//
//  AddFolder.swift
//  Linkeeper
//
//  Created by Om Chachad on 30/05/23.
//

import Foundation
import AppIntents
import SwiftUI

@available(iOS 16.0, *)
struct AddFolder: AppIntent {
    static var title: LocalizedStringResource = "Add Folder"
    static var description: IntentDescription = IntentDescription("Create a new folder.", categoryName: "Create", searchKeywords: ["Group", "New", "Create", "Bookmark"])
    
    @Parameter(title: "Title", description: "Provide a title for your folder.")
    var folderTitle: String
    
    @Parameter(title: "Icon", description: "Provide an icon for your folder. You may input the name of a valid SF Symbol.", requestValueDialog: "Choose an icon for your folder", optionsProvider: IconOptionsProvider())
    var icon: String
    
    @Parameter(title: "Color", requestValueDialog: "Choose a color for your folder", optionsProvider: ColorOptionsProvider())
    var color: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add Folder \(\.$folderTitle)") {
            \.$icon
            \.$color
        }
    }
    
    func perform() async throws -> some ReturnsValue<FolderEntity>{
        do {
            let folder = try FoldersManager.shared.addFolder(title: folderTitle, accentColor: color, chosenSymbol: icon)
            let entity = FolderEntity(id: folder.id!, title: folder.wrappedTitle, bookmarks: Set<BookmarkEntity>(), index: Int(folder.index), symbol: folder.wrappedSymbol, color: folder.accentColor ?? "gray")
            return .result(value: entity)
        } catch {
            throw error
        }
    }
}

@available(iOS 16.0, *)
struct IconOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> ItemCollection<String> {
        
        if #available(iOS 16.4, *) {
            return ItemCollection {
                ItemSection("Objects",  items:
                    SymbolCategory.objects.symbolKeys.map {
                        IntentItem<String>.init(
                            $0,
                            title: LocalizedStringResource(stringLiteral: SymbolCategory.objects.symbolValues[SymbolCategory.objects.symbolKeys.firstIndex(of: $0)!]),
                            subtitle: LocalizedStringResource(stringLiteral: $0),
                            image: .init(systemName: $0)
                        )
                    }
                )
                ItemSection("People",  items:
                    SymbolCategory.people.symbolKeys.map {
                        IntentItem<String>.init(
                            $0,
                            title: LocalizedStringResource(stringLiteral: SymbolCategory.people.symbolValues[SymbolCategory.people.symbolKeys.firstIndex(of: $0)!]),
                            subtitle: LocalizedStringResource(stringLiteral: $0),
                            image: .init(systemName: $0)
                        )
                    }
                )
                ItemSection("Symbols",  items:
                    SymbolCategory.symbols.symbolKeys.map {
                        IntentItem<String>.init(
                            $0,
                            title: LocalizedStringResource(stringLiteral: SymbolCategory.symbols.symbolValues[SymbolCategory.symbols.symbolKeys.firstIndex(of: $0)!]),
                            subtitle: LocalizedStringResource(stringLiteral: $0),
                            image: .init(systemName: $0)
                        )
                    }
                )
            }
        } else {
            return ItemCollection {
                ItemSection(items:
                    SymbolCategory.objects.symbolKeys.map {
                        IntentItem<String>.init(
                            $0,
                            title: LocalizedStringResource(stringLiteral: SymbolCategory.objects.symbolValues[SymbolCategory.objects.symbolKeys.firstIndex(of: $0)!]),
                            subtitle: LocalizedStringResource(stringLiteral: $0),
                            image: .init(systemName: $0)
                        )
                    }
                )
                ItemSection(items:
                    SymbolCategory.people.symbolKeys.map {
                        IntentItem<String>.init(
                            $0,
                            title: LocalizedStringResource(stringLiteral: SymbolCategory.people.symbolValues[SymbolCategory.people.symbolKeys.firstIndex(of: $0)!]),
                            subtitle: LocalizedStringResource(stringLiteral: $0),
                            image: .init(systemName: $0)
                        )
                    }
                )
                ItemSection(items:
                    SymbolCategory.symbols.symbolKeys.map {
                        IntentItem<String>.init(
                            $0,
                            title: LocalizedStringResource(stringLiteral: SymbolCategory.symbols.symbolValues[SymbolCategory.symbols.symbolKeys.firstIndex(of: $0)!]),
                            subtitle: LocalizedStringResource(stringLiteral: $0),
                            image: .init(systemName: $0)
                        )
                    }
                )
            }
        }
    }
}

@available(iOS 16.0, *)
struct ColorOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> ItemCollection<String> {
        let colors = ColorOption.allCases
        return ItemCollection {
            ItemSection(items:
                            colors.map {
                IntentItem<String>.init(
                    $0.rawValue,
                    title: LocalizedStringResource(stringLiteral: $0.rawValue.capitalized),
                    image: .init(data: UIImage(systemName: "circle.fill")?.withTintColor(UIColor($0.color)).pngData() ?? Data())
                )
            }
            )
        }
    }
}

