import Foundation

struct ImageModel: Identifiable, Hashable {
    let id: String
    let name: String
    let resolutions: [String]
    let aspectRatios: [String]
    let qualities: [String]
    let maxReferences: Int
    let maxN: Int
}

struct GeneratedImage: Identifiable {
    let id = UUID()
    let data: Data
    let mediaType: String?
}

struct ImageRequest: Codable {
    struct InputReference: Codable {
        let type: String
        let imageUrl: ImageURL

        enum CodingKeys: String, CodingKey {
            case type
            case imageUrl = "image_url"
        }
    }
    struct ImageURL: Codable {
        let url: String
    }

    let model: String
    let prompt: String
    let n: Int
    let resolution: String?
    let aspectRatio: String?
    let quality: String?
    let inputReferences: [InputReference]?

    enum CodingKeys: String, CodingKey {
        case model, prompt, n, resolution, quality
        case aspectRatio = "aspect_ratio"
        case inputReferences = "input_references"
    }
}

struct ImageResponse: Decodable {
    struct Image: Decodable {
        let b64Json: String
        let mediaType: String?

        enum CodingKeys: String, CodingKey {
            case b64Json = "b64_json"
            case mediaType = "media_type"
        }
    }
    struct APIError: Decodable {
        let message: String
    }

    let data: [Image]
    let error: APIError?
}

enum OpenRouterError: LocalizedError {
    case missingKey
    case badResponse
    case tooManyReferences(Int)
    case api(String)

    var errorDescription: String? {
        switch self {
        case .missingKey: "OPENROUTER_API_KEY is not set in the environment and no key was entered."
        case .badResponse: "Received an unexpected response from OpenRouter."
        case .tooManyReferences(let max): "This model supports at most \(max) reference images."
        case .api(let msg): "OpenRouter API error: \(msg)"
        }
    }
}

