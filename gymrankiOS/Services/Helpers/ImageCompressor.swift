//
//  ImageCompressor.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 12/03/2026.
//

import Foundation
import UIKit

enum ImageCompressor {

    static func jpegData(
        from image: UIImage,
        maxDimension: CGFloat,
        compressionQuality: CGFloat
    ) throws -> Data {
        let resized = resize(image: image, maxDimension: maxDimension)

        guard let data = resized.jpegData(compressionQuality: compressionQuality) else {
            throw NSError(
                domain: "ImageCompressor",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo generar JPEG"]
            )
        }

        return data
    }

    static func resize(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxCurrentDimension = max(size.width, size.height)

        guard maxCurrentDimension > maxDimension else {
            return image
        }

        let scale = maxDimension / maxCurrentDimension
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
