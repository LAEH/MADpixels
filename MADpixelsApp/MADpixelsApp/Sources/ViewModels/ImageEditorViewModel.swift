import SwiftUI
import PhotosUI

@MainActor
final class ImageEditorViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var originalImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var selectedEffect: ImageProcessor.Effect = .globalShuffle
    @Published var showOriginal = false
    @Published var isProcessing = false
    @Published var progress: Double = 0

    @Published var showShareSheet = false
    @Published var showSaveSuccess = false
    @Published var showError = false
    @Published var errorMessage = ""

    @Published var selectedItem: PhotosPickerItem? {
        didSet {
            loadImage()
        }
    }

    // MARK: - Processing Options

    @Published var processingOptions = ImageProcessor.Options()

    // MARK: - Private Properties

    private let processor = ImageProcessor()

    // MARK: - Computed Properties

    var canApplyEffect: Bool {
        originalImage != nil && !isProcessing
    }

    // MARK: - Methods

    func applyEffect() {
        guard let image = originalImage else { return }

        Task {
            isProcessing = true
            progress = 0

            // Subscribe to processor progress
            let progressTask = Task {
                for await _ in Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().values {
                    progress = processor.progress
                    if !processor.isProcessing { break }
                }
            }

            let result = await processor.apply(selectedEffect, to: image, options: processingOptions)

            progressTask.cancel()

            processedImage = result
            showOriginal = false
            isProcessing = false
            progress = 1.0
        }
    }

    func saveImage() {
        guard let image = processedImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    self?.errorMessage = "Photo library access denied"
                    self?.showError = true
                    return
                }

                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                self?.showSaveSuccess = true
            }
        }
    }

    func shareImage() {
        guard processedImage != nil else { return }
        showShareSheet = true
    }

    func reset() {
        processedImage = nil
        showOriginal = false
        progress = 0
    }

    // MARK: - Private Methods

    private func loadImage() {
        guard let item = selectedItem else { return }

        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    originalImage = image
                    processedImage = nil
                    showOriginal = false
                }
            } catch {
                errorMessage = "Failed to load image: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}
