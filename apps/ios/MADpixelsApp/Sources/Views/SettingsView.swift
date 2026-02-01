import SwiftUI

struct SettingsView: View {
    @Binding var options: ImageProcessor.Options
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Output Size") {
                    Stepper("Width: \(options.width)px", value: $options.width, in: 128...2048, step: 64)
                    Stepper("Height: \(options.height)px", value: $options.height, in: 128...2048, step: 64)
                }

                Section("Shuffle Settings") {
                    Stepper("Block Size: \(options.blockSize)px", value: $options.blockSize, in: 4...128, step: 4)

                    VStack(alignment: .leading) {
                        Text("Spread: \(String(format: "%.2f", options.spread))")
                        Slider(value: $options.spread, in: 0...1)
                    }
                }

                Section("Blur Settings") {
                    Stepper("Kernel Size: \(options.kernelSize)", value: $options.kernelSize, in: 1...200, step: 5)
                }

                Section("Boost Settings") {
                    VStack(alignment: .leading) {
                        Text("Red Boost: \(String(format: "%.2f", options.boostRed))")
                        Slider(value: $options.boostRed, in: 0...1)
                    }

                    VStack(alignment: .leading) {
                        Text("Green Boost: \(String(format: "%.2f", options.boostGreen))")
                        Slider(value: $options.boostGreen, in: 0...1)
                    }

                    VStack(alignment: .leading) {
                        Text("Blue Boost: \(String(format: "%.2f", options.boostBlue))")
                        Slider(value: $options.boostBlue, in: 0...1)
                    }
                }

                Section {
                    Button("Reset to Defaults") {
                        options = ImageProcessor.Options()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(options: .constant(ImageProcessor.Options()))
}
