import Foundation
import CoreImage
import UIKit
import Accelerate

/// Core image processing engine for MADpixels
/// Ported from Lua/Torch implementation to native Swift with Accelerate framework
@MainActor
final class ImageProcessor: ObservableObject {

    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var progress: Double = 0

    // MARK: - Available Effects
    enum Effect: String, CaseIterable, Identifiable {
        case globalShuffle = "Global Shuffle"
        case binedShuffle = "Bined Shuffle"
        case localShuffle = "Local Shuffle"
        case binedColorShuffle = "Color Shuffle"
        case invert = "Invert"
        case boost = "Boost"
        case gaussianBlur = "Gaussian Blur"
        case gradient = "Gradient"

        var id: String { rawValue }

        var category: Category {
            switch self {
            case .globalShuffle, .binedShuffle, .localShuffle, .binedColorShuffle:
                return .shuffles
            case .invert, .boost, .gaussianBlur:
                return .transforms
            case .gradient:
                return .creations
            }
        }

        enum Category: String, CaseIterable {
            case shuffles = "Shuffles"
            case transforms = "Transforms"
            case creations = "Creations"
        }
    }

    // MARK: - Processing Options
    struct Options {
        var width: Int = 512
        var height: Int = 512
        var blockSize: Int = 16
        var spread: Float = 0.25
        var kernelSize: Int = 50
        var boostRed: Float = 0.4
        var boostGreen: Float = 0.3
        var boostBlue: Float = 0.2
    }

    // MARK: - Apply Effect
    func apply(_ effect: Effect, to image: UIImage, options: Options = Options()) async -> UIImage? {
        isProcessing = true
        progress = 0
        defer {
            isProcessing = false
            progress = 1.0
        }

        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return nil }

