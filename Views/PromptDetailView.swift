import SwiftUI

struct PromptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: DataStore
    private let initialPrompt: Prompt
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var actionError: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                            TagFlowLayout(spacing: AppSpacing.small) {
                                ForEach(prompt.tags, id: \.self) { name in
                                    AppTagChip(name: name, color: dataStore.tags.first { $0.name == name }?.swiftUIColor ?? .accent)
                                }
                            }
                            .foregroundColor(.textPrimary)
                        }

                        PromptUsageView(prompt: prompt)

                        if let notes = prompt.usageNotes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                AppSectionHeader(title: "使用说明")
                                Text(notes).foregroundColor(.textSecondary)
                                    .font(AppTypography.body)
                                    .lineSpacing(5)
                            }
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appCard()
                        }

                        (dynamicTypeSize.isAccessibilitySize
                         ? AnyLayout(VStackLayout(spacing: AppSpacing.gap))
                         : AnyLayout(HStackLayout(spacing: AppSpacing.gap))) {
                            Button { showingEditSheet = true } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .accessibilityIdentifier("prompt.edit")
                            .buttonStyle(AppSecondaryButtonStyle())
                            Button(role: .destructive) { showingDeleteAlert = true } label: {
                                Label("删除", systemImage: "trash")
                            }
                            .accessibilityIdentifier("prompt.delete")
                            .buttonStyle(AppSecondaryButtonStyle(isDestructive: true))
                        }

                        if let actionError = actionError {
                            AppStatusMessage(message: actionError)
                        }
                    }
                    .padding(AppSpacing.page)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(prompt.kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    AppCloseButton(label: "关闭详情", identifier: "prompt.close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await dataStore.toggleFavorite(prompt: prompt)
                            actionError = dataStore.errorMessage
                        }
                    } label: {
                        Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(prompt.isFavorite ? .accent : .textSecondary)
                            .frame(minWidth: AppMetrics.touchTarget, minHeight: AppMetrics.touchTarget)
                    }
                    .accessibilityIdentifier("prompt.favorite")
                    .accessibilityLabel(prompt.isFavorite ? "取消收藏" : "收藏")
                    .accessibilityValue(prompt.isFavorite ? "已收藏" : "未收藏")
                }
            }
            .appScreen()
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
                    AppSectionHeader(title: "填写填空项", detail: "填齐后即可生成并复制，结果会实时更新。")
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
                AppSectionHeader(title: prompt.isTemplate ? "生成结果" : "提示词内容")
                Text(prompt.rendered(with: values))
                    .accessibilityIdentifier("prompt.result")
                    .textSelection(.enabled)
                    .foregroundColor(.textPrimary)
                    .font(AppTypography.body)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !missing.isEmpty {
                    AppStatusMessage(message: "待填写：\(missing.joined(separator: "、"))", isError: false)
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
