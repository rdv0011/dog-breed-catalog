//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

/// Constants for either images from a bundle or system images
/// Allows to avoid string literals to instantiate images in the code
/// - Tag: Asset
enum Asset {
    static let heart = SystemImageAsset(name: "heart")
    static let heartFill = SystemImageAsset(name: "heart.fill")
}

struct ImageAsset: Hashable {
    fileprivate(set) var name: String
    typealias Image = UIImage

    var imageView: UIImageView {
        guard let image = UIImage(asset: self) else {
            fatalError("Failed to init image: \(self)")
        }
        return UIImageView(image: image)
    }
}

extension ImageAsset.Image {
    convenience init?(asset: ImageAsset) {
        let bundle = BundleToken.bundle
        self.init(named: asset.name,
                  in: bundle,
                  compatibleWith: nil)
    }
}

struct SystemImageAsset: Hashable {
    fileprivate(set) var name: String
    typealias Image = UIImage

    var imageView: UIImageView {
        guard let image = UIImage(asset: self) else {
            fatalError("Failed to init image: \(self)")
        }
        return UIImageView(image: image)
    }
}

extension SystemImageAsset.Image {
    convenience init?(asset: SystemImageAsset) {
        self.init(systemName: asset.name,
                  compatibleWith: nil)
    }
}

private final class BundleToken {
  static let bundle: Bundle = {
    Bundle(for: BundleToken.self)
  }()
}
