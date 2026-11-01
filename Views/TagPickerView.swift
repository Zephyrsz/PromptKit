import SwiftUI

struct TagPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore

    @Binding var selectedTags: Set<String>
    @State private var showingCreateTag = false

    var body: some View {
        NavigationStack {
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
                            HStack(spacing: 12) {
                                Image(systemName: selectedTags.contains(tag.name) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedTags.contains(tag.name) ? .accent : .textTertiary)
                                    .accessibilityHidden(true)

                                Text(tag.name)
                                    .foregroundColor(.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer()

                                Circle()
                                    .fill(tag.swiftUIColor)
                                    .frame(width: 12, height: 12)
                                    .accessibilityHidden(true)
                            }
                            .frame(minHeight: AppMetrics.touchTarget)
                        }
                        .accessibilityLabel(tag.name)
                        .accessibilityValue(selectedTags.contains(tag.name) ? "已选择" : "未选择")
                        .accessibilityAddTraits(selectedTags.contains(tag.name) ? .isSelected : [])
                        .accessibilityIdentifier("tag.option.\(tag.name)")
                    }
                    .listRowBackground(Color.surface3)
                    if dataStore.tags.isEmpty {
                        AppEmptyState(symbol: "tag", title: "还没有标签", message: "点击右上角加号，新建后会自动选中。")
                            .listRowBackground(Color.surface1)
                            .listRowSeparator(.hidden)
                    }
                }
                .appGroupedList()
            }
            .navigationTitle("选择标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.accent)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateTag = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.accent)
                            .frame(minWidth: AppMetrics.touchTarget, minHeight: AppMetrics.touchTarget)
                    }
                    .accessibilityIdentifier("tag.add")
                    .accessibilityLabel("新建标签")
                }
            }
            .appScreen()
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

    private let predefinedColors: [TagColorChoice] = [
        .init(name: "蓝色", hex: "#38BDF8"), .init(name: "薄荷绿", hex: "#6EE7B7"),
        .init(name: "杏色", hex: "#E9A568"), .init(name: "靛蓝", hex: "#3B6DFF"),
        .init(name: "琥珀色", hex: "#F59E0B"), .init(name: "红色", hex: "#EF4444"),
        .init(name: "紫色", hex: "#8B5CF6"), .init(name: "粉色", hex: "#EC4899")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        VStack(alignment: .leading, spacing: 10) {
                            AppSectionHeader(title: "标签名称")
                            TextField("例如：写作、工作", text: $tagName)
                                .accessibilityIdentifier("tag.name")
                                .accessibilityLabel("标签名称")
                                .appInput()
                        }
                        .appCard()

                        VStack(alignment: .leading, spacing: 12) {
                            AppSectionHeader(title: "标签颜色", detail: "颜色帮助区分标签，不影响内容分类。")

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                ForEach(predefinedColors) { color in
                                    Button {
                                        selectedColor = color.hex
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: color.hex))
                                            .frame(width: 50, height: 50)
                                            .overlay {
                                                if selectedColor == color.hex {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 20, weight: .semibold))
                                                        .foregroundColor(.black)
                                                }
                                            }
                                            .overlay(Circle().strokeBorder(Color.white.opacity(0.8), lineWidth: selectedColor == color.hex ? 2 : 0))
                                            .frame(maxWidth: .infinity, minHeight: 56)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(AppPressFeedbackStyle())
                                    .accessibilityIdentifier("tag.color.\(color.name)")
                                    .accessibilityLabel(color.name)
                                    .accessibilityValue(selectedColor == color.hex ? "已选择" : "未选择")
                                    .accessibilityAddTraits(selectedColor == color.hex ? .isSelected : [])
                                }
                            }
                        }
                        .appCard()

                        if let saveError = saveError {
                            AppStatusMessage(message: saveError)
                                .accessibilityIdentifier("tag.error")
                        }

                        Button {
                            Task {
                                await createTag()
                            }
                        } label: {
                            Text(isSaving ? "保存中…" : "创建标签")
                        }
                        .buttonStyle(AppPrimaryButtonStyle())
                        .accessibilityIdentifier("tag.save")
                        .disabled(trimmedName.isEmpty || isSaving)
                    }
                    .padding(AppSpacing.page)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("新建标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
            .appScreen()
        }
        .interactiveDismissDisabled(isSaving)
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

private struct TagColorChoice: Identifiable {
    let name: String
    let hex: String
    var id: String { hex }
}
