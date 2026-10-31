import Foundation
import SwiftUI

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore(importURL: Bundle.main.url(forResource: "WebPrompts", withExtension: "sqlite"))

    @Published private(set) var prompts: [Prompt] = []
    @Published private(set) var tags: [Tag] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var importErrorMessage: String?

    private var database: SQLiteStore?

    init(databaseURL: URL = SQLiteStore.defaultURL, importURL: URL? = nil) {
        do {
            database = try SQLiteStore(url: databaseURL)
            try reload()
            if let importURL {
                do {
                    try database?.importWebSnapshot(from: importURL)
                    try reload()
                } catch {
                    importErrorMessage = "Web 数据导入失败：\(error.localizedDescription)；原有本地数据已保留。"
                }
            }
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
        guard let currenft = prompts.first(where: { $0.id == prompt.id }) else { return }
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
