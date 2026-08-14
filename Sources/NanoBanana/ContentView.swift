import SwiftUI
import UniformTypeIdentifiers

struct ReferenceImage: Identifiable {
    let id = UUID()
    let data: Data

    var nsImage: NSImage? { NSImage(data: data) }
}

struct ContentView: View {
    @State private var prompt = ""
    @State private var modelID = OpenRouterService.defaultModelID
    @State private var resolution = ""
    @State private var aspectRatio = ""
    @State private var quality = ""
    @State private var imageCount = 1
    @State private var referenceImages: [ReferenceImage] = []
    @State private var results: [GeneratedImage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingImporter = false
    @State private var apiKeyOverride = ""
    @State private var zoomed = false

    private var selectedModel: ImageModel {
        OpenRouterService.catalog.first { $0.id == modelID } ?? OpenRouterService.catalog[0]
    }

    private var envKeySet: Bool {
        !(ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? "").isEmpty
    }

    private var referencesFull: Bool {
        referenceImages.count >= selectedModel.maxReferences
    }

    var body: some View {
        HSplitView {
            leftPanel
                .frame(minWidth: 420)

            rightPanel
                .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Model", selection: $modelID) {
                ForEach(OpenRouterService.catalog) { model in
                    Text(model.name).tag(model.id)
                }
            }
            .labelsHidden()
            .onChange(of: modelID) {
                imageCount = min(imageCount, selectedModel.maxN)
                if !selectedModel.resolutions.contains(resolution) { resolution = "" }
                if !selectedModel.aspectRatios.contains(aspectRatio) { aspectRatio = "" }
                if !selectedModel.qualities.contains(quality) { quality = "" }
            }

            if !envKeySet {
                SecureField("OpenRouter API key", text: $apiKeyOverride)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 16) {
                if !selectedModel.resolutions.isEmpty {
                    optionPicker("Resolution", options: selectedModel.resolutions, selection: $resolution)
                }
                if !selectedModel.aspectRatios.isEmpty {
                    optionPicker("Aspect ratio", options: selectedModel.aspectRatios, selection: $aspectRatio)
                }
                if !selectedModel.qualities.isEmpty {
                    optionPicker("Quality", options: selectedModel.qualities, selection: $quality)
                }
                if selectedModel.maxN > 1 {
                    Stepper("Images: \(imageCount)", value: $imageCount, in: 1...selectedModel.maxN)
                        .fixedSize()
                }
            }

            HStack {
                Text("Reference images")
                    .font(.headline)
                Text("\(referenceImages.count)/\(selectedModel.maxReferences)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
                .disabled(referencesFull)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    for url in urls where referenceImages.count < selectedModel.maxReferences {
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
    }

    private var rightPanel: some View {
        VStack {
            if results.isEmpty {
                ContentUnavailableView(
                    "No image yet",
                    systemImage: "photo.badge.plus",
                    description: Text("Generated images will appear here.")
                )
                .frame(maxHeight: .infinity)
            } else {
                GeometryReader { geo in
                    if zoomed {
                        ScrollView([.horizontal, .vertical]) {
                            VStack(spacing: 16) {
                                ForEach(results) { image in
                                    resultCard(image, naturalSize: true)
                                        .onTapGesture { withAnimation { zoomed = false } }
                                }
                            }
                            .padding()
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(results) { image in
                                    resultCard(image, naturalSize: false)
                                        .onTapGesture { withAnimation { zoomed = true } }
                                        .frame(maxWidth: .infinity, maxHeight: max(geo.size.height - 56, 200))
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }

    @ViewBuilder
    private func resultCard(_ image: GeneratedImage, naturalSize: Bool) -> some View {
        VStack(spacing: 8) {
            if let nsImage = NSImage(data: image.data) {
                Group {
                    if naturalSize {
                        Image(nsImage: nsImage)
                            .resizable()
                            .frame(width: nsImage.size.width, height: nsImage.size.height)
                    } else {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .contentShape(Rectangle())
                .help(zoomed ? "Click to fit to window" : "Click to zoom to full size")
            }
            HStack {
                Text(zoomed ? "Click the image to fit to window" : "Click the image to zoom to full size")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    saveImage(image)
                } label: {
                    Label("Save Image…", systemImage: "square.and.arrow.down")
                }
            }
        }
    }

    private func optionPicker(_ label: String, options: [String], selection: Binding<String>) -> some View {
        Picker(label, selection: selection) {
            Text("Default").tag("")
            ForEach(options, id: \.self) { value in
                Text(value).tag(value)
            }
        }
        .fixedSize()
    }

    private func generate() {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        let imageData = referenceImages.map(\.data)
        let model = selectedModel
        let res = resolution.isEmpty ? nil : resolution
        let aspect = aspectRatio.isEmpty ? nil : aspectRatio
        let qual = quality.isEmpty ? nil : quality
        let n = imageCount
        let override = apiKeyOverride
        Task {
            do {
                let images = try await OpenRouterService().generate(
                    prompt: prompt,
                    images: imageData,
                    model: model,
                    resolution: res,
                    aspectRatio: aspect,
                    quality: qual,
                    n: n,
                    apiKeyOverride: override
                )
                results = images
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func saveImage(_ image: GeneratedImage) {
        let panel = NSSavePanel()
        var type = UTType.png
        if let mediaType = image.mediaType, let resolved = UTType(mimeType: mediaType) {
            type = resolved
        }
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = "image.\(type.preferredFilenameExtension ?? "png")"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? image.data.write(to: url)
        }
    }
}
