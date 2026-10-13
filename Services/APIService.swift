import Foundation

class APIService {
    static let shared = APIService()

    // 修改为你的服务器地址
    private let baseURL = "http://127.0.0.1:3001/api"

    private init() {}

    // MARK: - Prompts

    func fetchPrompts(filters: [String: String]? = nil) async throws -> [Prompt] {
        var urlComponents = URLComponents(string: "\(baseURL)/prompts")!

        if let filters = filters {
            urlComponents.queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let prompts = try JSONDecoder().decode([Prompt].self, from: data)
        return prompts
    }

    func fetchPrompt(id: Int) async throws -> Prompt {
        guard let url = URL(string: "\(baseURL)/prompts/\(id)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let prompt = try JSONDecoder().decode(Prompt.self, from: data)
        return prompt
    }

    func createPrompt(_ input: CreatePromptInput) async throws -> Prompt {
        guard let url = URL(string: "\(baseURL)/prompts") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(input)

        let (data, _) = try await URLSession.shared.data(for: request)
        let prompt = try JSONDecoder().decode(Prompt.self, from: data)
        return prompt
    }

    func updatePrompt(id: Int, input: CreatePromptInput) async throws -> Prompt {
        guard let url = URL(string: "\(baseURL)/prompts/\(id)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(input)

        let (data, _) = try await URLSession.shared.data(for: request)
        let prompt = try JSONDecoder().decode(Prompt.self, from: data)
        return prompt
    }

    func deletePrompt(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/prompts/\(id)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        _ = try await URLSession.shared.data(for: request)
    }

    func toggleFavorite(id: Int, isFavorite: Bool) async throws -> Prompt {
        guard let url = URL(string: "\(baseURL)/prompts") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["id": id, "isFavorite": isFavorite]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let prompt = try JSONDecoder().decode(Prompt.self, from: data)
        return prompt
    }

    // MARK: - Tags

    func fetchTags() async throws -> [Tag] {
        guard let url = URL(string: "\(baseURL)/tags") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let tags = try JSONDecoder().decode([Tag].self, from: data)
        return tags
    }

    func createTag(_ input: CreateTagInput) async throws -> Tag {
        guard let url = URL(string: "\(baseURL)/tags") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(input)

        let (data, _) = try await URLSession.shared.data(for: request)
        let tag = try JSONDecoder().decode(Tag.self, from: data)
        return tag
    }

    func deleteTag(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/tags/\(id)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        _ = try await URLSession.shared.data(for: request)
    }
}
