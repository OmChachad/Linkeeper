//
//  SpotlightIndexer.swift
//  Linkeeper
//

import AppIntents
import CoreData
import CoreSpotlight
import Foundation
import OSLog
import UniformTypeIdentifiers

/// Stable identifiers shared by Spotlight indexing and result activation.
enum SpotlightItemIdentifier {
    private static let bookmarkPrefix = "bookmark:"
    private static let folderPrefix = "folder:"

    /// Returns the Spotlight identifier for a bookmark.
    static func bookmark(_ id: UUID) -> String {
        bookmarkPrefix + id.uuidString
    }

    /// Returns the Spotlight identifier for a folder.
    static func folder(_ id: UUID) -> String {
        folderPrefix + id.uuidString
    }

    /// Parses a Spotlight identifier into an app destination.
    static func destination(from identifier: String) -> (kind: SpotlightDestinationKind, id: UUID)? {
        if identifier.hasPrefix(bookmarkPrefix),
           let id = UUID(uuidString: String(identifier.dropFirst(bookmarkPrefix.count))) {
            return (.bookmark, id)
        }

        if identifier.hasPrefix(folderPrefix),
           let id = UUID(uuidString: String(identifier.dropFirst(folderPrefix.count))) {
            return (.folder, id)
        }

        return nil
    }
}

/// Keeps Linkeeper's Core Data entities donated to a named Spotlight index.
// TODO(iOS 27 SDK): Make `IntentsBookmarkQuery` and `IntentsFolderQuery`
// conform to `IndexedEntityQuery`, implementing both
// `reindexEntities(for:indexDescription:)` and
// `reindexAllEntities(indexDescription:)`. Fetch the requested UUIDs from Core
// Data and pass the canonical entities through this class's serialized
// `indexAppEntities` path. Those APIs require iOS 27; once available, they can
// replace the compatibility `CSSearchableIndexDelegate` callbacks below.
@MainActor
final class SpotlightIndexer: NSObject, CSSearchableIndexDelegate {
    /// The app-wide Spotlight indexer.
    static let shared = SpotlightIndexer()

    private enum Domain {
        static let bookmarks = "org.starlightapps.Linkeeper.bookmarks"
        static let folders = "org.starlightapps.Linkeeper.folders"
        static let all = [bookmarks, folders]
    }

    private enum IndexSchema {
        /// Bump this whenever an entity's identity or its opening intent changes.
        static let currentVersion = 1
        static let storedVersionKey = "SpotlightIndexSchemaVersion"
        static let name = "LinkeeperContent"
    }

    private struct PendingChanges {
        var bookmarkUpserts: Set<UUID> = []
        var bookmarkDeletes: Set<UUID> = []
        var folderUpserts: Set<UUID> = []
        var folderDeletes: Set<UUID> = []

        var isEmpty: Bool {
            bookmarkUpserts.isEmpty && bookmarkDeletes.isEmpty && folderUpserts.isEmpty && folderDeletes.isEmpty
        }

        mutating func merge(_ other: PendingChanges) {
            // The newer change wins when an identifier was deleted and then
            // recreated (or vice versa) before the debounce interval elapsed.
            bookmarkUpserts.subtract(other.bookmarkDeletes)
            bookmarkDeletes.subtract(other.bookmarkUpserts)
            folderUpserts.subtract(other.folderDeletes)
            folderDeletes.subtract(other.folderUpserts)

            bookmarkUpserts.formUnion(other.bookmarkUpserts)
            bookmarkDeletes.formUnion(other.bookmarkDeletes)
            folderUpserts.formUnion(other.folderUpserts)
            folderDeletes.formUnion(other.folderDeletes)
        }
    }

    private let index = CSSearchableIndex(name: IndexSchema.name)
    private let logger = Logger(subsystem: "org.starlightapps.Linkeeper", category: "Spotlight")
    private var context: NSManagedObjectContext?
    private var observers: [NSObjectProtocol] = []
    private var changesBeforeSave = PendingChanges()
    private var pendingChanges = PendingChanges()
    private var incrementalTask: Task<Void, Never>?
    private var fullSynchronizationTask: Task<Void, Never>?
    private var indexOperationTask: Task<Void, Never>?

    private override init() {
        super.init()
        index.indexDelegate = self
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    /// Starts observing local saves and CloudKit-backed store changes.
    func start(with container: NSPersistentCloudKitContainer) {
        guard observers.isEmpty else {
            return
        }

        context = container.viewContext

        observers.append(NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextWillSave,
            object: container.viewContext,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.captureChangesBeforeSave(from: notification)
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: container.viewContext,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.enqueueCapturedChanges()
            }
        })

