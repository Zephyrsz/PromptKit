import SwiftUI

struct QuickAccessView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var searchText = ""
    @State private var selectedPrompt: Prompt?

    var filteredPrompts: [Prompt] {
        let favoritePrompts = dataStore.prompts.filter { $0.isFavorite }

        if searchText.isEmpty {
            return favoritePrompts
        } else {
            return favoritePrompts.filter { prompt in
                prompt.title.localizedCaseInsensitiveContains(searchText) ||
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

                        TextField("搜索快捷模板...", text: $searchText)
                            .foregroundColor(.textPrimary)
                    }
                    .padding()
                    .background(Color.surface3)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Quick access list
                    if filteredPrompts.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 48))
                                .foregroundColor(.textTertiary)
                            Text("暂无快捷模板")
                                .foregroundColor(.textSecondary)
                            Text("收藏模板后可在此快速访问")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredPrompts) { prompt in
                                    QuickAccessCardView(prompt: prompt)
                                        .onTapGesture {
                                            selectedPrompt = prompt
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("快捷贴贴")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedPrompt) { prompt in
                QuickUsePromptView(prompt: prompt)
            }
        }
    }
}

struct QuickAccessCardView: View {
    let prompt: Prompt
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title3)
                    .foregroundColor(.accentMuted)
                    .frame(width: 40, height: 40)
                    .background(Color.accentMuted.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text(prompt.promptText)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.textTertiary)
            }

            // Tags
            if !prompt.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(prompt.tags.prefix(3), id: \.self) { tagName in
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
                    }
                }
            }
        }
        .padding()
        .background(Color.surface3)
        .cornerRadius(12)
    }
}

struct QuickUsePromptView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore

    let prompt: Prompt

    @State private var filledVars: [String: String] = [:]
    @State private var processedText = ""
    @State private var showingCopiedAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surface1.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.title)
                                .foregroundColor(.accentMuted)
                                .frame(width: 50, height: 50)
                                .background(Color.accentMuted.opacity(0.15))
                                .cornerRadius(10)

                            Text(prompt.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            Spacer()
                        }
                        .padding()
                        .background(Color.surface3)
                        .cornerRadius(12)

                        // Template variables
                        if let templateVars = prompt.templateVars, !templateVars.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("快速填写")
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
                                    Text("生成")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentMuted)
                                        .cornerRadius(999)
                                }
                            }
                            .padding()
                            .background(Color.surface3)
                            .cornerRadius(12)
                        }

                        // Result
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("生成结果")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Button {
                                    copyAndDismiss()
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
                    }
                    .padding()
                }
            }
            .navigationTitle("快速使用")
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
            }
            .alert("已复制", isPresented: $showingCopiedAlert) {
                Button("好的", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("内容已复制到剪贴板")
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

    func copyAndDismiss() {
        let textToCopy = processedText.isEmpty ? prompt.promptText : processedText
        UIPasteboard.general.string = textToCopy
        showingCopiedAlert = true
    }
}
