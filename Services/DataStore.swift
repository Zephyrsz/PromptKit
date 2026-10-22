import Foundation
import SwiftUI

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published private(set) var prompts: [Prompt] = []
    @Published private(set) var tags: [Tag] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var database: SQLiteStore?

    init(databaseURL: URL = SQLiteStore.defaultURL) {
        do {
            database = try SQLiteStore(url: databaseURL)
            try reload()
        } catch {
            errorMessage = "无法打开本地资料库：\(error.localizedDescription)"
        }
    }

    // MARK: - Prompts

    func loadPrompts() async {
        isLoading = true
        defer { isLoading = false }
        _ = perform { _ in }
    }

    func createPrompt(_ input: CreatePromptInput) async -> Bool {
        perform { try $0.savePrompt(input) }
    }

    func updatePrompt(id: Int, input: CreatePromptInput) async -> Bool {
        perform { try $0.savePrompt(input, id: id) }
    }

    func deletePrompt(id: Int) async -> Bool {
        perform { try $0.deletePrompt(id: id) }
    }

    func toggleFavorite(prompt: Prompt) async {
        guard let current = prompts.first(where: { $0.id == prompt.id }) else { return }
        _ = perform { try $0.setFavorite(id: current.id, isFavorite: !current.isFavorite) }
    }

    // MARK: - Tags

    func loadTags() async {
        _ = perform { _ in }
    }

    func createTag(_ input: CreateTagInput) async -> Bool {
        perform { try $0.createTag(input) }
    }

    func deleteTag(id: Int) async -> Bool {
        perform { try $0.deleteTag(id: id) }
    }

    private func reload() throws {
        guard let database = database else { throw StorageError.message("本地资料库未能打开，请重新启动 App 后重试。") }
        let savedPrompts = try database.loadPrompts()
        let savedTags = try database.loadTags()
        prompts = savedPrompts
        tags = savedTags
    }

    private func perform(_ operation: (SQLiteStore) throws -> Void) -> Bool {
        do {
            guard let database = database else { throw StorageError.message("本地资料库未能打开，请重新启动 App 后重试。") }
            try operation(database)
            try reload()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
