import SwiftUI

struct QuickAccessView: View {
    var body: some View {
        PromptLibraryView(favoritesOnly: true)
    }
}

struct QuickUsePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: DataStore
    let prompt: Prompt

    private var currentPrompt: Prompt { dataStore.prompts.first { $0.id == prompt.id } ?? prompt }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.section) {
                        Text(currentPrompt.title).font(AppTypography.title).foregroundColor(.textPrimary)
                        PromptUsageView(prompt: currentPrompt)
                    }
                    .padding(AppSpacing.page)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("快速使用")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    AppCloseButton(label: "关闭快速使用") { dismiss() }
                }
            }
            .appScreen()
        }
    }
}
