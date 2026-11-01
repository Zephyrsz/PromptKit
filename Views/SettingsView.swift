import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var showingTagManagement = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .top, spacing: AppSpacing.gap) {
                        AppIconTile(symbol: "internaldrive")
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("本地资料库").font(AppTypography.section)
                            Text("仅保存在此 iPhone")
                                .font(AppTypography.secondary)
                                .foregroundColor(.textSecondary)
                            Text("\(dataStore.prompts.count) 条内容 · \(dataStore.tags.count) 个标签")
                                .font(AppTypography.caption)
                                .foregroundColor(.textTertiary)
                        }
                    }
                    .padding(.vertical, AppSpacing.small)
                }
                .listRowBackground(Color.surface3)

                Section {
                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        SettingsRow(symbol: "globe", title: "语言", value: "简体中文")
                    }
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        SettingsRow(symbol: "circle.lefthalf.filled", title: "外观", value: "深色模式")
                    }
                } header: {
                    sectionTitle("偏好设置")
                }
                .listRowBackground(Color.surface3)

                Section {
                    Button { showingTagManagement = true } label: {
                        SettingsRow(symbol: "tag", title: "标签管理", showsChevron: true)
                    }
                    .accessibilityLabel("标签管理")
                    .accessibilityIdentifier("settings.tags")

                    unavailableRow(symbol: "square.and.arrow.up", title: "数据导出", identifier: "settings.export")
                    unavailableRow(symbol: "icloud", title: "iCloud 同步", identifier: "settings.sync")
                } header: {
                    sectionTitle("数据与存储")
                } footer: {
                    Text("笔记、模板和标签均保存在本机；当前版本暂不支持导出和跨设备同步。")
                        .font(AppTypography.caption)
                        .foregroundColor(.textSecondary)
                }
                .listRowBackground(Color.surface3)

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRow(symbol: "info.circle", title: "关于")
                    }
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        SettingsRow(symbol: "hand.raised", title: "隐私政策")
                    }
                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        SettingsRow(symbol: "doc.text", title: "服务条款")
                    }
                    unavailableRow(symbol: "envelope", title: "反馈", identifier: "settings.feedback")
                    unavailableRow(symbol: "star", title: "给 \(AppBrand.name) 评分", identifier: "settings.rating")
                    unavailableRow(symbol: "message.circle", title: "QQ 交流群", identifier: "settings.community")
                    unavailableRow(symbol: "sparkles", title: "Pro", identifier: "settings.pro")
                } header: {
                    sectionTitle("支持与关于")
                }
                .listRowBackground(Color.surface3)
            }
            .appGroupedList()
            .buttonStyle(AppPressFeedbackStyle())
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .appScreen()
            .sheet(isPresented: $showingTagManagement) { TagManagementView() }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.caption.weight(.semibold))
            .foregroundColor(.textSecondary)
            .textCase(nil)
    }

    private func unavailableRow(symbol: String, title: String, identifier: String) -> some View {
        Button {} label: {
            SettingsRow(symbol: symbol, title: title, value: "暂未开放")
        }
        .disabled(true)
        .accessibilityIdentifier(identifier)
        .accessibilityHint("当前版本暂未开放")
    }
}

