import SwiftUI
import UniformTypeIdentifiers

struct ReferenceImage: Identifiable {
    let id = UUID()
    let data: Data

    var nsImage: NSImage? { NSImage(data: data) }
}

struct ContentView: View {
    @State private var prompt = ""
    @State private var model = OpenRouterService.defaultModel
    @State private var referenceImages: [ReferenceImage] = []
    @State private var resultImage: NSImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingImporter = false
    @State private var apiKeyOverride = ""

    private var envKeySet: Bool {
        !(ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? "").isEmpty
    }

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Model", selection: $model) {
                    ForEach(OpenRouterService.availableModels, id: \.self) { id in
                        Text(id).tag(id)
                    }
                }
                .labelsHidden()

                if !envKeySet {
                    SecureField("OpenRouter API key", text: $apiKeyOverride)
                        .textFieldStyle(.roundedBorder)
                }

                Text("Reference images")
                    .font(.headline)

                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(referenceImages) { ref in
                                ZStack(alignment: .topTrailing) {
                                    if let img = ref.nsImage {
                                        Image(nsImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 72, height: 72)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    Button {
                                        referenceImages.removeAll { $0.id == ref.id }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white, .black.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(3)
                                }
                            }
                        }
                    }
                    .frame(height: 80)

                    Button {
                        showingImporter = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fileImporter(
                    isPresented: $showingImporter,
                    allowedContentTypes: [.image],
                    allowsMultipleSelection: true
                ) { result in
                    if case .success(let urls) = result {
                        for url in urls {
                            if let data = try? Data(contentsOf: url) {
                                referenceImages.append(ReferenceImage(data: data))
                            }
                        }
                    }
                }

                Text("Prompt")
                    .font(.headline)

                TextEditor(text: $prompt)
                    .font(.body)
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    .disabled(isLoading)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }

                Button {
                    generate()
                } label: {
                    HStack {
                        if isLoading { ProgressView().controlSize(.small) }
                        Text(isLoading ? "Generating…" : "Generate")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .frame(minWidth: 420)

            VStack {
                if let resultImage {
                    ScrollView([.horizontal, .vertical]) {
                        Image(nsImage: resultImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    HStack {
                        Spacer()
                        Button {
                            saveImage(resultImage)
                        } label: {
                            Label("Save Image…", systemImage: "square.and.arrow.down")
                        }
                    }
                    .padding(.horizontal)
                } else {
                    ContentUnavailableView(
                        "No image yet",
                        systemImage: "photo.badge.plus",
                        description: Text("Generated images will appear here.")
                    )
                }
            }
            .padding(.vertical)
            .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func generate() {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        let imageData = referenceImages.map(\.data)
        let modelID = model
        let override = apiKeyOverride
        Task {
            do {
                let data = try await OpenRouterService().generate(
                    prompt: prompt,
                    images: imageData,
                    model: modelID,
                    apiKeyOverride: override
                )
                resultImage = NSImage(data: data)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func saveImage(_ image: NSImage) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "nano-banana.png"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if let tiff = image.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: url)
            }
        }
    }
}
