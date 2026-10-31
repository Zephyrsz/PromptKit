import SwiftUI

struct PromptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: DataStore
    private let initialPrompt: Prompt
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var actionError: String?

    init(prompt: Prompt) { initialPrompt = prompt }

    private var prompt: Prompt {
        dataStore.prompts.first { $0.id == initialPrompt.id } ?? initialPrompt
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.section) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(prompt.title, systemImage: prompt.kind.icon)
                                .font(AppTypography.title)
                                .foregroundColor(.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(prompt.kind.title)
                                .font(AppTypography.caption)
                                .foregroundColor(.textSecondary)
                            if let description = prompt.description, !description.isEmpty {
                                Text(description).font(AppTypography.secondary).foregroundColor(.textSecondary)
                                    .lineSpacing(4)
                            }
                        }

                        if !prompt.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(prompt.tags, id: \.self) { name in
                                        AppTagChip(name: name, color: dataStore.tags.first { $0.name == name }?.swiftUIColor ?? .accent)
                                    }
                                }
                            }
                            .foregroundColor(.textPrimary)
                        }

                        PromptUsageView(prompt: prompt)

                        if let notes = prompt.usageNotes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("使用说明").font(AppTypography.section)
                                Text(notes).foregroundColor(.textSecondary)
                                    .font(AppTypography.body)
                                    .lineSpacing(5)
                            }
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appCard()
                        }

                        HStack(spacing: 20) {
                            Button { showingEditSheet = true } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .accessibilityIdentifier("prompt.edit")
                            .buttonStyle(.bordered)
                            Spacer()
                            Button(role: .destructive) { showingDeleteAlert = true } label: {
                                Label("删除", systemImage: "trash")
                            }
                            .accessibilityIdentifier("prompt.delete")
                            .buttonStyle(.bordered)
                        }
                        .controlSize(.large)

                        if let actionError = actionError {
                            Text(actionError).font(.callout).foregroundColor(.red)
                        }
                    }
                    .padding(AppSpacing.page)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(prompt.kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityIdentifier("prompt.close")
                        .accessibilityLabel("关闭详情")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await dataStore.toggleFavorite(prompt: prompt)
                            actionError = dataStore.errorMessage
                        }
                    } label: {
                        Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                            .foregroundColor(prompt.isFavorite ? .accent : .textSecondary)
                    }
                    .accessibilityIdentifier("prompt.favorite")
                    .accessibilityLabel(prompt.isFavorite ? "取消收藏" : "收藏")
                }
            }
            .sheet(isPresented: $showingEditSheet) { EditPromptView(prompt: prompt) }
            .alert("删除\(prompt.kind.title)", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    Task {
                        if await dataStore.deletePrompt(id: prompt.id) { dismiss() }
                        else { actionError = dataStore.errorMessage }
                    }
                }
            } message: { Text("确定要删除「\(prompt.title)」吗？此操作无法撤销。") }
        }
    }
}

// Details and quick access use the same rendering and completion rules.
struct PromptUsageView: View {
    let prompt: Prompt
    @State private var values: [String: String] = [:]
    @State private var showingCopiedAlert = false

    private var missing: [String] { prompt.missingVariables(in: values) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            if !prompt.variableNames.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("填写变量").font(AppTypography.section).foregroundColor(.textPrimary)
                    ForEach(prompt.variableNames, id: \.self) { name in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(name).font(AppTypography.secondary.weight(.medium)).foregroundColor(.textSecondary)
                            TextField("输入 \(name)", text: Binding(
                                get: { values[name] ?? "" }, set: { values[name] = $0 }
                            ), axis: .vertical)
                            .accessibilityIdentifier("variable.\(name)")
                            .accessibilityLabel(name)
                            .appInput()
                        }
                    }
                }
                .appCard()
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(prompt.isTemplate ? "生成结果" : "提示词内容")
                    .font(AppTypography.section)
                    .foregroundColor(.textPrimary)
                Text(prompt.rendered(with: values))
                    .accessibilityIdentifier("prompt.result")
                    .textSelection(.enabled)
                    .foregroundColor(.textPrimary)
                    .font(AppTypography.body)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !missing.isEmpty {
                    Text("待填写：\(missing.joined(separator: "、"))")
                        .font(AppTypography.caption)
                        .foregroundColor(.textSecondary)
                }

                Button {
                    UIPasteboard.general.string = prompt.rendered(with: values)
                    showingCopiedAlert = true
                } label: {
                    Label(prompt.isTemplate ? "生成并复制" : "复制笔记", systemImage: "doc.on.doc")
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .accessibilityIdentifier("prompt.copy")
                .disabled(!missing.isEmpty)
            }
            .appCard()
        }
        .onChange(of: prompt.promptText) { _ in values = [:] }
        .onChange(of: prompt.isTemplate) { _ in values = [:] }
        .alert("已复制", isPresented: $showingCopiedAlert) {
            Button("好的", role: .cancel) {}
        } message: { Text("内容已复制到剪贴板") }
    }
}