private struct SettingsRow: View {
    let symbol: String
    let title: String
    var value: String? = nil
    var showsChevron = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: dynamicTypeSize.isAccessibilitySize ? .top : .center, spacing: AppSpacing.gap) {
            AppIconTile(symbol: symbol)
            if dynamicTypeSize.isAccessibilitySize {
                stackedText
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.small) {
                        Text(title).fixedSize()
                        Spacer(minLength: AppSpacing.small)
                        if let value { valueText(value).fixedSize() }
                    }
                    stackedText
                }
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .font(AppTypography.body)
        .foregroundColor(.textPrimary)
        .frame(maxWidth: .infinity, minHeight: AppMetrics.touchTarget, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var stackedText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).fixedSize(horizontal: false, vertical: true)
            if let value { valueText(value) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func valueText(_ value: String) -> some View {
        Text(value)
            .font(AppTypography.caption)
            .foregroundColor(.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct TagManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataStore: DataStore
    @State private var showingCreateTag = false
    @State private var tagToDelete: Tag?

    var body: some View {
        NavigationStack {
            List {
                if let error = dataStore.errorMessage {
                    AppStatusMessage(message: error)
                        .listRowBackground(Color.surface1)
                        .listRowSeparator(.hidden)
                }
                if dataStore.tags.isEmpty {
                    AppEmptyState(symbol: "tag", title: "还没有标签", message: "点击右上角加号创建标签，整理你的笔记和模板。")
                        .listRowBackground(Color.surface1)
                        .listRowSeparator(.hidden)
                }
                Section {
                    ForEach(dataStore.tags) { tag in
                        HStack(spacing: AppSpacing.gap) {
                            Circle()
                                .fill(tag.swiftUIColor)
                                .frame(width: 12, height: 12)
                                .accessibilityHidden(true)
                            Text(tag.name).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: AppSpacing.small)
                            Button {
                                tagToDelete = tag
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.appError)
                                    .frame(width: AppMetrics.touchTarget, height: AppMetrics.touchTarget)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("删除标签 \(tag.name)")
                        }
                    }
                    .listRowBackground(Color.surface3)
                } footer: {
                    if !dataStore.tags.isEmpty {
                        Text("正在使用的标签需先从相关笔记或模板中移除，才能删除。")
                            .font(AppTypography.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .appGroupedList()
            .navigationTitle("标签管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    AppCloseButton(label: "关闭标签管理") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingCreateTag = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .frame(minWidth: AppMetrics.touchTarget, minHeight: AppMetrics.touchTarget)
                    }
                    .accessibilityIdentifier("tag.add")
                    .accessibilityLabel("新建标签")
                }
            }
            .appScreen()
            .sheet(isPresented: $showingCreateTag) { CreateTagView() }
            .alert("删除标签", isPresented: .init(
                get: { tagToDelete != nil },
                set: { if !$0 { tagToDelete = nil } }
            )) {
                Button("取消", role: .cancel) { tagToDelete = nil }
                Button("删除", role: .destructive) {
                    if let tag = tagToDelete {
                        Task {
                            _ = await dataStore.deleteTag(id: tag.id)
                            tagToDelete = nil
                        }
                    }
                }
            } message: {
                if let tag = tagToDelete { Text("确定要删除标签「\(tag.name)」吗？此操作无法撤销。") }
            }
        }
    }
}

private struct SettingsInformationView: View {
    let title: String
    let symbol: String
    let message: String

    var body: some View {
        ScrollView {
            AppEmptyState(symbol: symbol, title: title, message: message)
                .appCard()
                .padding(AppSpacing.page)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }
}

struct LanguageSettingsView: View {
    var body: some View {
        SettingsInformationView(title: "语言", symbol: "globe", message: "当前界面使用简体中文，日期遵循系统区域设置。应用内切换语言暂未开放。")
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        SettingsInformationView(title: "外观", symbol: "circle.lefthalf.filled", message: "当前使用石墨灰分层表面、蓝色强调色和统一的系统字号。外观切换暂未开放。")
    }
}

struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                AppIconTile(symbol: "text.alignleft")
                AppWordmark()
                Text("收藏灵感，复用每一个好提示词。")
                    .font(AppTypography.secondary)
                    .foregroundColor(.textSecondary)
                Text("版本 \(version)")
                    .font(AppTypography.caption)
                    .foregroundColor(.textTertiary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .appCard()
            .padding(AppSpacing.page)
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .appScreen()
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        SettingsInformationView(title: "隐私政策", symbol: "hand.raised", message: "隐私政策正文尚未提供。当前版本的笔记、模板与标签保存在此 iPhone 的本地资料库，尚未接入云同步。")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        SettingsInformationView(title: "服务条款", symbol: "doc.text", message: "服务条款正文尚未提供，正式内容将在后续版本发布。")
    }
}
