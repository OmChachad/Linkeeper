//
//  LinkPresentation.swift
//  Marked
//
//  Created by Om Chachad on 08/05/22.
//
import SwiftUI
import UIKit
import LinkPresentation

class LinkViewModel : ObservableObject {
    let metadataProvider = LPMetadataProvider()
    
    @Published var metadata: LPLinkMetadata?
    @Published var image: Image?
    @Published var iconImage: Image?
    
    init(url : URL) {
//        guard let url = URL(string: link) else {
//            return
//        }
        metadataProvider.startFetchingMetadata(for: url) { (metadata, error) in
            guard error == nil else {
                return
            }
            DispatchQueue.main.async {
                self.metadata = metadata
            }
            
            if let iconImageProvider = metadata?.iconProvider {
                iconImageProvider.loadObject(ofClass: UIImage.self) { (iconImage, error) in
                    guard error == nil else { return }
                    if let image = iconImage as? UIImage {
                        // do something with image
                        DispatchQueue.main.async {
                            self.iconImage = Image(uiImage: image)
                        }
                    }
                }
            }
            
            if let imageProvider = metadata?.imageProvider {
                imageProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    guard error == nil else { return }
                    if let image = image as? UIImage {
                        // do something with image
                        DispatchQueue.main.async {
                            self.image = Image(uiImage: image)
                        }
                    }
                }
            }
        }
    }
}


