//
//  Metadata Fetcher.swift
//  Linkeeper
//
//  Created by Om Chachad on 07/07/23.
//

import Foundation
import LinkPresentation

func startFetchingMetadata(for url: URL, fetchSubresources: Bool, timeout: TimeInterval?) async throws -> LPLinkMetadata? {
    return try await withCheckedThrowingContinuation { continuation in
        let metadataProvider = LPMetadataProvider()
        metadataProvider.shouldFetchSubresources = fetchSubresources
        metadataProvider.timeout = timeout ?? metadataProvider.timeout
        
        metadataProvider.startFetchingMetadata(for: url) { metadata, error in
            if error != nil {
                continuation.resume(returning: nil)
            } else if let metadata = metadata {
                continuation.resume(returning: metadata)
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}
