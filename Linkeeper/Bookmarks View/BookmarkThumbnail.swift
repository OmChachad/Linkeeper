//
//  BookmarkThumbnail.swift
//  Linkeeper
//
//  Created by Om Chachad on 5/19/26.
//


import SwiftUI
import LinkPresentation
import Pow
import Shimmer

struct BookmarkThumbnail: View {
    let cachedPreview: cachedPreview?
    let title: String

    var body: some View {
        Group {
            switch cachedPreview?.previewState {
            case .thumbnail:
                cachedPreview!.image!
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .icon:
                cachedPreview!.image!
                    .resizable()
                    .aspectRatio(1/1, contentMode: .fit)
                    .cornerRadius(20, style: .continuous)
                    .padding(15)
            case .firstLetter:
                Color.gray
                    .overlay(
                        Text(String(title.first ?? "?"))
                            .font(.largeTitle.weight(.medium))
                            .foregroundColor(.white)
                            .scaleEffect(2)
                    )
            default:
                Rectangle()
                    .foregroundColor(.secondary.opacity(0.5))
                    .shimmering()
            }
        }
    }
}