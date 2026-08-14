import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: [ContentPart]
}

struct ContentPart: Codable {
    let type: String
    var text: String?
    var image_url: ImageURL?

    init(text: String) {
        type = "text"
        self.text = text
    }

    init(imageDataURI: String) {
        type = "image_url"
        image_url = ImageURL(url: imageDataURI)
    }
}

struct ImageURL: Codable {
    let url: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let modalities: [String]
}

struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: MessageContent?
            let images: [GeneratedImage]?
        }
        let message: Message
    }
    struct GeneratedImage: Decodable {
        let image_url: ImageURL
    }
    let choices: [Choice]
    let error: APIError?

    struct APIError: Decodable {
        let message: String
    }
}

enum MessageContent: Decodable {
    case string(String)
    case parts([ContentPart])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            let parts = try container.decode([ContentPart].self)
            self = .parts(parts)
        }
    }
}

enum OpenRouterError: LocalizedError {
    case missingKey
    case badResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .missingKey: "OPENROUTER_API_KEY is not set in the environment and no key was entered."
        case .badResponse: "Received an unexpected response from OpenRouter."
        case .api(let msg): "OpenRouter API error: \(msg)"
        }
    }
}

struct OpenRouterService {
    static let defaultModel = "google/gemini-2.5-flash-image"
    static let availableModels = [
        "google/gemini-2.5-flash-image",
        "google/gemini-3-pro-image",
        "google/gemini-3-pro-image-preview",
        "google/gemini-3.1-flash-image",
        "google/gemini-3.1-flash-lite-image",
        "google/gemini-3.1-flash-image-preview"
    ]

    var key: String {
        ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? ""
    }

    func generate(prompt: String, images: [Data], model: String, apiKeyOverride: String?) async throws -> Data {
        let key = apiKeyOverride?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? apiKeyOverride!
            : self.key
        guard !key.isEmpty else { throw OpenRouterError.missingKey }

        var parts = images.map { ContentPart(imageDataURI: "data:image/png;base64," + $0.base64EncodedString()) }
        parts.append(ContentPart(text: prompt))

        let request = ChatRequest(
            model: model,
            messages: [ChatMessage(role: "user", content: parts)],
            modalities: ["image", "text"]
        )

        var urlRequest = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw OpenRouterError.badResponse }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        if http.statusCode != 200 {
            throw OpenRouterError.api(decoded.error?.message ?? "HTTP \(http.statusCode)")
        }
        guard let message = decoded.choices.first?.message else { throw OpenRouterError.badResponse }

        var dataURIs: [String] = []
        if let images = message.images {
            dataURIs += images.map(\.image_url.url)
        }
        if case .parts(let parts) = message.content {
            dataURIs += parts.compactMap { $0.image_url?.url }
        }
        guard let first = dataURIs.first,
              let comma = first.range(of: ","),
              let imageData = Data(base64Encoded: String(first[first.index(after: comma.lowerBound)...]))
        else { throw OpenRouterError.badResponse }

        return imageData
    }
}