        observers.append(NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.scheduleFullSynchronization(after: 1.5)
            }
        })
    }

    nonisolated func searchableIndex(
        _ searchableIndex: CSSearchableIndex,
        reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void
    ) {
        Task { @MainActor [weak self] in
            await self?.synchronizeAll()
            acknowledgementHandler()
        }
    }

    nonisolated func searchableIndex(
        _ searchableIndex: CSSearchableIndex,
        reindexSearchableItemsWithIdentifiers searchableItemIdentifiers: [String],
        acknowledgementHandler: @escaping () -> Void
    ) {
        // App-entity identifiers aren't guaranteed to use the legacy searchable
        // item format, so a canonical rebuild is safer than guessing their type.
        Task { @MainActor [weak self] in
            await self?.synchronizeAll()
            acknowledgementHandler()
        }
    }

    /// Reconciles every bookmark and folder with Spotlight.
    func synchronizeAll() async {
        do {
            try await enqueueIndexOperation { [weak self] in
                try await self?.performFullSynchronization()
            }
        } catch is CancellationError {
            return
        } catch {
            logger.error("Spotlight synchronization failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Starts observation when needed and reconciles the shared store.
    ///
    /// App Intents and share extensions can run without creating Linkeeper's
    /// SwiftUI scene, so they must not rely on the app-launch setup path.
    func synchronizeCurrentStore() async {
        start(with: DataController.shared.persistentCloudKitContainer)
        await synchronizeAll()
    }

    private func performFullSynchronization() async throws {
        guard CSSearchableIndex.isIndexingAvailable(), let context else {
            return
        }

        let bookmarkRequest: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        let folderRequest: NSFetchRequest<Folder> = Folder.fetchRequest()
        let bookmarks = uniqueBookmarks(try context.fetch(bookmarkRequest))
        let folders = uniqueFolders(try context.fetch(folderRequest))
        let requiresMigration = SharedUserDefaults.integer(forKey: IndexSchema.storedVersionKey) != IndexSchema.currentVersion

        if requiresMigration {
            // Previous index generations can survive in either Linkeeper's
            // named index or its former default index. Type-specific deletion
            // cannot remove records with old entity/open-intent metadata.
            try await deleteAllItems(from: index)
            try await deleteAllItems(from: .default())
        }

        if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
            try await synchronizeAppEntities(bookmarks: bookmarks, folders: folders)
        } else {
            try await replaceLegacyItems(bookmarks: bookmarks, folders: folders)
        }

        if requiresMigration {
            SharedUserDefaults.set(IndexSchema.currentVersion, forKey: IndexSchema.storedVersionKey)
        }
    }

    private func enqueueIndexOperation(
        _ operation: @escaping @MainActor () async throws -> Void
    ) async throws {
        let previousOperation = indexOperationTask
        let resultTask = Task { @MainActor () -> Result<Void, Error> in
            await previousOperation?.value

            do {
                try await operation()
                return .success(())
            } catch {
                return .failure(error)
            }
        }

        indexOperationTask = Task { @MainActor in
            _ = await resultTask.value
        }

        try await resultTask.value.get()
    }

    private func captureChangesBeforeSave(from notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else {
            return
        }

        var changes = PendingChanges()

        for object in context.insertedObjects.union(context.updatedObjects) {
            if let bookmark = object as? Bookmark, let id = bookmark.id {
                changes.bookmarkUpserts.insert(id)
                captureAffectedFolders(for: bookmark, in: &changes)
            } else if let folder = object as? Folder, let id = folder.id {
                changes.folderUpserts.insert(id)
            }
        }

        for object in context.deletedObjects {
            if let bookmark = object as? Bookmark, let id = bookmark.id {
                changes.bookmarkDeletes.insert(id)
                captureAffectedFolders(for: bookmark, in: &changes)
            } else if let folder = object as? Folder, let id = folder.id {
                changes.folderDeletes.insert(id)
            }
        }

        changesBeforeSave.merge(changes)
    }

    private func captureAffectedFolders(for bookmark: Bookmark, in changes: inout PendingChanges) {
        if let folderID = bookmark.folder?.id {
            changes.folderUpserts.insert(folderID)
        }

        if let previousFolder = bookmark.committedValues(forKeys: ["folder"])["folder"] as? Folder,
           let previousFolderID = previousFolder.id {
            changes.folderUpserts.insert(previousFolderID)
        }
    }

    private func enqueueCapturedChanges() {
        guard !changesBeforeSave.isEmpty else {
            return
        }

        pendingChanges.merge(changesBeforeSave)
        changesBeforeSave = PendingChanges()
        scheduleIncrementalSynchronization()
    }

    private func scheduleIncrementalSynchronization() {
        incrementalTask?.cancel()
        incrementalTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else {
                return
            }
            await self?.flushPendingChanges()
        }
    }

    private func scheduleFullSynchronization(after delay: TimeInterval) {
        fullSynchronizationTask?.cancel()
        fullSynchronizationTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else {
                return
            }
            await self?.synchronizeAll()
        }
    }

    private func flushPendingChanges() async {
        guard CSSearchableIndex.isIndexingAvailable(), let context, !pendingChanges.isEmpty else {
            return
        }

        let changes = pendingChanges
        pendingChanges = PendingChanges()

        do {
            try await enqueueIndexOperation { [weak self] in
                await self?.applyPendingChanges(changes, in: context)
            }
        } catch is CancellationError {
            pendingChanges.merge(changes)
        } catch {
            pendingChanges.merge(changes)
            logger.error("Incremental Spotlight update could not be scheduled: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func applyPendingChanges(_ pendingChanges: PendingChanges, in context: NSManagedObjectContext) async {
        var changes = pendingChanges

        do {
            let bookmarks = uniqueBookmarks(try fetchBookmarks(with: changes.bookmarkUpserts, in: context))
            let folders = uniqueFolders(try fetchFolders(with: changes.folderUpserts, in: context))
            let existingBookmarkIDs = Set(bookmarks.compactMap(\.id))
            let existingFolderIDs = Set(folders.compactMap(\.id))

            changes.bookmarkDeletes.formUnion(changes.bookmarkUpserts.subtracting(existingBookmarkIDs))
            changes.folderDeletes.formUnion(changes.folderUpserts.subtracting(existingFolderIDs))
            changes.bookmarkDeletes.subtract(existingBookmarkIDs)
            changes.folderDeletes.subtract(existingFolderIDs)

            if #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) {
                try await applyAppEntityChanges(changes, bookmarks: bookmarks, folders: folders)
            } else {
                try await applyLegacyChanges(changes, bookmarks: bookmarks, folders: folders)
            }
        } catch is CancellationError {
            self.pendingChanges.merge(changes)
        } catch {
            logger.error("Incremental Spotlight update failed: \(error.localizedDescription, privacy: .public)")
            do {
                try await performFullSynchronization()
            } catch {
                logger.error("Fallback Spotlight synchronization failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func uniqueBookmarks(_ bookmarks: [Bookmark]) -> [Bookmark] {
        var identifiers: Set<UUID> = []
        return bookmarks.filter { bookmark in
            guard let id = bookmark.id else {
                return false
            }
            return identifiers.insert(id).inserted
        }
    }

    private func uniqueFolders(_ folders: [Folder]) -> [Folder] {
        var identifiers: Set<UUID> = []
        return folders.filter { folder in
            guard let id = folder.id else {
                return false
            }
            return identifiers.insert(id).inserted
        }
    }

    private func fetchBookmarks(with ids: Set<UUID>, in context: NSManagedObjectContext) throws -> [Bookmark] {
        guard !ids.isEmpty else {
            return []
        }

        let request: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", Array(ids) as NSArray)
        return try context.fetch(request)
    }

    private func fetchFolders(with ids: Set<UUID>, in context: NSManagedObjectContext) throws -> [Folder] {
        guard !ids.isEmpty else {
            return []
        }

        let request: NSFetchRequest<Folder> = Folder.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", Array(ids) as NSArray)
        return try context.fetch(request)
    }

    @available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
    private func synchronizeAppEntities(bookmarks: [Bookmark], folders: [Folder]) async throws {
        try await deleteLegacyItems(in: Domain.all)
        try await index.deleteAppEntities(ofType: LinkeeperBookmarkEntity.self)
        try await index.deleteAppEntities(ofType: FolderEntity.self)
        try await indexBookmarkEntities(bookmarks.toEntity())
        try await indexFolderEntities(folders.toEntity())
    }

    @available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
    private func applyAppEntityChanges(_ changes: PendingChanges, bookmarks: [Bookmark], folders: [Folder]) async throws {
        if !changes.bookmarkDeletes.isEmpty {
            try await index.deleteAppEntities(identifiedBy: Array(changes.bookmarkDeletes), ofType: LinkeeperBookmarkEntity.self)
        }
        if !changes.folderDeletes.isEmpty {
            try await index.deleteAppEntities(identifiedBy: Array(changes.folderDeletes), ofType: FolderEntity.self)
        }

        try await indexBookmarkEntities(bookmarks.toEntity())
        try await indexFolderEntities(folders.toEntity())
    }

    @available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
    private func indexBookmarkEntities(_ entities: [LinkeeperBookmarkEntity]) async throws {
        let favorites = entities.filter(\.isFavorited)
        let remaining = entities.filter { !$0.isFavorited }

        if !remaining.isEmpty {
            try await index.indexAppEntities(remaining, priority: 0)
        }
        if !favorites.isEmpty {
            try await index.indexAppEntities(favorites, priority: 10)
        }
    }

    @available(iOS 18.0, macOS 15.0, visionOS 2.0, *)
    private func indexFolderEntities(_ entities: [FolderEntity]) async throws {
        let pinned = entities.filter(\.isPinned)
        let remaining = entities.filter { !$0.isPinned }

        if !remaining.isEmpty {
            try await index.indexAppEntities(remaining, priority: 1)
        }
        if !pinned.isEmpty {
            try await index.indexAppEntities(pinned, priority: 8)
        }
    }

    private func replaceLegacyItems(bookmarks: [Bookmark], folders: [Folder]) async throws {
        try await deleteLegacyItems(in: Domain.all)
        let items = bookmarks.compactMap(makeLegacyBookmarkItem) + folders.compactMap(makeLegacyFolderItem)
        try await indexLegacyItems(items)
    }

    private func applyLegacyChanges(_ changes: PendingChanges, bookmarks: [Bookmark], folders: [Folder]) async throws {
        let identifiers = changes.bookmarkDeletes.map(SpotlightItemIdentifier.bookmark)
            + changes.folderDeletes.map(SpotlightItemIdentifier.folder)
        try await deleteLegacyItems(withIdentifiers: identifiers)

        let items = bookmarks.compactMap(makeLegacyBookmarkItem) + folders.compactMap(makeLegacyFolderItem)
        try await indexLegacyItems(items)
    }

    private func makeLegacyBookmarkItem(_ bookmark: Bookmark) -> CSSearchableItem? {
        guard let id = bookmark.id else {
            return nil
        }

        let attributes = CSSearchableItemAttributeSet(contentType: .url)
        let folderTitle = bookmark.folder?.wrappedTitle
        attributes.title = bookmark.wrappedTitle
        attributes.displayName = bookmark.wrappedTitle
        attributes.contentDescription = bookmark.wrappedNotes.isEmpty ? bookmark.wrappedURL.absoluteString : bookmark.wrappedNotes
        attributes.textContent = [bookmark.wrappedTitle, bookmark.wrappedURL.absoluteString, bookmark.wrappedHost, bookmark.wrappedNotes, folderTitle]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        attributes.url = bookmark.wrappedURL
        attributes.keywords = ["bookmark", bookmark.wrappedHost, folderTitle]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        attributes.contentCreationDate = bookmark.wrappedDate
        attributes.addedDate = bookmark.wrappedDate
        attributes.containerDisplayName = folderTitle
        attributes.userCreated = NSNumber(value: true)
        attributes.userCurated = NSNumber(value: bookmark.isFavorited)
        attributes.rankingHint = NSNumber(value: bookmark.isFavorited ? 1 : 0.5)
        attributes.thumbnailData = CacheManager.instance.get(id: id)?.imageData

        let item = CSSearchableItem(
            uniqueIdentifier: SpotlightItemIdentifier.bookmark(id),
            domainIdentifier: Domain.bookmarks,
            attributeSet: attributes
        )
        item.expirationDate = .distantFuture
        return item
    }

    private func makeLegacyFolderItem(_ folder: Folder) -> CSSearchableItem? {
        guard let id = folder.id else {
            return nil
        }

        let attributes = CSSearchableItemAttributeSet(contentType: .folder)
        attributes.contentTypeTree = [UTType.folder.identifier, UTType.directory.identifier]
        attributes.title = folder.wrappedTitle
        attributes.displayName = folder.wrappedTitle
        attributes.contentDescription = folder.countOfBookmarks == 1 ? "1 bookmark" : "\(folder.countOfBookmarks) bookmarks"
        attributes.textContent = folder.wrappedTitle
        attributes.keywords = [folder.wrappedTitle, "folder"]
        attributes.userCreated = NSNumber(value: true)
        attributes.userCurated = NSNumber(value: folder.isPinned)
        attributes.rankingHint = NSNumber(value: folder.isPinned ? 1 : 0.5)

        let item = CSSearchableItem(
            uniqueIdentifier: SpotlightItemIdentifier.folder(id),
            domainIdentifier: Domain.folders,
            attributeSet: attributes
        )
        item.expirationDate = .distantFuture
        return item
    }

    private func indexLegacyItems(_ items: [CSSearchableItem]) async throws {
        guard !items.isEmpty else {
            return
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            index.indexSearchableItems(items) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func deleteLegacyItems(in domains: [String]) async throws {
        guard !domains.isEmpty else {
            return
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            index.deleteSearchableItems(withDomainIdentifiers: domains) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func deleteLegacyItems(withIdentifiers identifiers: [String]) async throws {
        guard !identifiers.isEmpty else {
            return
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            index.deleteSearchableItems(withIdentifiers: identifiers) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func deleteAllItems(from searchableIndex: CSSearchableIndex) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            searchableIndex.deleteAllSearchableItems { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