            switch effect {
            case .globalShuffle:
                return await self.globalShuffle(image, options: options)
            case .binedShuffle:
                return await self.binedShuffle(image, options: options)
            case .localShuffle:
                return await self.localShuffle(image, options: options)
            case .binedColorShuffle:
                return await self.binedColorShuffle(image, options: options)
            case .invert:
                return self.invert(image)
            case .boost:
                return self.boost(image, options: options)
            case .gaussianBlur:
                return self.gaussianBlur(image, options: options)
            case .gradient:
                return self.createGradient(options: options)
            }
        }.value
    }

    // MARK: - Shuffle Effects

    /// Randomly shuffles all pixels globally across the entire image
    private func globalShuffle(_ image: UIImage, options: Options) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = options.width
        let height = options.height
        let scaledImage = resizeImage(cgImage, to: CGSize(width: width, height: height))

        guard let pixelData = getPixelData(from: scaledImage) else { return nil }

        var pixels = pixelData
        let pixelCount = width * height

        // Fisher-Yates shuffle
        for i in stride(from: pixelCount - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            let iOffset = i * 4
            let jOffset = j * 4

            // Swap RGBA values
            for c in 0..<4 {
                pixels.swapAt(iOffset + c, jOffset + c)
            }

            if i % 10000 == 0 {
                await MainActor.run { [weak self] in
                    self?.progress = Double(pixelCount - i) / Double(pixelCount)
                }
            }
        }

        return createImage(from: pixels, width: width, height: height)
    }

    /// Divides image into blocks and shuffles pixels within each block
    private func binedShuffle(_ image: UIImage, options: Options) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = options.width
        let height = options.height
        let blockSize = options.blockSize
        let scaledImage = resizeImage(cgImage, to: CGSize(width: width, height: height))

        guard var pixels = getPixelData(from: scaledImage) else { return nil }

        let blocksX = width / blockSize
        let blocksY = height / blockSize
        let totalBlocks = blocksX * blocksY
        var processedBlocks = 0

        // Process each block
        for by in 0..<blocksY {
            for bx in 0..<blocksX {
                // Collect pixel indices in this block
                var blockIndices: [Int] = []
                for ly in 0..<blockSize {
                    for lx in 0..<blockSize {
                        let x = bx * blockSize + lx
                        let y = by * blockSize + ly
                        blockIndices.append(y * width + x)
                    }
                }

                // Shuffle within block
                let shuffledIndices = blockIndices.shuffled()
                var tempPixels = [UInt8](repeating: 0, count: blockIndices.count * 4)

                for (i, srcIdx) in shuffledIndices.enumerated() {
                    for c in 0..<4 {
                        tempPixels[i * 4 + c] = pixels[srcIdx * 4 + c]
                    }
                }

                for (i, dstIdx) in blockIndices.enumerated() {
                    for c in 0..<4 {
                        pixels[dstIdx * 4 + c] = tempPixels[i * 4 + c]
                    }
                }

                processedBlocks += 1
                if processedBlocks % 10 == 0 {
                    await MainActor.run { [weak self] in
                        self?.progress = Double(processedBlocks) / Double(totalBlocks)
                    }
                }
            }
        }

        return createImage(from: pixels, width: width, height: height)
    }

    /// Applies local displacement to pixels with configurable spread
    private func localShuffle(_ image: UIImage, options: Options) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let spread = options.spread * Float(max(width, height)) / 4.0

        guard spread > 0, var pixels = getPixelData(from: cgImage) else {
            return image
        }

        let pixelCount = width * height

        for i in 0..<pixelCount {
            let x = i % width
            let y = i / width

            // Generate normal-distributed offset
            let offsetX = Int(gaussianRandom() * Double(spread))
            let offsetY = Int(gaussianRandom() * Double(spread))

            let newX = max(0, min(width - 1, x + offsetX))
            let newY = max(0, min(height - 1, y + offsetY))
            let newIdx = newY * width + newX

            // Swap pixels
            for c in 0..<4 {
                pixels.swapAt(i * 4 + c, newIdx * 4 + c)
            }

            if i % 10000 == 0 {
                await MainActor.run { [weak self] in
                    self?.progress = Double(i) / Double(pixelCount)
                }
            }
        }

        return createImage(from: pixels, width: width, height: height)
    }

    /// Creates colorful block patterns based on sampled colors
    private func binedColorShuffle(_ image: UIImage, options: Options) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = options.width
        let height = options.height
        let blockSize = options.blockSize
        let scaledImage = resizeImage(cgImage, to: CGSize(width: width, height: height))

        guard let sourcePixels = getPixelData(from: scaledImage) else { return nil }

        // Sample colors from the image
        var sampledColors: [(h: Float, s: Float, l: Float)] = []
        for _ in 0..<100 {
            let idx = Int.random(in: 0..<(width * height))
            let r = Float(sourcePixels[idx * 4]) / 255.0
            let g = Float(sourcePixels[idx * 4 + 1]) / 255.0
            let b = Float(sourcePixels[idx * 4 + 2]) / 255.0
            sampledColors.append(rgbToHSL(r: r, g: g, b: b))
        }

        var pixels = [UInt8](repeating: 255, count: width * height * 4)

        let blocksX = width / blockSize
        let blocksY = height / blockSize
        let totalBlocks = blocksX * blocksY
        var processedBlocks = 0

        for by in 0..<blocksY {
            for bx in 0..<blocksX {
                let baseColor = sampledColors.randomElement()!

                for ly in 0..<blockSize {
                    for lx in 0..<blockSize {
                        let x = bx * blockSize + lx
                        let y = by * blockSize + ly
                        let idx = (y * width + x) * 4

                        let h = baseColor.h
                        let s = baseColor.s * Float.random(in: 1.0...1.5)
                        let l = baseColor.l * Float.random(in: 0.0...1.5)

                        let (r, g, b) = hslToRGB(h: h, s: min(1, s), l: min(1, max(0, l)))
                        pixels[idx] = UInt8(min(255, max(0, r * 255)))
                        pixels[idx + 1] = UInt8(min(255, max(0, g * 255)))
                        pixels[idx + 2] = UInt8(min(255, max(0, b * 255)))
                        pixels[idx + 3] = 255
                    }
                }

                processedBlocks += 1
                if processedBlocks % 10 == 0 {
                    await MainActor.run { [weak self] in
                        self?.progress = Double(processedBlocks) / Double(totalBlocks)
                    }
                }
            }
        }

        return createImage(from: pixels, width: width, height: height)
    }

    // MARK: - Transform Effects

    /// Inverts all color values (creates negative)
    private func invert(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image),
              let filter = CIFilter(name: "CIColorInvert") else { return nil }

        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    /// Normalizes and enhances image contrast with selective channel boosting
    private func boost(_ image: UIImage, options: Options) -> UIImage? {
        guard let cgImage = image.cgImage,
              var pixels = getPixelData(from: cgImage) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let pixelCount = width * height

        // Calculate mean
        var sumR: Float = 0, sumG: Float = 0, sumB: Float = 0
        for i in 0..<pixelCount {
            sumR += Float(pixels[i * 4])
            sumG += Float(pixels[i * 4 + 1])
            sumB += Float(pixels[i * 4 + 2])
        }
        let meanR = sumR / Float(pixelCount)
        let meanG = sumG / Float(pixelCount)
        let meanB = sumB / Float(pixelCount)

        // Calculate std dev
        var varR: Float = 0, varG: Float = 0, varB: Float = 0
        for i in 0..<pixelCount {
            let dr = Float(pixels[i * 4]) - meanR
            let dg = Float(pixels[i * 4 + 1]) - meanG
            let db = Float(pixels[i * 4 + 2]) - meanB
            varR += dr * dr
            varG += dg * dg
            varB += db * db
        }
        let stdR = sqrt(varR / Float(pixelCount))
        let stdG = sqrt(varG / Float(pixelCount))
        let stdB = sqrt(varB / Float(pixelCount))

        // Apply boost with soft clipping
        for i in 0..<pixelCount {
            let r = (Float(pixels[i * 4]) - meanR) / max(stdR, 1) * options.boostRed
            let g = (Float(pixels[i * 4 + 1]) - meanG) / max(stdG, 1) * options.boostGreen
            let b = (Float(pixels[i * 4 + 2]) - meanB) / max(stdB, 1) * options.boostBlue

            // Soft clip using tanh
            let clippedR = (tanh(r * 4) + 1) / 2
            let clippedG = (tanh(g * 4) + 1) / 2
            let clippedB = (tanh(b * 4) + 1) / 2

            pixels[i * 4] = UInt8(min(255, max(0, clippedR * 255)))
            pixels[i * 4 + 1] = UInt8(min(255, max(0, clippedG * 255)))
            pixels[i * 4 + 2] = UInt8(min(255, max(0, clippedB * 255)))
        }

        return createImage(from: pixels, width: width, height: height)
    }

    /// Applies Gaussian blur using Core Image
    private func gaussianBlur(_ image: UIImage, options: Options) -> UIImage? {
        guard let ciImage = CIImage(image: image),
              let filter = CIFilter(name: "CIGaussianBlur") else { return nil }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(Float(options.kernelSize) / 2, forKey: kCIInputRadiusKey)

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Creation Effects

    /// Creates a gradient image with random corner colors
    private func createGradient(options: Options) -> UIImage? {
        let width = options.width
        let height = options.height

        // Random corner colors
        let tl = (r: Float.random(in: 0...1), g: Float.random(in: 0...1), b: Float.random(in: 0...1))
        let tr = (r: Float.random(in: 0...1), g: Float.random(in: 0...1), b: Float.random(in: 0...1))
        let bl = (r: Float.random(in: 0...1), g: Float.random(in: 0...1), b: Float.random(in: 0...1))
        let br = (r: Float.random(in: 0...1), g: Float.random(in: 0...1), b: Float.random(in: 0...1))

        var pixels = [UInt8](repeating: 255, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                let fx = Float(x) / Float(width - 1)
                let fy = Float(y) / Float(height - 1)

                // Bilinear interpolation
                let top = (
                    r: tl.r * (1 - fx) + tr.r * fx,
                    g: tl.g * (1 - fx) + tr.g * fx,
                    b: tl.b * (1 - fx) + tr.b * fx
                )
                let bottom = (
                    r: bl.r * (1 - fx) + br.r * fx,
                    g: bl.g * (1 - fx) + br.g * fx,
                    b: bl.b * (1 - fx) + br.b * fx
                )

                let r = top.r * (1 - fy) + bottom.r * fy
                let g = top.g * (1 - fy) + bottom.g * fy
                let b = top.b * (1 - fy) + bottom.b * fy

                let idx = (y * width + x) * 4
                pixels[idx] = UInt8(r * 255)
                pixels[idx + 1] = UInt8(g * 255)
                pixels[idx + 2] = UInt8(b * 255)
                pixels[idx + 3] = 255
            }
        }

        return createImage(from: pixels, width: width, height: height)
    }

    // MARK: - Helper Functions

    private func resizeImage(_ cgImage: CGImage, to size: CGSize) -> CGImage {
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width) * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        return context.makeImage()!
    }

    private func getPixelData(from cgImage: CGImage) -> [UInt8]? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return pixels
    }

    private func createImage(from pixels: [UInt8], width: Int, height: Int) -> UIImage? {
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var mutablePixels = pixels

        guard let context = CGContext(
            data: &mutablePixels,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ),
        let cgImage = context.makeImage() else { return nil }

        return UIImage(cgImage: cgImage)
    }

    private func gaussianRandom() -> Double {
        // Box-Muller transform
        let u1 = Double.random(in: 0.0001...1)
        let u2 = Double.random(in: 0...1)
        return sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }

    private func rgbToHSL(r: Float, g: Float, b: Float) -> (h: Float, s: Float, l: Float) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let l = (maxC + minC) / 2

        if maxC == minC {
            return (0, 0, l)
        }

        let d = maxC - minC
        let s = l > 0.5 ? d / (2 - maxC - minC) : d / (maxC + minC)

        var h: Float
        switch maxC {
        case r: h = (g - b) / d + (g < b ? 6 : 0)
        case g: h = (b - r) / d + 2
        default: h = (r - g) / d + 4
        }
        h /= 6

        return (h, s, l)
    }

    private func hslToRGB(h: Float, s: Float, l: Float) -> (r: Float, g: Float, b: Float) {
        if s == 0 {
            return (l, l, l)
        }

        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q

        func hueToRGB(_ p: Float, _ q: Float, _ t: Float) -> Float {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1/6 { return p + (q - p) * 6 * t }
            if t < 1/2 { return q }
            if t < 2/3 { return p + (q - p) * (2/3 - t) * 6 }
            return p
        }

        return (
            hueToRGB(p, q, h + 1/3),
            hueToRGB(p, q, h),
            hueToRGB(p, q, h - 1/3)
        )
    }
}
