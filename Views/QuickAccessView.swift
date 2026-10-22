import SwiftUI

struct QuickAccessView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var searchText = ""
    @State private var selectedPrompt: Prompt?

    private var filteredPrompts: [Prompt] {
        dataStore.prompts.filter {
            $0.isFavorite && (searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) ||
                             $0.promptText.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.surface1.ignoresSafeArea()
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.textSecondary)
                        TextField("搜索收藏的笔记或模板", text: $searchText)
                            .foregroundColor(.textPrimary)
                    }
                    .padding()
                    .background(Color.surface3)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    if filteredPrompts.isEmpty {
                        Spacer()
                        Image(systemName: "star").font(.largeTitle).foregroundColor(.textSecondary)
                        Text(searchText.isEmpty ? "暂无收藏的笔记或模板" : "没有匹配的收藏")
                            .foregroundColor(.textSecondary)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredPrompts) { prompt in
                                    Button { selectedPrompt = prompt } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: prompt.kind.icon)
                                                .foregroundColor(.accent)
                                                .font(.title2)
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(prompt.title).font(.headline).foregroundColor(.textPrimary)
                                                Text(prompt.kind.title).font(.caption).foregroundColor(.textSecondary)
                                                Text(prompt.promptText).font(.subheadline).foregroundColor(.textSecondary).lineLimit(2)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right").foregroundColor(.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(Color.surface3)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("快捷贴贴")
            .sheet(item: $selectedPrompt) { QuickUsePromptView(prompt: $0) }
        }
    }
}

struct QuickUsePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: DataStore
    let prompt: Prompt

    private var currentPrompt: Prompt { dataStore.prompts.first { $0.id == prompt.id } ?? prompt }

    var body: some View {
        NavigationView {
            ZStack {
                Color.surface1.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(currentPrompt.title).font(.title2.bold()).foregroundColor(.textPrimary)
                        PromptUsageView(prompt: currentPrompt)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("快速使用")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("关闭快速使用")
                }
            }
        }
    }
}