//var intentSymbolNames: [[String: String]] = [
//    ["car.fill": "Car", "bus.fill": "Bus", "bicycle": "Bicycle", "airplane": "Airplane", "house.fill": "House", "building.2.fill": "Building", "cart.fill": "Cart", "bag.fill": "Bag", "fork.knife": "Cutlery", "takeoutbag.and.cup.and.straw.fill": "Takeout Bag", "thermometer": "Thermometer", "sun.max.fill": "Sun", "moon.fill": "Moon", "snowflake": "Snowflake", "cloud.fill": "Cloud", "cloud.rain.fill": "Rain Cloud", "umbrella.fill": "Umbrella", "flame.fill": "Flame", "binoculars.fill": "Binoculars", "globe": "Globe", "photo.fill": "Photo", "camera.fill": "Camera", "doc.on.clipboard.fill": "Clipboard with Document", "calendar": "Calendar", "envelope.fill": "Envelope", "paperplane.fill": "Paper Plane", "briefcase.fill": "Briefcase", "folder.fill": "Folder", "creditcard.fill": "Credit Card", "phone.fill": "Phone", "laptopcomputer": "Laptop", "desktopcomputer": "Desktop Computer", "chart.bar.fill": "Bar Chart", "printer.fill": "Printer", "archivebox.fill": "Archive Box", "tv.fill": "TV", "gamecontroller.fill": "Game Controller", "headphones": "Headphones", "ear.fill": "Ear", "music.note": "Music Note", "speaker.fill": "Speaker", "books.vertical.fill": "Books", "book.fill": "Book", "bookmark.fill": "Bookmark", "eyeglasses": "Eyeglasses", "ticket.fill": "Ticket", "dice.fill": "Dice", "sportscourt.fill": "Sports Court", "lifepreserver.fill": "Life Preserver", "hare.fill": "Hare", "clock.fill": "Clock", "alarm.fill": "Alarm", "stopwatch.fill": "Stopwatch", "bell.fill": "Bell", "heart.fill": "Heart", "star.fill": "Star", "lightbulb.fill": "Lightbulb", "bolt.fill": "Bolt", "flag.fill": "Flag", "tag.fill": "Tag", "key.fill": "Key", "hourglass": "Hourglass", "lock.fill": "Lock", "battery.100": "Battery", "wand.and.rays": "Wand with Rays", "paintbrush.fill": "Paintbrush", "pencil": "Pencil", "scissors": "Scissors", "magnifyingglass": "Magnifying Glass", "link": "Link", "hammer.fill": "Hammer", "wrench.fill": "Wrench", "gear": "Gear", "trash.fill": "Trash", "cup.and.saucer.fill": "Cup and Saucer", "tshirt.fill": "T-Shirt", "bandage.fill": "Bandage", "stethoscope": "Stethoscope", "facemask.fill": "Face Mask", "atom": "Atom", "graduationcap.fill": "Graduation Cap", "gift.fill": "Gift", "bed.double.fill": "Double Bed", "map.fill": "Map", "speedometer": "Speedometer", "barometer": "Barometer", "network": "Network", "rectangle.split.2x1": "Split Rectangle", "photo.fill.on.rectangle.fill": "Photo on Rectangle", "camera.aperture": "Camera Aperture", "arrow.up.circle.fill": "Up Arrow Circle", "plus.bubble.fill": "Plus Bubble", "square.fill": "Square", "hand.point.up.braille.fill": "Hand Pointing Up (Braille)", "square.and.arrow.down.fill": "Square and Down Arrow", "square.and.arrow.up.fill": "Square and Up Arrow", "play.circle.fill": "Play Circle", "questionmark.circle.fill": "Question Mark Circle", "checkmark.circle.fill": "Checkmark Circle", "plus.circle.fill": "Plus Circle", "info.circle.fill": "Info Circle", "face.smiling.fill": "Smiling Face", "xmark.square": "X Mark Square", "doc.text.fill": "Text Document", "square.grid.2x2.fill": "Grid (2x2)", "ellipsis": "Ellipsis", "list.bullet": "Bullet List", "checklist": "Checklist", "rays": "Rays", "infinity": "Infinity", "location.fill": "Location", "mappin.and.ellipse": "Map Pin and Ellipse", "crop": "Crop", "shuffle": "Shuffle", "quote.bubble.fill": "Quote Bubble", "quote.bubble": "Quote Bubble", "camera.filters": "Camera Filters", "wifi": "WiFi", "airplayaudio": "AirPlay Audio", "airplayvideo": "AirPlay Video", "music.note.list": "List of Music Notes", "timer": "Timer", "square.and.pencil": "Square and Pencil", "dial.min.fill": "Min Dial", "dial.max.fill": "Max Dial", "wallet.pass.fill": "Wallet Pass", "command": "Command"],
//    ["figure.stand": "Standing Figure", "person.fill": "Person", "person.2.fill": "Person 2", "person.3.fill": "Person 3", "figure.walk": "Walking Figure", "figure.roll": "Rolling Figure"],
//    ["square.2.layers.3d.top.filled": "3D Square", "exclamationmark.triangle.fill": "Exclamation Mark Triangle", "arrowshape.turn.up.backward.fill": "Arrow Turn Up Backward", "arrowshape.turn.up.forward.fill": "Arrow Turn Up Forward", "bookmark.fill": "Bookmark", "barcode": "Barcode", "qrcode": "QR Code", "qrcode.viewfinder": "QR Code Viewfinder", "play.fill": "Play", "square.fill": "Square", "square": "Square", "hand.point.up.braille.fill": "Hand Pointing Up (Braille)", "chevron.backward.circle.fill": "Chevron Backward Circle", "chevron.right.circle.fill": "Chevron Right Circle", "square.and.arrow.down.fill": "Square and Down Arrow", "chevron.up.circle.fill": "Chevron Up Circle", "chevron.down.circle.fill": "Chevron Down Circle", "square.and.arrow.up.fill": "Square and Up Arrow", "play.circle.fill": "Play Circle", "backward.circle.fill": "Backward Circle", "power.circle.fill": "Power Circle", "stop.circle.fill": "Stop Circle", "forward.circle.fill": "Forward Circle", "questionmark.circle.fill": "Question Mark Circle", "checkmark.circle.fill": "Checkmark Circle", "plus.circle.fill": "Plus Circle", "info.circle.fill": "Info Circle", "face.smiling.fill": "Smiling Face", "xmark.square": "X Mark Square", "doc": "Document", "dollarsign.circle.fill": "Dollar Sign Circle", "eurosign.circle.fill": "Euro Sign Circle", "sterlingsign.circle.fill": "Pound Sterling Sign Circle", "yensign.circle.fill": "Yen Sign Circle", "bitcoinsign.circle.fill": "Bitcoin Sign Circle", "multiply.circle.fill": "Multiply Circle", "staroflife": "Star of Life", "doc.text.fill": "Text Document", "doc.text": "Text Document", "doc.richtext": "Rich Text Document", "square.grid.2x2.fill": "Grid (2x2)", "ellipsis": "Ellipsis", "list.bullet": "Bullet List", "checklist": "Checklist", "square.grid.4x3.fill": "Grid (4x3)", "rays": "Rays", "point.3.filled.connected.trianglepath.dotted": "Connected Dotted Triangle", "infinity": "Infinity", "arrow.3.trianglepath": "Three-Arrow Triangle", "circle.circle": "Circle within Circle", "location.fill": "Location", "mappin.and.ellipse": "Map Pin and Ellipse", "p.square.fill": "Filled Square with P", "crop": "Crop", "arrow.down.right.and.arrow.up.left": "Down-Right and Up-Left Arrows", "arrow.up.and.down.and.arrow.left.and.right": "Up-Down and Left-Right Arrows", "arrow.2.squarepath": "Two-Arrow Square Path", "arrow.triangle.2.circlepath": "Triangle-Arrow Circle Path", "shuffle": "Shuffle", "slider.horizontal.3": "Horizontal Slider (3)", "quote.bubble.fill": "Quote Bubble", "quote.bubble": "Quote Bubble", "peacesign": "Peace Sign", "camera.filters": "Camera Filters", "t.square.fill": "T Square", "character.textbox": "Character Textbox", "cloud.fill": "Cloud", "pills.fill": "Pills", "dot.radiowaves.forward": "Radiowaves Forward", "dot.radiowaves.up.forward": "Radiowaves Up Forward", "wifi": "WiFi", "arrow.triangle.turn.up.right.diamond.fill": "Diamond-Filled Triangle Turn Up Right", "arrow.triangle.turn.up.right.circle.fill": "Circle-Filled Triangle Turn Up Right", "airplayaudio": "AirPlay Audio", "airplayvideo": "AirPlay Video", "music.note.list": "List of Music Notes", "music.note": "Music Note", "waveform.path": "Waveform Path", "waveform": "Waveform", "calendar.badge.plus": "Calendar Badge Plus", "calendar.badge.exclamationmark": "Calendar Badge Exclamation Mark", "timer": "Timer", "timer.square": "Timer Square", "square.and.pencil": "Square and Pencil", "plus.square.fill.on.square.fill": "Plus Square on Square", "dial.min.fill": "Min Dial", "dial.max.fill": "Max Dial",  "camera.viewfinder": "Camera Viewfinder", "wallet.pass.fill": "Wallet Pass", "nosign": "No Sign", "command": "Command", "command.circle.fill": "Command Circle", "command.square.fill": "Command Square"]
//]
//
