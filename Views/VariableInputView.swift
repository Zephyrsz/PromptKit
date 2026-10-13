import SwiftUI

struct VariableInputView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var templateVars: [String]
    @Binding var promptText: String

    @State private var varName = ""

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

                        Text("将在模板中插入 {{\(varName.isEmpty ? "变量名" : varName)}}")
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
                                    Text("{{\(varName)}}")
                                        .font(.body)
                                        .foregroundColor(.accent)

                                    Spacer()

                                    Button {
                                        templateVars.removeAll { $0 == varName }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.textTertiary)
                                    }
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
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(varName.isEmpty ? Color.surface4 : Color.accentMuted)
                            .cornerRadius(999)
                    }
                    .disabled(varName.isEmpty)
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
        let trimmedName = varName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if !templateVars.contains(trimmedName) {
            templateVars.append(trimmedName)
            promptText += " {{\(trimmedName)}}"
        }

        varName = ""
    }
}
