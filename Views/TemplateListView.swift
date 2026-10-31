import SwiftUI

struct TemplateListView: View {
    var body: some View {
        PromptLibraryView(favoritesOnly: false)
    }
}

struct PromptCardView: View {
    let prompt: Prompt
    var onOpen: () -> Void
    @EnvironmentObject private var dataStore: DataStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onOpen) {
                    HStack(alignment: .top, spacing: 12) {
                        if !dynamicTypeSize.isAccessibilitySize {
                            AppIconTile(symbol: prompt.kind.icon)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(prompt.title)
                                .font(AppTypography.section)
                                .foregroundColor(.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(prompt.description.flatMap { $0.isEmpty ? nil : $0 } ?? prompt.promptText)
                                .font(AppTypography.secondary)
                                .foregroundColor(.textSecondary)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("打开\(prompt.kind.title)")

                Button {
                    Task { await dataStore.toggleFavorite(prompt: prompt) }
                } label: {
                    Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                        .font(AppTypography.body)
                        .foregroundColor(prompt.isFavorite ? .accent : .textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(prompt.isFavorite ? "取消收藏 \(prompt.title)" : "收藏 \(prompt.title)")
                .accessibilityValue(prompt.isFavorite ? "已收藏" : "未收藏")
            }

            if !prompt.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(prompt.tags, id: \.self) { name in
                            AppTagChip(name: name, color: dataStore.tags.first { $0.name == name }?.swiftUIColor ?? .accent)
                        }
                    }
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Label(prompt.kind.title, systemImage: prompt.kind.icon)
                Spacer(minLength: 8)
                Text(prompt.updatedAt, style: .date)
                    .monospacedDigit()
            }
            .font(AppTypography.caption)
            .foregroundColor(.textTertiary)
        }
        .appCard()
    }
}
