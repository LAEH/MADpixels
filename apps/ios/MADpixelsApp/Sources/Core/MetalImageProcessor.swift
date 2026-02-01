import Metal
import MetalKit
import MetalPerformanceShaders

/// GPU-accelerated image processor using Metal
final class MetalImageProcessor {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary

    // Compute pipelines for each effect
    private var globalShufflePipeline: MTLComputePipelineState?
    private var binedShufflePipeline: MTLComputePipelineState?
    private var localShufflePipeline: MTLComputePipelineState?
    private var boostPipeline: MTLComputePipelineState?
    private var invertPipeline: MTLComputePipelineState?

    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue

        // Load shader library
        guard let library = try? device.makeDefaultLibrary(bundle: .main) else {
            return nil
        }
        self.library = library

        setupPipelines()
    }

    private func setupPipelines() {
        globalShufflePipeline = makePipeline(named: "globalShuffleKernel")
        binedShufflePipeline = makePipeline(named: "binedShuffleKernel")
        localShufflePipeline = makePipeline(named: "localShuffleKernel")
        boostPipeline = makePipeline(named: "boostKernel")
        invertPipeline = makePipeline(named: "invertKernel")
    }

    private func makePipeline(named name: String) -> MTLComputePipelineState? {
        guard let function = library.makeFunction(name: name) else { return nil }
        return try? device.makeComputePipelineState(function: function)
    }

    // MARK: - Texture Management

    func makeTexture(from image: UIImage) -> MTLTexture? {
        guard let cgImage = image.cgImage else { return nil }

        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.topLeft,
            .SRGB: false
        ]

        return try? textureLoader.newTexture(cgImage: cgImage, options: options)
    }

    func makeOutputTexture(width: Int, height: Int) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        return device.makeTexture(descriptor: descriptor)
    }

    func textureToUIImage(_ texture: MTLTexture) -> UIImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let region = MTLRegionMake2D(0, 0, width, height)

        texture.getBytes(&pixels, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ),
        let cgImage = context.makeImage() else { return nil }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - GPU Effects

    func invert(_ image: UIImage) -> UIImage? {
        guard let pipeline = invertPipeline,
              let inputTexture = makeTexture(from: image),
              let outputTexture = makeOutputTexture(width: inputTexture.width, height: inputTexture.height),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return nil
        }

        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)

        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (inputTexture.width + 15) / 16,
            height: (inputTexture.height + 15) / 16,
            depth: 1
        )

        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return textureToUIImage(outputTexture)
    }

    func boost(_ image: UIImage, red: Float, green: Float, blue: Float) -> UIImage? {
        guard let pipeline = boostPipeline,
              let inputTexture = makeTexture(from: image),
              let outputTexture = makeOutputTexture(width: inputTexture.width, height: inputTexture.height),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return nil
        }

        // Pass boost parameters
        var params = SIMD3<Float>(red, green, blue)
        let paramsBuffer = device.makeBuffer(bytes: &params, length: MemoryLayout<SIMD3<Float>>.size)

        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)
        encoder.setBuffer(paramsBuffer, offset: 0, index: 0)

        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (inputTexture.width + 15) / 16,
            height: (inputTexture.height + 15) / 16,
            depth: 1
        )

        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return textureToUIImage(outputTexture)
    }

    func gaussianBlur(_ image: UIImage, radius: Float) -> UIImage? {
        guard let inputTexture = makeTexture(from: image),
              let outputTexture = makeOutputTexture(width: inputTexture.width, height: inputTexture.height),
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return nil
        }

        // Use Metal Performance Shaders for optimized blur
        let blur = MPSImageGaussianBlur(device: device, sigma: radius)
        blur.encode(commandBuffer: commandBuffer, sourceTexture: inputTexture, destinationTexture: outputTexture)

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return textureToUIImage(outputTexture)
    }

    func localShuffle(_ image: UIImage, spread: Float, seed: UInt32) -> UIImage? {
        guard let pipeline = localShufflePipeline,
              let inputTexture = makeTexture(from: image),
              let outputTexture = makeOutputTexture(width: inputTexture.width, height: inputTexture.height),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return nil
        }

        var params = ShuffleParams(spread: spread, seed: seed, width: UInt32(inputTexture.width), height: UInt32(inputTexture.height))
        let paramsBuffer = device.makeBuffer(bytes: &params, length: MemoryLayout<ShuffleParams>.size)

        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)
        encoder.setBuffer(paramsBuffer, offset: 0, index: 0)

        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (inputTexture.width + 15) / 16,
            height: (inputTexture.height + 15) / 16,
            depth: 1
        )

        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return textureToUIImage(outputTexture)
    }
}

// MARK: - Shader Parameters

struct ShuffleParams {
    var spread: Float
    var seed: UInt32
    var width: UInt32
    var height: UInt32
}

struct BoostParams {
    var redBoost: Float
    var greenBoost: Float
    var blueBoost: Float
    var padding: Float = 0
}
