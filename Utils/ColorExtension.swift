import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        let components = UIColor(self).cgColor.components
        let r = components?[0] ?? 0
        let g = components?[1] ?? 0
        let b = components?[2] ?? 0

        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }
}

// Theme colors
extension Color {
    static let surface1 = Color(hex: "101216")
    static let surface2 = Color(hex: "14171C")
    static let surface3 = Color(hex: "1B1F26")
    static let surface4 = Color(hex: "252B34")
    static let surface5 = Color(hex: "343D49")
    static let outline = Color(hex: "343B46")

    static let accent = Color(hex: "78C4ED")
    static let accentMuted = Color(hex: "99D5F3")

    static let textPrimary = Color(hex: "F1F3F5")
    static let textSecondary = Color(hex: "B3BDC9")
    static let textTertiary = Color(hex: "9AA6B5")
}

// Semantic system fonts retain native Chinese fallback and Dynamic Type support.
enum AppTypography {
    static let wordmark = Font.custom("Georgia-BoldItalic", size: 27, relativeTo: .title2)
    static let title = Font.system(.title2, design: .default).weight(.semibold)
    static let section = Font.system(.headline, design: .default)
    static let body = Font.system(.body, design: .default)
    static let secondary = Font.system(.subheadline, design: .default)
    static let caption = Font.system(.footnote, design: .default)
}

enum AppBrand {
    static let name = "PromptMaster"
}

struct AppWordmark: View {
    var body: some View {
        Text(AppBrand.name)
            .font(AppTypography.wordmark)
            .foregroundColor(.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("app.wordmark")
    }
}

enum AppSpacing {
    static let page: CGFloat = 20
    static let section: CGFloat = 24
    static let card: CGFloat = 16
    static let gap: CGFloat = 12
    static let radius: CGFloat = 14
}

extension View {
    func appCard() -> some View {
        self.padding(AppSpacing.card)
            .background(Color.surface3, in: RoundedRectangle(cornerRadius: AppSpacing.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppSpacing.radius, style: .continuous).strokeBorder(Color.outline.opacity(0.65)))
    }

    func appInput() -> some View {
        self.font(AppTypography.body)
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.outline))
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.section)
            .foregroundColor(isEnabled ? .surface1 : .textTertiary)
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(14)
            .background(isEnabled ? Color.accent : Color.surface4, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct AppSearchField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.textTertiary)
                .accessibilityHidden(true)
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .accessibilityLabel(placeholder)
                .submitLabel(.search)
                .onSubmit { isFocused = false }
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textTertiary)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("清除搜索")
            }
        }
        .font(AppTypography.body)
        .foregroundColor(.textPrimary)
        .padding(.leading, 14)
        .padding(.trailing, text.isEmpty ? 14 : 0)
        .frame(minHeight: 50)
        .background(Color.surface3, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.outline))
    }
}

struct AppIconTile: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(.body, design: .default).weight(.medium))
            .foregroundColor(.accent)
            .frame(width: 40, height: 40)
            .background(Color.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct AppTagChip: View {
    let name: String
    var color: Color = .accent

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 5, height: 5).accessibilityHidden(true)
            Text(name).fixedSize(horizontal: false, vertical: true)
        }
        .font(AppTypography.caption)
        .foregroundColor(.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.surface4, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

struct AppEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(.largeTitle, design: .default).weight(.light))
                .foregroundColor(.accent)
                .padding(.bottom, 8)
                .accessibilityHidden(true)
            Text(title).font(AppTypography.section).foregroundColor(.textPrimary)
            Text(message).font(AppTypography.secondary).foregroundColor(.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.section)
    }
}
