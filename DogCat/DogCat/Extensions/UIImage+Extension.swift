//
// Copyright © 2020 Rybakov Dmitry. All rights reserved.

import Foundation
import UIKit
import Combine

extension UIImage {
    /// Estimated size of the decompressed image
    var decompressedSize: Int {
        let height = self.size.height
        let width = self.size.width
        var bytesPerRow = 4 * width
        if bytesPerRow.truncatingRemainder(dividingBy: 16) != 0 {
            bytesPerRow = ((bytesPerRow / 16) + 1) * 16
        }
        return Int(height * bytesPerRow)
    }


    /// - Returns: Decompressed version of the image to speed up rendering in the UI
    func decompressed() -> UIImage {
        guard let imageRef = self.cgImage else {
            log.error("Failed to get a context")
            return UIImage()
        }
        let rect = CGRect(x: 0,
                          y: 0,
                          width: imageRef.width,
                          height: imageRef.height)
        // If colorSpace is not defined use RGB by default
        let colorSpace = imageRef.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        // kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little are the bit flags required so that the main thread doesn't have any conversions to do.
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let context = CGContext(data: nil,
                                      width: Int(rect.size.width),
                                      height: Int(rect.size.height),
                                      bitsPerComponent: imageRef.bitsPerComponent,
                                      bytesPerRow: imageRef.bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            log.error("CGContext creation failed")
            return UIImage()
        }

        context.draw(imageRef, in: rect)
        guard let decompressedImageRef = context.makeImage() else {
            log.error("Failed to create image from context")
            return UIImage()
        }

        return UIImage(cgImage: decompressedImageRef)
    }
}
