//
//  ColorsAndSymbols.swift
//  Marked
//
//  Created by Om Chachad on 27/04/22.
//

import Foundation
import SwiftUI

//struct ColorOptions {
//    static var keys = ["gray",
//    "magenta",
//    "brown",
//       "purple",
//    "pink",
//    "indigo",
//    "orange",
//    "blue",
//    "yellow",
//    "cyan",
//    "green",
//    "mint"]
//
//    static var values: [String:Color] = [
//        "gray": Color(UIColor.systemGray4),
//        "purple": Color.purple,
//        "orange": Color.orange,
//        "pink": Color.red,
//        "yellow": Color.yellow,
//        "mint": Color.mint,
//        "indigo": Color.indigo,
//        "green": Color.green,
//        "cyan": Color.cyan,
//        "brown": Color.brown,
//        "blue": Color.blue,
//        "magenta": Color(UIColor.magenta)
//    ]
//}

struct ColorOptions {
    @Environment(\.colorScheme) var colorScheme
    
    static var keys = ["gray",
    "purple",
    "brown",
       "indigo",
    "pink",
    "blurple",
    "orange",
    "blue",
    "yellow",
    "cyan",
    "green",
    "mint"]
    
    static var values: [String:Color] = [
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
        "blurple": Color( red: 0.5294117647, green: 0.4823529412, blue: 0.9019607843)
    ]
}

var symbols = [
    ["car.fill", "car.2.fill", "bolt.car.fill", "bus.fill", "bus.doubledecker.fill", "tram.fill", "tram.fill.tunnel", "bicycle", "cross.fill", "airplane", "house.fill", "building.2.fill", "cart.fill", "takeoutbag.and.cup.and.straw.fill", "bag.fill", "fork.knife", "fuelpump.fill", "thermometer", "sun.max.fill", "moon.fill", "moon.circle.fill", "snowflake", "cloud.fill", "cloud.rain.fill", "umbrella.fill", "flame.fill", "signpost.left.fill", "signpost.right.fill", "binoculars.fill", "globe", "photo.fill", "film.fill", "camera.fill", "mic.fill", "play.rectangle.fill", "play.square.fill", "doc.on.clipboard.fill", "calendar", "bubble.right.fill", "bubble.left.and.bubble.right.fill", "text.bubble.fill", "envelope.fill", "envelope.open.fill", "paperplane.fill", "paperplane.circle.fill", "briefcase.fill", "suitcase.fill", "folder.fill", "folder", "creditcard.fill", "phone.fill", "laptopcomputer", "desktopcomputer", "keyboard.fill", "keyboard", "chart.bar.fill", "printer.fill", "internaldrive.fill","internaldrive", "archivebox.fill", "cube.fill", "tv.fill", "gamecontroller.fill", "puzzlepiece.fill", "puzzlepiece.extension.fill", "headphones", "headphones.circle.fill", "ear.fill", "music.note", "speaker.wave.1.fill", "speaker.wave.2.fill", "speaker.wave.3.fill", "speaker.slash.fill", "speaker.fill", "hifispeaker.fill", "tv.and.hifispeaker.fill", "books.vertical.fill", "book.fill", "bookmark.fill", "book.closed.fill", "eyeglasses", "ticket.fill", "theatermasks.fill", "dice.fill", "sportscourt.fill", "opticaldisc", "lifepreserver.fill", "hare.fill", "clock.fill", "alarm.fill", "stopwatch.fill", "bell.fill", "heart.fill", "star.fill", "star.leadinghalf.filled", "lightbulb.fill", "bolt.fill", "flag.fill", "tag.fill", "key.fill", "hourglass", "lock.fill", "lock.open.fill", "battery.100", "wand.and.rays", "paintbrush.fill", "pencil", "paperclip", "scissors", "magnifyingglass", "link", "eyedropper.halffull", "hammer.fill", "wrench.fill", "wrench.and.screwdriver.fill", "gear", "screwdriver.fill", "trash.fill", "drop.fill", "cup.and.saucer.fill", "tshirt.fill", "pills.fill", "bandage.fill", "stethoscope", "facemask.fill", "atom", "graduationcap.fill", "gift.fill", "bed.double.fill", "map.fill", "speedometer", "barometer", "network", "square.stack.fill", "rectangle.grid.2x2.fill", "rectangle.grid.2x2",  "square.stack.3d.down.right.fill", "rectangle.split.2x1", "rectangle.split.3x1.fill", "rectangle.split.3x1", "photo.fill.on.rectangle.fill", "photo.on.rectangle.angled", "camera.aperture", "note", "note.text", "note.text.badge.plus", "arrow.up.circle.fill", "arrow.up.circle", "plus.bubble.fill", "radio.fill", "rectangle.portrait", "rectangle"],
    ["figure.stand", "figure.roll", "person.fill", "person.2.fill", "person.3.fill", "figure.walk", "figure.walk.circle.fill", "figure.walk.circle", "person.wave.2.fill", "brain.head.profile", "brain"],
    ["square.2.stack.3d", "exclamationmark.triangle.fill", "arrowshape.turn.up.backward.fill", "arrowshape.turn.up.forward.fill", "bookmark.fill", "barcode", "qrcode", "qrcode.viewfinder", "play.fill", "square.fill", "square", "hand.point.up.braille.fill", "chevron.backward.circle.fill", "chevron.right.circle.fill", "square.and.arrow.down.fill", "chevron.up.circle.fill", "chevron.down.circle.fill", "square.and.arrow.up.fill", "play.circle.fill", "backward.circle.fill", "power.circle.fill", "stop.circle.fill", "forward.circle.fill", "questionmark.circle.fill", "checkmark.circle.fill", "plus.circle.fill", "info.circle.fill", "face.smiling.fill", "xmark.square", "doc", "dollarsign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill", "yensign.circle.fill", "bitcoinsign.circle.fill", "multiply.circle.fill", "staroflife", "doc.text.fill", "doc.text", "doc.richtext", "square.grid.2x2.fill", "ellipsis", "list.bullet", "checklist", "square.grid.4x3.fill", "rays", "point.3.filled.connected.trianglepath.dotted", "infinity", "arrow.3.trianglepath", "circle.circle", "location.fill", "mappin.and.ellipse", "p.square.fill", "crop", "arrow.down.right.and.arrow.up.left", "arrow.up.and.down.and.arrow.left.and.right", "arrow.2.squarepath", "arrow.triangle.2.circlepath", "shuffle", "slider.horizontal.3", "quote.bubble.fill", "quote.bubble", "peacesign", "camera.filters", "t.square.fill", "character.textbox", "cloud.fill", "pills.fill", "dot.radiowaves.forward", "dot.radiowaves.up.forward", "wifi","arrow.triangle.turn.up.right.diamond.fill", "arrow.triangle.turn.up.right.circle.fill", "airplayaudio", "airplayvideo", "music.note.list", "music.note", "waveform.path", "waveform", "calendar.badge.plus", "calendar.badge.exclamationmark", "timer", "timer.square", "square.and.pencil", "plus.square.fill.on.square.fill", "dial.min.fill", "dial.max.fill", "qrcode.viewfinder", "camera.viewfinder", "wallet.pass.fill", "nosign", "command", "command.circle.fill", "command.square.fill"]
]
