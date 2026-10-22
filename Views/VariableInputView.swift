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
        NavigationView {
            ZStack {
                Color.surface1.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("变量名称")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        TextField("例如: 主题、产品名称", text: $varName)
                            .foregroundColor(.textPrimary)
                            .padding()
                            .background(Color.surface3)
                            .cornerRadius(12)

                        Text("将在模板中插入 ${\(trimmedName.isEmpty ? "变量名" : trimmedName)}")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    if !templateVars.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("已有变量")
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            ForEach(templateVars, id: \.self) { varName in
                                HStack {
                                    Text(varName)
                                        .font(.body)
                                        .foregroundColor(.accent)

                                    Spacer()

                                    Button {
                                        promptText = TemplateText.render(promptText, values: [varName: varName])
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.textTertiary)
                                    }
                                    .accessibilityLabel("移除填空项 \(varName)")
                                }
                                .padding()
                                .background(Color.surface3)
                                .cornerRadius(8)
                            }
                        }
                    }

                    Spacer()

                    Button {
                        addVariable()
                    } label: {
                        Text("插入变量")
                            .font(.headline)
                            .foregroundColor(isValid ? .surface1 : .textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid ? Color.accent : Color.surface4)
                            .cornerRadius(999)
                    }
                    .disabled(!isValid)
                }
                .padding()
            }
            .navigationTitle("添加替换项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.accent)
                }
            }
        }
    }

    func addVariable() {
        guard isValid else { return }
        promptText += " ${\(trimmedName)}"
        dismiss()
    }
}
