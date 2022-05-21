//
//  BookmarkView.swift
//  Marked
//
//  Created by Om Chachad on 11/05/22.
//

import SwiftUI

struct BookmarkView: View {
    @StateObject var vm : LinkViewModel
    @Environment(\.openURL) var openURL
    
    var bookmark: Bookmark
    var isShimmering = true
    
    var body: some View {
        VStack {
            
            ZStack {
                Rectangle()
                    .foregroundColor(.secondary.opacity(0.5))
                    .shimmering(active: isShimmering)
                    .aspectRatio(4/3, contentMode: .fill)
                    .clipped()
                //                                .frame(width: (UIScreen.main.bounds.width / 2) - 30)
                                                .frame(minWidth: 130, idealWidth: 165, maxWidth: 165)
                if let thumbnail = vm.image {
                    thumbnail
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                        .clipped()
                    //                                .frame(width: (UIScreen.main.bounds.width / 2) - 30)
                                                    .frame(minWidth: 130, idealWidth: 165, maxWidth: 165)
                } else {
                    if let iconImage = vm.iconImage {
                        ZStack {
                            Rectangle()
                                .aspectRatio(4/3, contentMode: .fill)
                                .foregroundColor(.white)
//                                .frame(width: (UIScreen.main.bounds.width / 2) - 30)
                                .frame(minWidth: 130, idealWidth: 165, maxWidth: 165)

                            iconImage
                            .resizable()
                            .aspectRatio(1/1, contentMode: .fit)
                            .padding(20)
                            .background(Color(red: 0.8980392157, green: 0.8980392157, blue: 0.9137254902))
                            .cornerRadius(20)
                            .clipped()
                            .scaleEffect(0.75)
                            
//                            iconImage
//                            .resizable()
//                            .aspectRatio(4/3, contentMode: .fill)
//                            .clipped()
//                            .frame(width: (UIScreen.main.bounds.width / 2) - 30)
                            
                        }
                        
                    } else {
                        if let title: String = vm.metadata?.title {
                            if let firstChar: Character = title.first {
                                Color(uiColor: .systemGray2)
                                    .aspectRatio(4/3, contentMode: .fill)
                                    .frame(minWidth: 130, idealWidth: 165, maxWidth: 165)
                                    .overlay(
                                        Text(String(firstChar))
                                            .font(.largeTitle.weight(.medium))
                                            .foregroundColor(.white)
                                            .scaleEffect(2)
                                    )
                            }
                        }
                    }
                }
            }
            VStack {
                Text(bookmark.title)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                Text(bookmark.host)
                        .lineLimit(1)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .offset(y: -5)
            .padding(5)
        }
        .onTapGesture {
            openURL(bookmark.url)
        }
        .background(Color(UIColor.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
//        .aspectRatio(4/5, contentMode: .fit)
//        .frame(maxWidth: (UIScreen.main.bounds.width / 2) - 10)
//        .frame(height: 200)
    }
}

struct BookmarkView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkView(vm: LinkViewModel(url: URL(string: "https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image")!), bookmark: Bookmark(title: "iTech Everything", url: URL(string: "https://youtube.com/TheiTE")!, host: "youtube.com", notes: "My YouTube channel", date: Date.now))
    }
}
