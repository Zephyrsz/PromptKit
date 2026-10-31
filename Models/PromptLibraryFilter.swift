import Foundation

struct PromptLibraryFilter {
    var kind: PromptKind? = nil
    var selectedTags: Set<String> = []
    var query = ""
    var favoritesOnly = false

    func apply(to prompts: [Prompt]) -> [Prompt] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return prompts.filter { prompt in
            (!favoritesOnly || prompt.isFavorite) &&
            (kind == nil || prompt.kind == kind) &&
            (selectedTags.isEmpty || !selectedTags.isDisjoint(with: prompt.tags)) &&
            (term.isEmpty || [prompt.title, prompt.description ?? "", prompt.promptText, prompt.usageNotes ?? ""]
                .contains { $0.localizedCaseInsensitiveContains(term) } ||
             prompt.tags.contains { $0.localizedCaseInsensitiveContains(term) })
        }
    }
}
