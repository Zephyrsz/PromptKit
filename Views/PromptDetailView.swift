import SwiftUI

struct PromptDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore

    let prompt: Prompt

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var filledVars: [String: String] = [:]
    @State private var processedText = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.surface1.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title and icon
                        HStack(spacing: 12) {
                            Image(systemName: "message")
                                .font(.title)
                                .foregroundColor(.accent)
                                .frame(width: 50, height: 50)
                                .background(Color.accent.opacity(0.15))
                                .cornerRadius(10)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(prompt.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)

                                if let description = prompt.description, !description.isEmpty {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.textSecondary)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.surface3)
                        .cornerRadius(12)

                        // Tags
                        if !prompt.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(prompt.tags, id: \.self) { tagName in
                                        if let tag = dataStore.tags.first(where: { $0.name == tagName }) {
                                            Text(tag.name)
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(tag.swiftUIColor.opacity(0.3))
                                                .cornerRadius(999)
                                        }
                                    }
                                }
                            }
                        }

                        // Template variables
                        if let templateVars = prompt.templateVars, !templateVars.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("填写变量")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)

                                ForEach(templateVars, id: \.self) { varName in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(varName)
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)

                                        TextField("输入 \(varName)", text: Binding(
                                            get: { filledVars[varName] ?? "" },
                                            set: { filledVars[varName] = $0 }
                                        ))
                                        .foregroundColor(.textPrimary)
                                        .padding()
                                        .background(Color.surface2)
                                        .cornerRadius(8)
                                    }
                                }

                                Button {
                                    processTemplate()
                                } label: {
                                    Text("生成文本")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accent)
                                        .cornerRadius(999)
                                }
                            }
                            .padding()
                            .background(Color.surface3)
                            .cornerRadius(12)
                        }

                        // Content
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("模板内容")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Button {
                                    copyToClipboard()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                        Text("复制")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.accent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accent.opacity(0.15))
                                    .cornerRadius(999)
                                }
                            }

                            Text(processedText.isEmpty ? prompt.promptText : processedText)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surface2)
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.surface3)
                        .cornerRadius(12)

                        // Usage notes
                        if let usageNotes = prompt.usageNotes, !usageNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("使用说明")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)

                                Text(usageNotes)
                                    .font(.body)
                                    .foregroundColor(.textSecondary)
                            }
                            .padding()
                            .background(Color.surface3)
                            .cornerRadius(12)
                        }

                        // Actions
                        HStack(spacing: 12) {
                            Button {
                                showingEditSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("编辑")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.surface4)
                                .cornerRadius(999)
                            }

                            Button {
                                showingDeleteAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("删除")
                                }
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.surface4)
                                .cornerRadius(999)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await dataStore.toggleFavorite(prompt: prompt)
                        }
                    } label: {
                        Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                            .foregroundColor(prompt.isFavorite ? .yellow : .textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditPromptView(prompt: prompt)
            }
            .alert("删除模板", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    Task {
                        let success = await dataStore.deletePrompt(id: prompt.id)
                        if success {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("确定要删除「\(prompt.title)」吗？此操作无法撤销。")
            }
        }
    }

    func processTemplate() {
        var result = prompt.promptText

        if let templateVars = prompt.templateVars {
            for varName in templateVars {
                if let value = filledVars[varName], !value.isEmpty {
                    result = result.replacingOccurrences(of: "{{\(varName)}}", with: value)
                }
            }
        }

        processedText = result
    }

    func copyToClipboard() {
        let textToCopy = processedText.isEmpty ? prompt.promptText : processedText
        UIPasteboard.general.string = textToCopy
    }
}
