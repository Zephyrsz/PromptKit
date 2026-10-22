import SwiftUI

struct TagPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore

    @Binding var selectedTags: Set<String>
    @State private var showingCreateTag = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surface1.ignoresSafeArea()

                List {
                    ForEach(dataStore.tags) { tag in
                        Button {
                            if selectedTags.contains(tag.name) {
                                selectedTags.remove(tag.name)
                            } else {
                                selectedTags.insert(tag.name)
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedTags.contains(tag.name) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedTags.contains(tag.name) ? .accent : .textTertiary)

                                Text(tag.name)
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Circle()
                                    .fill(tag.swiftUIColor)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                    .listRowBackground(Color.surface3)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("选择标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.accent)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateTag = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.accent)
                    }
                    .accessibilityIdentifier("tag.add")
                    .accessibilityLabel("新建标签")
                }
            }
            .sheet(isPresented: $showingCreateTag) {
                CreateTagView { tag in selectedTags.insert(tag.name) }
            }
        }
    }
}

struct CreateTagView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore

    @State private var tagName = ""
    @State private var selectedColor = "#38BDF8"
    @State private var isSaving = false
    @State private var saveError: String?
    var onCreate: ((Tag) -> Void)? = nil

    private var trimmedName: String { tagName.trimmingCharacters(in: .whitespacesAndNewlines) }

    let predefinedColors = [
        "#38BDF8", "#6EE7B7", "#E9A568", "#3B6DFF",
        "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.surface1.ignoresSafeArea()

                VStack(spacing: 20) {
                    TextField("标签名称", text: $tagName)
                        .accessibilityIdentifier("tag.name")
                        .foregroundColor(.textPrimary)
                        .padding()
                        .background(Color.surface3)
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择颜色")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(predefinedColors, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                }
                                .accessibilityLabel("标签颜色 \(color)")
                                .accessibilityAddTraits(selectedColor == color ? .isSelected : [])
                            }
                        }
                    }

                    if let saveError = saveError {
                        Text(saveError)
                            .foregroundColor(.red)
                            .font(.callout)
                            .accessibilityIdentifier("tag.error")
                    }

                    Spacer()

                    Button {
                        Task {
                            await createTag()
                        }
                    } label: {
                        Text(isSaving ? "保存中…" : "创建标签")
                            .font(.headline)
                            .foregroundColor(trimmedName.isEmpty ? .textSecondary : .surface1)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(trimmedName.isEmpty ? Color.surface4 : Color.accent)
                            .cornerRadius(999)
                    }
                    .accessibilityIdentifier("tag.save")
                    .disabled(trimmedName.isEmpty || isSaving)
                }
                .padding()
            }
            .navigationTitle("新建标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }

    func createTag() async {
        guard !trimmedName.isEmpty, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        let input = CreateTagInput(name: trimmedName, color: selectedColor)
        let success = await dataStore.createTag(input)
        if success {
            if let tag = dataStore.tags.first(where: { $0.name == trimmedName }) { onCreate?(tag) }
            dismiss()
        } else {
            saveError = dataStore.errorMessage
        }
    }
}
