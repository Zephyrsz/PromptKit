import SwiftUI

struct TemplateListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var showingMenu = false
    @State private var selectedPrompt: Prompt?

    var filteredPrompts: [Prompt] {
        if searchText.isEmpty {
            return dataStore.prompts
        } else {
            return dataStore.prompts.filter { prompt in
                prompt.title.localizedCaseInsensitiveContains(searchText) ||
                prompt.description?.localizedCaseInsensitiveContains(searchText) ?? false ||
                prompt.promptText.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.surface1.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textTertiary)

                        TextField("搜索模板...", text: $searchText)
                            .foregroundColor(.textPrimary)
                    }
                    .padding()
                    .background(Color.surface3)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Prompts list
                    if dataStore.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.accent)
                        Spacer()
                    } else if filteredPrompts.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundColor(.textTertiary)
                            Text("暂无模板")
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredPrompts) { prompt in
                                    PromptCardView(prompt: prompt)
                                        .onTapGesture {
                                            selectedPrompt = prompt
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }

                // Add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingMenu = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.surface4)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("PromptKit")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await dataStore.loadPrompts()
                    await dataStore.loadTags()
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                EditPromptView(prompt: nil)
            }
            .sheet(item: $selectedPrompt) { prompt in
                PromptDetailView(prompt: prompt)
            }
            .confirmationDialog("", isPresented: $showingMenu, titleVisibility: .hidden) {
                Button("创建") {
                    showingCreateSheet = true
                }
                Button("导入") {
                    // TODO: Import functionality
                }
                Button("选择") {
                    // TODO: Select mode
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
}

struct PromptCardView: View {
    let prompt: Prompt
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "message")
                    .font(.title3)
                    .foregroundColor(.accent)
                    .frame(width: 40, height: 40)
                    .background(Color.accent.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    if let description = prompt.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button {
                    Task {
                        await dataStore.toggleFavorite(prompt: prompt)
                    }
                } label: {
                    Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                        .foregroundColor(prompt.isFavorite ? .yellow : .textTertiary)
                }
            }

            // Tags
            if !prompt.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Image(systemName: "equal")
                            .font(.caption)
                            .foregroundColor(.textTertiary)

                        ForEach(prompt.tags, id: \.self) { tagName in
                            if let tag = dataStore.tags.first(where: { $0.name == tagName }) {
                                Text(tag.name)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(tag.swiftUIColor.opacity(0.3))
                                    .cornerRadius(4)
                            }
                        }

                        Text("昨天")
                            .font(.caption)
                            .foregroundColor(.textTertiary)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.surface3)
        .cornerRadius(12)
    }
}
