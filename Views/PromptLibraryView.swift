import SwiftUI

struct PromptLibraryView: View {
    @EnvironmentObject private var dataStore: DataStore
    let favoritesOnly: Bool
    @State private var searchText = ""
    @State private var selectedTags: Set<String> = []
    @State private var selectedKind: PromptKind?
    @State private var selectedPrompt: Prompt?
    @State private var tagsExpanded = true

    private var filter: PromptLibraryFilter {
        PromptLibraryFilter(kind: selectedKind, selectedTags: selectedTags, query: searchText, favoritesOnly: favoritesOnly)
    }

    private var results: [Prompt] { filter.apply(to: dataStore.prompts) }
    private var facetPrompts: [Prompt] {
        PromptLibraryFilter(kind: selectedKind, query: searchText, favoritesOnly: favoritesOnly).apply(to: dataStore.prompts)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppSearchField(placeholder: favoritesOnly ? "搜索收藏的笔记或模板" : "搜索笔记、模板或标签", text: $searchText)
                    .padding(.horizontal, AppSpacing.page)
                    .padding(.top, 8)

                Picker("内容分类", selection: $selectedKind) {
                    Text("全部").tag(PromptKind?.none)
                    Text("笔记").tag(PromptKind?.some(.note))
                    Text("模板").tag(PromptKind?.some(.template))
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.page)
                .padding(.vertical, 16)
                .accessibilityIdentifier("prompt.filter")

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: AppSpacing.gap) {
                        tagFilters

                        if let message = dataStore.importErrorMessage ?? dataStore.errorMessage {
                            Text(message).font(AppTypography.secondary).foregroundColor(.red)
                        }

                        if dataStore.isLoading {
                            ProgressView().tint(.accent).frame(maxWidth: .infinity)
                        } else if results.isEmpty {
                            AppEmptyState(symbol: favoritesOnly ? "star" : "line.3.horizontal.decrease.circle",
                                          title: emptyTitle, message: "试试其他关键词、标签或内容分类。")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.section)
                        } else {
                            if selectedKind != .template { promptSection(.note, title: "笔记", identifier: "notes") }
                            if selectedKind != .note { promptSection(.template, title: "模板", identifier: "templates") }
                        }
                    }
                    .padding(.horizontal, AppSpacing.page)
                    .padding(.bottom, AppSpacing.section)
                }
                .accessibilityIdentifier("library.scroll")
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.surface1.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if favoritesOnly {
                        Text("个人收藏").font(AppTypography.title).foregroundColor(.textPrimary)
                    } else {
                        AppWordmark()
                    }
                }
            }
            .sheet(item: $selectedPrompt) { prompt in
                PromptDetailView(prompt: prompt)
            }
            .onChange(of: dataStore.tags) { tags in
                selectedTags.formIntersection(tags.map(\.name))
            }
        }
    }

    private var emptyTitle: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedTags.isEmpty {
            return favoritesOnly ? "没有匹配的收藏" : "没有匹配的内容"
        }
        return favoritesOnly ? "暂无收藏的笔记或模板" : "暂无\(selectedKind?.title ?? "笔记或模板")"
    }

    private var tagFilters: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Button {
                    tagsExpanded.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Text("标签").font(AppTypography.section)
                        Text("\(dataStore.tags.count)").font(AppTypography.caption).foregroundColor(.textSecondary)
                        Image(systemName: tagsExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold)).foregroundColor(.textSecondary)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.textPrimary)
                .accessibilityIdentifier("library.tags.toggle")
                .accessibilityLabel("全部标签")
                .accessibilityValue(tagsExpanded ? "已展开" : "已收起")
                .accessibilityHint("展开或收起标签筛选")

                Spacer(minLength: 8)
                Text("\(results.count) 条内容")
                    .font(AppTypography.caption)
                    .foregroundColor(.textSecondary)
                    .accessibilityIdentifier("library.results.count")
                if !selectedTags.isEmpty {
                    Button("清除筛选") { selectedTags.removeAll() }
                        .font(AppTypography.secondary)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("library.tags.clear")
                }
            }
            if tagsExpanded {
                TagFlowLayout(spacing: 8) {
                    ForEach(dataStore.tags) { tag in
                        tagButton(tag)
                    }
                }
                if dataStore.tags.isEmpty {
                    Text("在编辑器或设置中添加标签。")
                        .font(AppTypography.secondary).foregroundColor(.textSecondary)
                }
            }
            if !selectedTags.isEmpty {
                Text("已选 \(selectedTags.count) 个标签 · 匹配任一标签")
                    .font(AppTypography.caption).foregroundColor(.textSecondary)
            }
        }
    }

    private func tagButton(_ tag: Tag) -> some View {
        let selected = selectedTags.contains(tag.name)
        let count = facetPrompts.filter { $0.tags.contains(tag.name) }.count
        return Button {
            if selected { selectedTags.remove(tag.name) } else { selectedTags.insert(tag.name) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selected ? "checkmark.square.fill" : "square")
                    .foregroundColor(selected ? .accent : .textSecondary)
                    .accessibilityHidden(true)
                Text(tag.name).fixedSize(horizontal: false, vertical: true)
                Text("\(count)").monospacedDigit().foregroundColor(.textSecondary)
            }
            .font(AppTypography.secondary)
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(selected ? Color.accent.opacity(0.14) : Color.surface3,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(selected ? Color.accent : Color.outline))
        }
        .buttonStyle(LibraryTagButtonStyle())
        .accessibilityIdentifier("library.tag.\(tag.name)")
        .accessibilityLabel(tag.name)
        .accessibilityValue("\(count) 条内容")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func promptSection(_ kind: PromptKind, title: String, identifier: String) -> some View {
        let prompts = results.filter { $0.kind == kind }
        return Section {
            if prompts.isEmpty {
                Text("暂无匹配的\(title)")
                    .font(AppTypography.secondary).foregroundColor(.textSecondary)
            } else {
                ForEach(prompts) { prompt in
                    PromptCardView(prompt: prompt) { selectedPrompt = prompt }
                        .accessibilityIdentifier("prompt.row.\(prompt.id)")
                }
            }
        } header: {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(AppTypography.section).foregroundColor(.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(prompts.count) 条").font(AppTypography.caption).foregroundColor(.textSecondary)
                    .accessibilityIdentifier("library.\(identifier).count")
            }
        }
    }
}

private struct LibraryTagButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct TagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        positions(width: proposal.width ?? 320, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = positions(width: bounds.width, subviews: subviews)
        for (index, view) in subviews.enumerated() {
            let item = layout.items[index]
            view.place(at: CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y),
                       proposal: ProposedViewSize(item.size))
        }
    }

    private func positions(width: CGFloat, subviews: Subviews) -> (items: [CGRect], size: CGSize) {
        let width = max(width, 1)
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var items: [CGRect] = []
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: width, height: nil))
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            items.append(CGRect(x: x, y: y, width: min(size.width, width), height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (items, CGSize(width: width, height: y + rowHeight))
    }
}
