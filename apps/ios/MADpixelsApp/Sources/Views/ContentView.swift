import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = ImageEditorViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Image Display Area
                ImageDisplayView(
                    originalImage: viewModel.originalImage,
                    processedImage: viewModel.processedImage,
                    showOriginal: viewModel.showOriginal
                )

                // Toggle between original and processed
                if viewModel.processedImage != nil {
                    CompareToggle(showOriginal: $viewModel.showOriginal)
                        .padding(.vertical, 8)
                }

                // Processing indicator
                if viewModel.isProcessing {
                    ProcessingIndicator(progress: viewModel.progress)
                        .padding()
                }

                Divider()

                // Effect Selection
                EffectSelectorView(
                    selectedEffect: $viewModel.selectedEffect,
                    onApply: { viewModel.applyEffect() },
                    canApply: viewModel.canApplyEffect
                )
                .padding()
            }
            .navigationTitle("MADpixels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    PhotosPicker(
                        selection: $viewModel.selectedItem,
                        matching: .images
                    ) {
                        Image(systemName: "photo.on.rectangle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }

                        Menu {
                            Button {
                                viewModel.saveImage()
                            } label: {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            }
                            .disabled(viewModel.processedImage == nil)

                            Button {
                                viewModel.shareImage()
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .disabled(viewModel.processedImage == nil)

                            Divider()

                            Button(role: .destructive) {
                                viewModel.reset()
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let image = viewModel.processedImage {
                    ShareSheet(items: [image])
                }
            }
            .alert("Saved!", isPresented: $viewModel.showSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Image saved to your photo library")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(options: $viewModel.processingOptions)
            }
        }
    }
}

// MARK: - Image Display View

struct ImageDisplayView: View {
    let originalImage: UIImage?
    let processedImage: UIImage?
    let showOriginal: Bool

    var displayImage: UIImage? {
        showOriginal ? originalImage : (processedImage ?? originalImage)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGroupedBackground)

                if let image = displayImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)

                        Text("Select a photo to get started")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Compare Toggle

struct CompareToggle: View {
    @Binding var showOriginal: Bool

    var body: some View {
        HStack {
            Text("Original")
                .foregroundStyle(showOriginal ? .primary : .secondary)

            Toggle("", isOn: $showOriginal)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))

            Text("Processed")
                .foregroundStyle(!showOriginal ? .primary : .secondary)
        }
        .font(.caption)
    }
}

// MARK: - Processing Indicator

struct ProcessingIndicator: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)

            Text("Processing... \(Int(progress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Effect Selector View

struct EffectSelectorView: View {
    @Binding var selectedEffect: ImageProcessor.Effect
    let onApply: () -> Void
    let canApply: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Category Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ImageProcessor.Effect.Category.allCases, id: \.rawValue) { category in
                        let effectsInCategory = ImageProcessor.Effect.allCases.filter { $0.category == category }
                        let isSelected = effectsInCategory.contains(selectedEffect)

                        CategoryButton(
                            title: category.rawValue,
                            isSelected: isSelected
                        ) {
                            if let firstEffect = effectsInCategory.first {
                                selectedEffect = firstEffect
                            }
                        }
                    }
                }
            }

            // Effects in selected category
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ImageProcessor.Effect.allCases.filter { $0.category == selectedEffect.category }) { effect in
                        EffectButton(
                            title: effect.rawValue,
                            isSelected: effect == selectedEffect
                        ) {
                            selectedEffect = effect
                        }
                    }
                }
            }

            // Apply Button
            Button(action: onApply) {
                Text("Apply Effect")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canApply ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!canApply)
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct EffectButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                )
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
