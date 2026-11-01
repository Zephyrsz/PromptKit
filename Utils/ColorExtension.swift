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
    static let appError = Color(hex: "FF9B9B")
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
    static let small: CGFloat = 8
    static let page: CGFloat = 20
    static let section: CGFloat = 24
    static let card: CGFloat = 16
    static let gap: CGFloat = 12
    static let radius: CGFloat = 14
}

enum AppRadius {
    static let chip: CGFloat = 8
    static let control: CGFloat = 12
    static let card: CGFloat = AppSpacing.radius
}

enum AppMetrics {
    static let touchTarget: CGFloat = 44
    static let controlHeight: CGFloat = 50
}

extension View {
    func appCard() -> some View {
        self.padding(AppSpacing.card)
            .background(Color.surface3, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous).strokeBorder(Color.outline.opacity(0.65)))
    }

    func appInputSurface() -> some View {
        self.background(Color.surface2, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous).strokeBorder(Color.outline))
    }

    func appInput() -> some View {
        self.font(AppTypography.body)
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: AppMetrics.controlHeight)
            .appInputSurface()
    }

    func appScreen() -> some View {
        self.font(AppTypography.body)
            .foregroundColor(.textPrimary)
            .tint(.accent)
            .background(Color.surface1.ignoresSafeArea())
            .toolbarBackground(Color.surface1, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
    }

    func appGroupedList() -> some View {
        self.listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 56)
            .listRowSeparatorTint(Color.outline.opacity(0.65))
            .scrollContentBackground(.hidden)
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.section)
            .foregroundColor(isEnabled ? .surface1 : .textTertiary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(14)
            .background(isEnabled ? Color.accent : Color.surface4, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    var isDestructive = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.secondary.weight(.semibold))
            .foregroundColor(isDestructive ? .appError : .accent)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 24)
            .padding(12)
            .background(isDestructive ? Color.appError.opacity(0.08) : Color.surface4,
                        in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .strokeBorder(isDestructive ? Color.appError.opacity(0.3) : Color.outline))
            .opacity(!isEnabled ? 0.5 : configuration.isPressed ? 0.75 : 1)
    }
}

struct AppPressFeedbackStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct AppCloseButton: View {
    let label: String
    var identifier = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .frame(minWidth: AppMetrics.touchTarget, minHeight: AppMetrics.touchTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }
}

struct AppSectionHeader: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.section)
                .foregroundColor(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let detail {
                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AppStatusMessage: View {
    let message: String
    var isError = true

    var body: some View {
        Label(message, systemImage: isError ? "exclamationmark.circle" : "info.circle")
            .font(AppTypography.secondary)
            .foregroundColor(isError ? .appError : .textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.gap)
            .background(isError ? Color.appError.opacity(0.08) : Color.surface2,
                        in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
            .accessibilityElement(children: .combine)
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
            TextField(placeholder, text: $text, prompt: Text(placeholder).foregroundColor(.textTertiary))
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
        .padding(.vertical, 4)
        .frame(minHeight: AppMetrics.controlHeight)
        .background(Color.surface3, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous).strokeBorder(Color.outline))
    }
}

struct AppIconTile: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.accent)
            .frame(width: 40, height: 40)
            .background(Color.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct AppTagChip: View {
    let name: String
    var color: Color = .accent
    var removable = false

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 5, height: 5).accessibilityHidden(true)
            Text(name).fixedSize(horizontal: false, vertical: true)
            if removable {
                Image(systemName: "xmark")
                    .font(AppTypography.caption.weight(.semibold))
                    .accessibilityHidden(true)
            }
        }
        .font(AppTypography.caption)
        .foregroundColor(.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.surface4, in: RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
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
                .accessibilityAddTraits(.isHeader)
            Text(message).font(AppTypography.secondary).foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.section)
    }
}

struct AppComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppSectionHeader(title: "统一的界面组件", detail: "石墨灰表面 · 蓝色操作 · 原生动态字号")
                VStack(alignment: .leading, spacing: AppSpacing.gap) {
                    TextField("输入内容", text: .constant("")).appInput()
                    TagFlowLayout {
                        AppTagChip(name: "工作")
                        AppTagChip(name: "写作", removable: true)
                    }
                    Button("生成并复制") {}.buttonStyle(AppPrimaryButtonStyle())
                    Button("编辑") {}.buttonStyle(AppSecondaryButtonStyle())
                }
                .appCard()
                AppStatusMessage(message: "未能保存，请重试。")
                AppEmptyState(symbol: "star", title: "暂无收藏", message: "收藏常用的笔记或模板，方便下次找到。")
            }
            .padding(AppSpacing.page)
        }
        .appScreen()
        .previewDisplayName("共享组件")
    }
}
