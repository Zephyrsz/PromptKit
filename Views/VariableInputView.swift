import SwiftUI

struct VariableInputView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var promptText: String

    @State private var varName = ""

    private var templateVars: [String] { TemplateText.variables(in: promptText) }
    private var trimmedName: String { varName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool {
        !trimmedName.isEmpty && trimmedName.rangeOfCharacter(from: CharacterSet(charactersIn: "{}\r\n")) == nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        VStack(alignment: .leading, spacing: 12) {
                            AppSectionHeader(title: "填空项名称")

                            TextField("例如：主题、产品名称", text: $varName)
                                .accessibilityLabel("填空项名称")
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .appInput()

                            Text("将在模板末尾插入 ${\(trimmedName.isEmpty ? "填空项名称" : trimmedName)}")
                                .font(AppTypography.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .appCard()

                        if !templateVars.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                AppSectionHeader(title: "已有填空项", detail: "移除填空项会保留名称作为普通文字。")

                                ForEach(templateVars, id: \.self) { varName in
                                    HStack {
                                        Text(varName)
                                            .font(AppTypography.body)
                                            .foregroundColor(.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Spacer()

                                        Button {
                                            promptText = TemplateText.render(promptText, values: [varName: varName])
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.textTertiary)
                                                .frame(width: 44, height: 44)
                                        }
                                        .buttonStyle(AppPressFeedbackStyle())
                                        .accessibilityLabel("移除填空项 \(varName)")
                                    }
                                    if varName != templateVars.last {
                                        Divider().overlay(Color.outline)
                                    }
                                }
                            }
                            .appCard()
                        }

                        Button {
                            addVariable()
                        } label: {
                            Label("插入填空项", systemImage: "plus.circle")
                        }
                        .buttonStyle(AppPrimaryButtonStyle())
                        .disabled(!isValid)
                    }
                    .padding(AppSpacing.page)
                }
            }
            .navigationTitle("插入填空项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    AppCloseButton(label: "关闭填空项") { dismiss() }
                }
            }
            .appScreen()
        }
    }

    func addVariable() {
        guard isValid else { return }
        promptText += " ${\(trimmedName)}"
        dismiss()
    }
}
