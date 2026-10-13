import Foundation
import SwiftUI

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var prompts: [Prompt] = []
    @Published var tags: [Tag] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    private init() {}

    // MARK: - Prompts

    func loadPrompts(filters: [String: String]? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            prompts = try await apiService.fetchPrompts(filters: filters)
        } catch {
            errorMessage = "加载模板失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func createPrompt(_ input: CreatePromptInput) async -> Bool {
        do {
            let newPrompt = try await apiService.createPrompt(input)
            prompts.insert(newPrompt, at: 0)
            return true
        } catch {
            errorMessage = "创建模板失败: \(error.localizedDescription)"
            return false
        }
    }

    func updatePrompt(id: Int, input: CreatePromptInput) async -> Bool {
        do {
            let updatedPrompt = try await apiService.updatePrompt(id: id, input: input)
            if let index = prompts.firstIndex(where: { $0.id == id }) {
                prompts[index] = updatedPrompt
            }
            return true
        } catch {
            errorMessage = "更新模板失败: \(error.localizedDescription)"
            return false
        }
    }

    func deletePrompt(id: Int) async -> Bool {
        do {
            try await apiService.deletePrompt(id: id)
            prompts.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = "删除模板失败: \(error.localizedDescription)"
            return false
        }
    }

    func toggleFavorite(prompt: Prompt) async {
        do {
            let updatedPrompt = try await apiService.toggleFavorite(id: prompt.id, isFavorite: !prompt.isFavorite)
            if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
                prompts[index] = updatedPrompt
            }
        } catch {
            errorMessage = "更新收藏状态失败: \(error.localizedDescription)"
        }
    }

    // MARK: - Tags

    func loadTags() async {
        do {
            tags = try await apiService.fetchTags()
        } catch {
            errorMessage = "加载标签失败: \(error.localizedDescription)"
        }
    }

    func createTag(_ input: CreateTagInput) async -> Bool {
        do {
            let newTag = try await apiService.createTag(input)
            tags.append(newTag)
            return true
        } catch {
            errorMessage = "创建标签失败: \(error.localizedDescription)"
            return false
        }
    }

    func deleteTag(id: Int) async -> Bool {
        do {
            try await apiService.deleteTag(id: id)
            tags.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = "删除标签失败: \(error.localizedDescription)"
            return false
        }
    }
}
