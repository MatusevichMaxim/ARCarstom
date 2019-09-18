//
//  UIImage+ PixelBuffer.swift
//  CarstomApp
//
//  Created by Максим Матусевич on 7/31/19.
//  Copyright © 2019 Максим Матусевич. All rights reserved.
//

import UIKit

extension UIImage {
    
    // Returns image scaled according to the given size.
    public func resizeTo(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = scaledImage else { return nil }
        let imageData = image.pngData() ?? image.jpegData(compressionQuality: Constants.jpegCompressionQuality)
        return imageData.map { UIImage(data: $0) } ?? nil
    }
    
    func resizeImage(with size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: size.width, height: size.height))
        draw(in: CGRect(x:0, y:0, width: size.width, height: size.height))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    /// Returns scaled image data representation of the image from the given values.
    ///
    /// - Parameters
    ///   - size: Size to scale the image to (i.e. expected size of the image in the trained model).
    ///   - componentsCount: Number of color components for the image.
    ///   - batchSize: Batch size for the image.
    /// - Returns: The scaled image data or `nil` if the image could not be scaled.
    public func scaledImageData(
        with size: CGSize,
        componentsCount newComponentsCount: Int,
        batchSize: Int
        ) -> Data? {
        guard let cgImage = self.cgImage, cgImage.width > 0, cgImage.height > 0 else { return nil }
        let oldComponentsCount = cgImage.bytesPerRow / cgImage.width
        guard newComponentsCount <= oldComponentsCount else { return nil }
        
        let newWidth = Int(size.width)
        let newHeight = Int(size.height)
        guard let imageData = imageData(
            from: cgImage,
            size: size,
            componentsCount: oldComponentsCount)
            else {
                return nil
        }
        
        let bytesCount = newWidth * newHeight * newComponentsCount * batchSize
        var scaledBytes = [UInt8](repeating: 0, count: bytesCount)
        
        // Extract the RGB(A) components from the scaled image data while ignoring the alpha component.
        var pixelIndex = 0
        for pixel in imageData.enumerated() {
            let offset = pixel.offset
            let isAlphaComponent = (offset % Constants.alphaComponentBaseOffset) ==
                Constants.alphaComponentModuloRemainder
            guard !isAlphaComponent else { continue }
            scaledBytes[pixelIndex] = pixel.element
            pixelIndex += 1
        }
        
        let scaledImageData = Data(_: scaledBytes)
        return scaledImageData
    }
    
    /// Returns a scaled pixel array representation of the image from the given values.
    ///
    /// - Parameters
    ///   - size: Size to scale the image to (i.e. expected size of the image in the trained model).
    ///   - componentsCount: Number of color components for the image.
    ///   - batchSize: Batch size for the image.
    ///   - isQuantized: Indicates whether the model uses quantization. If `true`, apply
    ///     `(value - mean) / std` to each pixel to convert the data from Int(0, 255) scale to
    ///     Float(-1, 1).
    /// - Returns: The scaled pixel array or `nil` if the image could not be scaled.
    public func scaledPixelArray(
        with size: CGSize,
        componentsCount newComponentsCount: Int,
        batchSize: Int,
        isQuantized: Bool
        ) -> [[[[Any]]]]? {
        guard let cgImage = self.cgImage, cgImage.width > 0, cgImage.height > 0 else { return nil }
        let oldComponentsCount = cgImage.bytesPerRow / cgImage.width
        guard newComponentsCount <= oldComponentsCount else { return nil }
        
        let newWidth = Int(size.width)
        let newHeight = Int(size.height)
        guard let imageData = imageData(
            from: cgImage,
            size: size,
            componentsCount: oldComponentsCount)
            else {
                return nil
        }
        
        var columnArray: [[[Any]]] = isQuantized ? [[[UInt8]]]() : [[[Float32]]]()
        for yCoordinate in 0..<newWidth {
            var rowArray: [[Any]] = isQuantized ? [[UInt8]]() : [[Float32]]()
            for xCoordinate in 0..<newHeight {
                var pixelArray: [Any] = isQuantized ? [UInt8]() : [Float32]()
                for component in 0..<newComponentsCount {
                    let inputIndex =
                        (yCoordinate * newHeight * oldComponentsCount) +
                            (xCoordinate * oldComponentsCount + component)
                    let pixel = imageData[inputIndex]
                    if isQuantized {
                        pixelArray.append(pixel)
                    } else {
                        // Convert pixel values from [0, 255] to [-1, 1] scale.
                        let pixel = (Float32(pixel) - Constants.meanRGBValue) / Constants.stdRGBValue
                        pixelArray.append(pixel)
                    }
                }
                rowArray.append(pixelArray)
            }
            columnArray.append(rowArray)
        }
        return [columnArray]
    }
    
    
    // MARK: - Private
    
    
    /// Returns the image data from the given CGImage resized to the given width and height.
    private func imageData(
        from image: CGImage,
        size: CGSize,
        componentsCount: Int
        ) -> Data? {
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        )
        let width = Int(size.width)
        let height = Int(size.height)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: componentsCount * width,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue)
            else {
                return nil
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()?.dataProvider?.data as Data?
    }
}


// MARK: - Constants


private enum Constants {
    static let maxRGBValue: Float32 = 255.0
    static let meanRGBValue: Float32 = maxRGBValue / 2.0
    static let stdRGBValue: Float32 = maxRGBValue / 2.0
    static let jpegCompressionQuality: CGFloat = 0.8
    static let alphaComponentBaseOffset = 4
    static let alphaComponentModuloRemainder = 3
}
