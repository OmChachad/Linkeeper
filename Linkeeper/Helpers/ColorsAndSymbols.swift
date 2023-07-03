//
//  ColorsAndSymbols.swift
//  Marked
//
//  Created by Om Chachad on 27/04/22.
//

import Foundation
import SwiftUI

enum ColorOption: String, CaseIterable {
    case gray
    case purple
    case brown
    case indigo
    case pink
    case blurple
    case orange
    case blue
    case yellow
    case cyan
    case green
    case mint
    
    private static var values: [String : Color] = [
        "gray": Color(uiColor: .systemGray),
        "purple": Color.purple,
        "orange": Color.orange,
        "pink": Color.red,
        "yellow": Color.yellow,
        "mint": Color.mint,
        "indigo": Color.indigo,
        "green": Color.green,
        "cyan": Color.cyan,
        "brown": Color.brown,
        "blue": Color.blue,
        "blurple": Color(red: 0.5294117647, green: 0.4823529412, blue: 0.9019607843)
    ]
    
    var color: Color {
        return ColorOption.values[self.rawValue] ?? .gray
    }
}

var symbols = [    ["car.fill", "bus.fill", "bicycle", "airplane", "house.fill", "building.2.fill", "cart.fill", "bag.fill", "fork.knife",  "takeoutbag.and.cup.and.straw.fill", "thermometer", "sun.max.fill", "moon.fill", "snowflake", "cloud.fill", "cloud.rain.fill", "umbrella.fill", "flame.fill", "binoculars.fill", "globe", "photo.fill", "camera.fill", "doc.on.clipboard.fill", "calendar", "envelope.fill", "paperplane.fill", "briefcase.fill", "folder.fill", "creditcard.fill", "phone.fill", "laptopcomputer", "desktopcomputer", "chart.bar.fill", "printer.fill", "archivebox.fill", "tv.fill", "gamecontroller.fill", "headphones", "ear.fill", "music.note", "speaker.fill", "books.vertical.fill", "book.fill", "bookmark.fill", "eyeglasses", "ticket.fill", "dice.fill", "sportscourt.fill", "lifepreserver.fill", "hare.fill", "clock.fill", "alarm.fill", "stopwatch.fill", "bell.fill", "heart.fill", "star.fill", "lightbulb.fill", "bolt.fill", "flag.fill", "tag.fill", "key.fill", "hourglass", "lock.fill", "battery.100", "wand.and.rays", "paintbrush.fill", "pencil", "scissors", "magnifyingglass", "link", "hammer.fill", "wrench.fill", "gear", "trash.fill", "cup.and.saucer.fill", "tshirt.fill", "bandage.fill", "stethoscope", "facemask.fill", "atom", "graduationcap.fill", "gift.fill", "bed.double.fill", "map.fill", "speedometer", "barometer", "network", "rectangle.split.2x1", "photo.fill.on.rectangle.fill", "camera.aperture", "arrow.up.circle.fill", "plus.bubble.fill", "square.fill", "hand.point.up.braille.fill", "square.and.arrow.down.fill", "square.and.arrow.up.fill", "play.circle.fill", "questionmark.circle.fill", "checkmark.circle.fill", "plus.circle.fill", "info.circle.fill", "face.smiling.fill", "xmark.square", "doc.text.fill", "square.grid.2x2.fill", "ellipsis", "list.bullet", "checklist", "rays", "infinity", "location.fill", "mappin.and.ellipse", "crop", "shuffle", "quote.bubble.fill", "quote.bubble", "camera.filters", "wifi", "airplayaudio", "airplayvideo", "music.note.list", "timer", "square.and.pencil", "dial.min.fill", "dial.max.fill", "wallet.pass.fill", "command",],
    ["figure.stand", "person.fill", "person.2.fill", "person.3.fill", "figure.walk", "figure.roll"],
    ["square.2.layers.3d.top.filled", "exclamationmark.triangle.fill", "arrowshape.turn.up.backward.fill", "arrowshape.turn.up.forward.fill", "bookmark.fill", "barcode", "qrcode", "qrcode.viewfinder", "play.fill", "square.fill", "square", "hand.point.up.braille.fill", "chevron.backward.circle.fill", "chevron.right.circle.fill", "square.and.arrow.down.fill", "chevron.up.circle.fill", "chevron.down.circle.fill", "square.and.arrow.up.fill", "play.circle.fill", "backward.circle.fill", "power.circle.fill", "stop.circle.fill", "forward.circle.fill", "questionmark.circle.fill", "checkmark.circle.fill", "plus.circle.fill", "info.circle.fill", "face.smiling.fill", "xmark.square", "doc", "dollarsign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill", "yensign.circle.fill", "bitcoinsign.circle.fill", "multiply.circle.fill", "staroflife", "doc.text.fill", "doc.text", "doc.richtext", "square.grid.2x2.fill", "ellipsis", "list.bullet", "checklist", "square.grid.4x3.fill", "rays", "point.3.filled.connected.trianglepath.dotted", "infinity", "arrow.3.trianglepath", "circle.circle", "location.fill", "mappin.and.ellipse", "p.square.fill", "crop", "arrow.down.right.and.arrow.up.left", "arrow.up.and.down.and.arrow.left.and.right", "arrow.2.squarepath", "arrow.triangle.2.circlepath", "shuffle", "slider.horizontal.3", "quote.bubble.fill", "quote.bubble", "peacesign", "camera.filters", "t.square.fill", "character.textbox", "cloud.fill", "pills.fill", "dot.radiowaves.forward", "dot.radiowaves.up.forward", "wifi","arrow.triangle.turn.up.right.diamond.fill", "arrow.triangle.turn.up.right.circle.fill", "airplayaudio", "airplayvideo", "music.note.list", "music.note", "waveform.path", "waveform", "calendar.badge.plus", "calendar.badge.exclamationmark", "timer", "timer.square", "square.and.pencil", "plus.square.fill.on.square.fill", "dial.min.fill", "dial.max.fill", "camera.viewfinder", "wallet.pass.fill", "nosign", "command", "command.circle.fill", "command.square.fill"]
]