struct OpenRouterService {
    static let defaultModelID = "google/gemini-3.1-flash-image"
    static let catalog: [ImageModel] = [
        ImageModel(id: "google/gemini-3.1-flash-image",
                   name: "Nano Banana 2 (Gemini 3.1 Flash Image)",
                   resolutions: ["512", "1K", "2K", "4K"],
                   aspectRatios: ["1:1", "1:4", "1:8", "2:3", "3:2", "3:4", "4:1", "4:3", "4:5", "5:4", "8:1", "9:16", "16:9", "21:9"],
                   qualities: [], maxReferences: 14, maxN: 1),
        ImageModel(id: "google/gemini-2.5-flash-image",
                   name: "Nano Banana (Gemini 2.5 Flash Image)",
                   resolutions: [],
                   aspectRatios: ["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"],
                   qualities: [], maxReferences: 3, maxN: 1),
        ImageModel(id: "google/gemini-3-pro-image",
                   name: "Nano Banana Pro (Gemini 3 Pro Image)",
                   resolutions: ["1K", "2K", "4K"],
                   aspectRatios: ["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"],
                   qualities: [], maxReferences: 14, maxN: 1),
        ImageModel(id: "google/gemini-3.1-flash-lite-image",
                   name: "Gemini 3.1 Flash Lite Image",
                   resolutions: ["1K"],
                   aspectRatios: ["1:1", "1:4", "1:8", "2:3", "3:2", "3:4", "4:1", "4:3", "4:5", "5:4", "8:1", "9:16", "16:9", "21:9"],
                   qualities: [], maxReferences: 14, maxN: 1),
        ImageModel(id: "openai/gpt-image-2",
                   name: "GPT Image 2",
                   resolutions: [],
                   aspectRatios: ["1:1", "3:2", "2:3", "4:3", "3:4", "16:9", "9:16", "21:9", "auto"],
                   qualities: ["auto", "low", "medium", "high"], maxReferences: 16, maxN: 10),
        ImageModel(id: "openai/gpt-image-1",
                   name: "GPT Image 1",
                   resolutions: [],
                   aspectRatios: ["1:1", "3:2", "2:3", "auto"],
                   qualities: ["auto", "low", "medium", "high"], maxReferences: 16, maxN: 10),
        ImageModel(id: "openai/gpt-5-image",
                   name: "GPT-5 Image",
                   resolutions: [],
                   aspectRatios: [],
                   qualities: ["auto", "low", "medium", "high"], maxReferences: 16, maxN: 10),
        ImageModel(id: "openai/gpt-5.4-image-2",
                   name: "GPT-5.4 Image 2",
                   resolutions: [],
                   aspectRatios: [],
                   qualities: ["auto", "low", "medium", "high"], maxReferences: 16, maxN: 10),
        ImageModel(id: "black-forest-labs/flux.2-pro",
                   name: "FLUX.2 Pro",
                   resolutions: [],
                   aspectRatios: ["1:1", "4:3", "3:4", "3:2", "2:3", "16:9", "9:16", "21:9", "auto"],
                   qualities: [], maxReferences: 8, maxN: 1),
        ImageModel(id: "bytedance-seed/seedream-4.5",
                   name: "Seedream 4.5",
                   resolutions: ["1K", "2K", "4K"],
                   aspectRatios: ["1:1", "1:2", "2:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9", "auto"],
                   qualities: [], maxReferences: 14, maxN: 10),
        ImageModel(id: "x-ai/grok-imagine-image-2.0",
                   name: "Grok Imagine 2.0",
                   resolutions: ["1K", "2K"],
                   aspectRatios: ["1:1", "3:4", "4:3", "9:16", "16:9", "2:3", "3:2", "1:2", "2:1", "auto"],
                   qualities: ["low", "medium"], maxReferences: 3, maxN: 1),
        ImageModel(id: "qwen/qwen-image-3",
                   name: "Qwen Image 3",
                   resolutions: ["1K", "2K"],
                   aspectRatios: ["1:1", "1:2", "1:4", "2:1", "2:3", "3:2", "3:4", "4:1", "4:3", "4:5", "5:4", "9:16", "16:9"],
                   qualities: [], maxReferences: 4, maxN: 6),
        ImageModel(id: "recraft/recraft-v4",
                   name: "Recraft V4",
                   resolutions: [],
                   aspectRatios: ["1:1", "4:3", "3:4", "16:9", "9:16", "auto"],
                   qualities: [], maxReferences: 1, maxN: 6),
        ImageModel(id: "sourceful/riverflow-v2.5-pro",
                   name: "Riverflow V2.5 Pro",
                   resolutions: ["1K", "2K", "4K"],
                   aspectRatios: ["1:1", "4:3", "3:4", "3:2", "2:3", "16:9", "9:16", "21:9", "auto"],
                   qualities: [], maxReferences: 10, maxN: 1),
        ImageModel(id: "microsoft/mai-image-2.5-pro",
                   name: "MAI Image 2.5 Pro",
                   resolutions: [],
                   aspectRatios: ["1:1", "4:3", "3:4", "16:9", "9:16", "3:2", "2:3", "auto"],
                   qualities: [], maxReferences: 1, maxN: 1),
        ImageModel(id: "krea/krea-2-large",
                   name: "Krea 2 Large",
                   resolutions: ["1K"],
                   aspectRatios: ["1:1", "4:3", "3:2", "16:9", "4:5", "2:3", "9:16"],
                   qualities: [], maxReferences: 1, maxN: 1)
    ]

    var key: String {
        ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? ""
    }

    func generate(
        prompt: String,
        images: [Data],
        model: ImageModel,
        resolution: String?,
        aspectRatio: String?,
        quality: String?,
        n: Int,
        apiKeyOverride: String?
    ) async throws -> [GeneratedImage] {
        let key = apiKeyOverride?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? apiKeyOverride!
            : self.key
        guard !key.isEmpty else { throw OpenRouterError.missingKey }
        guard images.count <= model.maxReferences else {
            throw OpenRouterError.tooManyReferences(model.maxReferences)
        }

        let references = images.isEmpty ? nil : images.map {
            ImageRequest.InputReference(
                type: "image_url",
                imageUrl: ImageRequest.ImageURL(url: "data:image/png;base64," + $0.base64EncodedString())
            )
        }

        let request = ImageRequest(
            model: model.id,
            prompt: prompt,
            n: n,
            resolution: resolution,
            aspectRatio: aspectRatio,
            quality: quality,
            inputReferences: references
        )

        var urlRequest = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/images")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw OpenRouterError.badResponse }
        let decoded = try JSONDecoder().decode(ImageResponse.self, from: data)
        if http.statusCode != 200 {
            throw OpenRouterError.api(decoded.error?.message ?? "HTTP \(http.statusCode)")
        }
        guard !decoded.data.isEmpty else { throw OpenRouterError.badResponse }

        return try decoded.data.map { image in
            guard let imageData = Data(base64Encoded: image.b64Json) else {
                throw OpenRouterError.badResponse
            }
            return GeneratedImage(data: imageData, mediaType: image.mediaType)
        }
    }
}
