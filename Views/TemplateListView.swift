import SwiftUI

struct TemplateListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var showingMenu = false
    @State private var selectedPrompt: Prompt?
    @State private var selectedKind: PromptKind?
    @State private var createKind: PromptKind = .note

    var filteredPrompts: [Prompt] {
        dataStore.prompts.filter { prompt in
            (selectedKind == nil || prompt.kind == selectedKind) &&
            (searchText.isEmpty || prompt.title.localizedCaseInsensitiveContains(searchText) ||
             (prompt.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
             prompt.promptText.localizedCaseInsensitiveContains(searchText) ||
             prompt.tags.contains { $0.localizedCaseInsensitiveContains(searchText) })
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

                        TextField("搜索笔记、模板或标签", text: $searchText)
                            .foregroundColor(.textPrimary)
                    }
                    .padding()
                    .background(Color.surface3)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Picker("内容分类", selection: $selectedKind) {
                        Text("全部").tag(PromptKind?.none)
                        Text("笔记").tag(PromptKind?.some(.note))
                        Text("模板").tag(PromptKind?.some(.template))
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .accessibilityIdentifier("prompt.filter")

                    if let message = dataStore.errorMessage {
                        Text(message)
                            .font(.callout)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

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
                            Text(searchText.isEmpty ? "暂无\(selectedKind?.title ?? "笔记或模板")" : "没有匹配的内容")
                                .foregroundColor(.textSecondary)
                            Button("新建\(selectedKind?.title ?? "提示词笔记")") {
                                createKind = selectedKind ?? .note
                                showingCreateSheet = true
                            }
                            .foregroundColor(.accent)
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
                        .accessibilityIdentifier("prompt.add")
                        .accessibilityLabel("新建提示词")
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
                EditPromptView(prompt: nil, initialKind: createKind)
            }
            .sheet(item: $selectedPrompt) { prompt in
                PromptDetailView(prompt: prompt)
            }
            .confirmationDialog("", isPresented: $showingMenu, titleVisibility: .hidden) {
                Button("新建提示词笔记") {
                    createKind = .note
                    showingCreateSheet = true
                }
                .accessibilityIdentifier("prompt.create.note")
                Button("新建模板") {
                    createKind = .template
                    showingCreateSheet = true
                }
                .accessibilityIdentifier("prompt.create.template")
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
                Image(systemName: prompt.kind.icon)
                    .font(.title3)
                    .foregroundColor(.accent)
                    .frame(width: 40, height: 40)
                    .background(Color.accent.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text(prompt.kind.title)
                        .font(.caption)
                        .foregroundColor(.textSecondary)

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

                        Text(prompt.updatedAt, style: .date)
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
