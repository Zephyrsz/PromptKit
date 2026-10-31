import SwiftUI

struct TemplateReferenceView: View {
    @Environment(\.dismiss) var dismiss

    let onSelectTemplate: (Prompt) -> Void

    let presetTemplates = [
        Prompt(
            id: -1,
            title: "创意文案",
            description: "快速生成吸引人的营销文案",
            promptText: "帮我写一段关于{{主题}}的文案。",
            tags: ["营销", "文案"],
            isTemplate: true,
            templateVars: ["主题"]
        ),
        Prompt(
            id: -2,
            title: "面试模拟",
            description: "模拟真实面试场景，提升求职竞争力",
            promptText: "你是一位资深的{{职位}}面试官，请对我进行面试，并在结束后给出反馈。",
            tags: ["面试", "求职"],
            isTemplate: true,
            templateVars: ["职位"]
        ),
        Prompt(
            id: -3,
            title: "AI绘图词",
            description: "生成高质量的AI绘图提示词",
            promptText: "请为我生成一个{{风格}}风格的AI绘图提示词，主题是{{主题}}。",
            tags: ["AI", "绘图"],
            isTemplate: true,
            templateVars: ["风格", "主题"]
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(presetTemplates.enumerated()), id: \.element.id) { index, template in
                            Button {
                                onSelectTemplate(template)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(AppTypography.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.surface1)
                                        .frame(width: 28, height: 28)
                                        .background(Color.accent)
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(template.title)
                                            .font(AppTypography.section)
                                            .foregroundColor(.accent)

                                        Text(template.description ?? "")
                                            .font(AppTypography.caption)
                                            .foregroundColor(.textSecondary)

                                        Text(template.promptText)
                                            .font(AppTypography.caption)
                                            .foregroundColor(.textSecondary)
                                            .lineLimit(2)
                                            .padding(.top, 4)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.accent)
                                }
                                .appCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(AppSpacing.page)
                }
            }
            .navigationTitle("预设模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
    }
}
