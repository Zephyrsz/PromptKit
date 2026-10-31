import SwiftUI

struct EditPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: DataStore

    let prompt: Prompt?
    @State private var kind: PromptKind
    @State private var title: String
    @State private var promptText: String
    @State private var selectedTags: Set<String>
    @State private var showingTagPicker = false
    @State private var showingVariableSheet = false
    @State private var showingTemplateList = false
    @State private var isSaving = false
    @State private var saveError: String?

    init(prompt: Prompt?, initialKind: PromptKind = .note) {
        self.prompt = prompt
        _kind = State(initialValue: prompt?.kind ?? initialKind)
        _title = State(initialValue: prompt?.title ?? "")
        _promptText = State(initialValue: prompt?.promptText ?? "")
        _selectedTags = State(initialValue: Set(prompt?.tags ?? []))
    }

    private var variables: [String] { TemplateText.variables(in: promptText) }
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (kind == .note || !variables.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.section) {
                        Picker("内容类型", selection: $kind) {
                            ForEach(PromptKind.allCases) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("prompt.kind")

                        VStack(alignment: .leading, spacing: 10) {
                            Text("标题")
                                .font(AppTypography.section)
                                .foregroundColor(.textPrimary)
                            TextField(kind == .note ? "为笔记起个名字" : "为模板起个名字", text: $title)
                                .accessibilityIdentifier("prompt.title")
                                .accessibilityLabel("标题")
                                .appInput()
                        }
                        .appCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Text(kind == .note ? "提示词内容" : "模板内容")
                                .font(AppTypography.section)
                                .foregroundColor(.textPrimary)

                            TextEditor(text: $promptText)
                                .accessibilityIdentifier("prompt.body")
                                .accessibilityLabel(kind == .note ? "提示词内容" : "模板内容")
                                .font(AppTypography.body)
                                .lineSpacing(5)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(.textPrimary)
                                .frame(minHeight: 220)
                                .padding(8)
                                .background(Color.surface2)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.outline))

                            if kind == .template {
                                Button {
                                    showingVariableSheet = true
                                } label: {
                                    Label("插入填空项", systemImage: "plus.circle")
                                }
                                .accessibilityIdentifier("variable.add")
                                .foregroundColor(.accent)
                                .frame(minHeight: 44, alignment: .leading)

                                Text(variables.isEmpty ? "模板至少需要一个填空项，例如 ${主题}。" : "填空项（\(variables.count)）：\(variables.joined(separator: "、"))")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.textSecondary)
                            } else {
                                Text("直接复制使用，正文中的占位符会原样保留。")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .appCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                showingTagPicker = true
                            } label: {
                                HStack(spacing: 12) {
                                    Label("选择标签", systemImage: "tag")
                                        .font(AppTypography.section)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text(selectedTags.isEmpty ? "可选" : "已选 \(selectedTags.count) 个")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.textTertiary)
                                    Image(systemName: "chevron.right")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.textTertiary)
                                }
                                .frame(minHeight: 44)
                            }
                            .accessibilityIdentifier("prompt.tags")

                            if !selectedTags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(selectedTags.sorted(), id: \.self) { name in
                                            Button {
                                                selectedTags.remove(name)
                                            } label: {
                                                Label(name, systemImage: "xmark.circle")
                                                    .font(AppTypography.caption)
                                                    .padding(.horizontal, 10)
                                                    .frame(minHeight: 44)
                                                    .background(Color.surface4)
                                                    .cornerRadius(8)
                                            }
                                            .foregroundColor(.textPrimary)
                                            .accessibilityLabel("移除标签 \(name)")
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appCard()

                        if kind == .template {
                            Button {
                                showingTemplateList = true
                            } label: {
                                Label("预设模板参考", systemImage: "books.vertical")
                            }
                            .foregroundColor(.accent)
                            .frame(minHeight: 44)
                        }

                        Label("保存在此 iPhone 的本地资料库", systemImage: "internaldrive")
                            .font(AppTypography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(AppSpacing.page)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("\(prompt == nil ? "新建" : "编辑")\(kind.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSaving ? "保存中…" : "保存") {
                        Task { await savePrompt() }
                    }
                    .accessibilityIdentifier("prompt.save")
                    .font(AppTypography.section)
                    .disabled(!isValid || isSaving)
                }
            }
            .sheet(isPresented: $showingTagPicker) {
                TagPickerView(selectedTags: $selectedTags)
            }
            .sheet(isPresented: $showingVariableSheet) {
                VariableInputView(promptText: $promptText)
            }
            .sheet(isPresented: $showingTemplateList) {
                TemplateReferenceView { template in
                    title = template.title
                    promptText = template.promptText
                    showingTemplateList = false
                }
            }
            .alert("保存失败", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("好的", role: .cancel) { saveError = nil }
            } message: { Text(saveError ?? "") }
        }
        .interactiveDismissDisabled(isSaving)
    }

    private func savePrompt() async {
        guard isValid, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        let input = CreatePromptInput(editing: prompt, title: title, promptText: promptText, tags: selectedTags.sorted(), kind: kind)
        let success: Bool
        if let prompt = prompt {
            success = await dataStore.updatePrompt(id: prompt.id, input: input)
        } else {
            success = await dataStore.createPrompt(input)
        }
        if success { dismiss() } else { saveError = dataStore.errorMessage }
    }
}
