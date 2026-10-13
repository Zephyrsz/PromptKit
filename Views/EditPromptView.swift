import SwiftUI

struct EditPromptView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore

    let prompt: Prompt?

    @State private var title = ""
    @State private var promptText = ""
    @State private var selectedTags: Set<String> = []
    @State private var showingTagPicker = false
    @State private var showingVariableSheet = false
    @State private var templateVars: [String] = []
    @State private var showingTemplateList = false

    var isValid: Bool {
        !title.isEmpty && !promptText.isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.surface1.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Title field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "gift")
                                    .foregroundColor(.accent)
                                TextField("模板标题", text: $title)
                                    .foregroundColor(.textPrimary)
                            }
                            .padding()
                            .background(Color.surface3)
                            .cornerRadius(12)
                        }

                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                showingTagPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.accent)
                                    Text("添加标签")
                                        .foregroundColor(.accent)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.surface3)
                                .cornerRadius(12)
                            }

                            if !selectedTags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(selectedTags), id: \.self) { tagName in
                                            if let tag = dataStore.tags.first(where: { $0.name == tagName }) {
                                                HStack(spacing: 4) {
                                                    Text(tag.name)
                                                        .font(.caption)
                                                        .foregroundColor(.white)

                                                    Button {
                                                        selectedTags.remove(tagName)
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.caption)
                                                            .foregroundColor(.white.opacity(0.7))
                                                    }
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(tag.swiftUIColor.opacity(0.3))
                                                .cornerRadius(999)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Content field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("模板内容")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Button {
                                    // Toggle visibility
                                } label: {
                                    Image(systemName: "eye")
                                        .foregroundColor(.textTertiary)
                                }
                            }

                            TextEditor(text: $promptText)
                                .foregroundColor(.textPrimary)
                                .frame(minHeight: 200)
                                .padding(8)
                                .background(Color.surface2)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.surface4, lineWidth: 1)
                                )

                            HStack {
                                Button {
                                    // Paste
                                } label: {
                                    Image(systemName: "doc.on.clipboard")
                                        .foregroundColor(.textTertiary)
                                }

                                Button {
                                    // Format
                                } label: {
                                    Image(systemName: "list.bullet")
                                        .foregroundColor(.textTertiary)
                                }

                                Spacer()

                                Button {
                                    showingVariableSheet = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("插入替换项")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.accentMuted)
                                    .cornerRadius(999)
                                }
                            }
                        }
                        .padding()
                        .background(Color.surface3)
                        .cornerRadius(12)

                        // Template variables info
                        if !templateVars.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                        .foregroundColor(.textSecondary)
                                    Text("模板没有填空项")
                                        .font(.headline)
                                        .foregroundColor(.textSecondary)
                                }

                                Text("点击「插入替换项」或选中文字后点击「设为可替换」来添加填空项")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                            .padding()
                            .background(Color.surface2)
                            .cornerRadius(12)
                        }

                        // Template reference
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(.yellow)
                                Image(systemName: "books.vertical")
                                    .foregroundColor(.accent)
                                Text("预设模板参考")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)

                                Spacer()
                            }

                            Button {
                                showingTemplateList = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("1")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .frame(width: 24, height: 24)
                                                .background(Color.accent)
                                                .clipShape(Circle())

                                            Text("创意文案")
                                                .font(.headline)
                                                .foregroundColor(.accent)
                                        }

                                        Text("快速生成吸引人的营销文案")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.accent)
                                }
                                .padding()
                                .background(Color.surface2)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.surface3)
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("创建")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await savePrompt()
                        }
                    }
                    .foregroundColor(isValid ? .textSecondary : .textTertiary)
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingTagPicker) {
                TagPickerView(selectedTags: $selectedTags)
            }
            .sheet(isPresented: $showingVariableSheet) {
                VariableInputView(templateVars: $templateVars, promptText: $promptText)
            }
            .sheet(isPresented: $showingTemplateList) {
                TemplateReferenceView(onSelectTemplate: { template in
                    title = template.title
                    promptText = template.promptText
                    showingTemplateList = false
                })
            }
        }
        .onAppear {
            if let prompt = prompt {
                title = prompt.title
                promptText = prompt.promptText
                selectedTags = Set(prompt.tags)
                templateVars = prompt.templateVars ?? []
            }
        }
    }

    func savePrompt() async {
        let input = CreatePromptInput(
            title: title,
            description: nil,
            promptText: promptText,
            tags: Array(selectedTags),
            usageNotes: nil,
            isFavorite: false,
            isTemplate: true,
            templateVars: templateVars.isEmpty ? nil : templateVars
        )

        let success: Bool
        if let prompt = prompt {
            success = await dataStore.updatePrompt(id: prompt.id, input: input)
        } else {
            success = await dataStore.createPrompt(input)
        }

        if success {
            dismiss()
        }
    }
}
