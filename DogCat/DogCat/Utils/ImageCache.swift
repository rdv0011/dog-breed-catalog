//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation
import UIKit

/// Implements 2 levels of caching for compressed and decompressed images
/// If it exceeds the memory ;limits the second level might be emptied
/// Since the first level occupies significantly less memory it may still stay in the memory
/// Which still allows to skip time consuming downloading
/// - Tag: ImageCache
final class ImageCache {

    // 1st level cache, that contains encoded images
    private lazy var imageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.countLimit = config.countLimit
        return cache
    }()
    // 2nd level cache, that contains decompressed images
    private lazy var decompressedImageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.totalCostLimit = config.memoryLimit
        return cache
    }()
    private let lock = NSLock()
    private let config: Config

    struct Config {
        let countLimit: Int
        let memoryLimit: Int

        static let defaultConfig = Config(countLimit: 30,
                                          memoryLimit: 1024 * 1024 * 30)
    }

    init(config: Config = Config.defaultConfig) {
        self.config = config
    }

    /// Returns image by provided url if it existing in a cache
    func image(for url: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        // the best case scenario -> there is a decoded image
        if let decompressedImage = decompressedImageCache.object(forKey: url as AnyObject) as? UIImage {
            return decompressedImage
        }
        // search for image data
        if let image = imageCache.object(forKey: url as AnyObject) as? UIImage {
            let decompressedImage = image.decompressed()
            decompressedImageCache.setObject(image as AnyObject, forKey: url as AnyObject, cost: decompressedImage.decompressedSize)
            return decompressedImage
        }
        return nil
    }

    /// Remove image from a cache
    /// - Parameters:
    ///   - image:Image object to add to a cache. Object associated with ```url``` will be removed If nil is provided
    ///   - url: Image url with which it should be associated in a cache
    func insertImage(_ image: UIImage?, for url: URL) {
        guard let image = image else { return removeImage(for: url) }
        let decompressedImage = image.decompressed()

        lock.lock(); defer { lock.unlock() }
        imageCache.setObject(image, forKey: url as AnyObject)
        decompressedImageCache.setObject(decompressedImage as AnyObject, forKey: url as AnyObject, cost: decompressedImage.decompressedSize)
    }

    /// Remove image by provided url from a cache
    func removeImage(for url: URL) {
        lock.lock(); defer { lock.unlock() }
        imageCache.removeObject(forKey: url as AnyObject)
        decompressedImageCache.removeObject(forKey: url as AnyObject)
    }

    // MARK: - Helper function
    subscript(_ key: URL) -> UIImage? {
        get {
            return image(for: key)
        }
        set {
            return insertImage(newValue, for: key)
        }
    }
}
