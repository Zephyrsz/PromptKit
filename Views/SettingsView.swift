import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingTagManagement = false
    @State private var showingExport = false
    @State private var iCloudSyncEnabled = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()

                List {
                    // Pro section
                    Section {
                        Button {
                            // TODO: Pro upgrade
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(AppTypography.title)
                                    .foregroundColor(.accent)
                                    .frame(width: 40, height: 40)
                                    .background(Color.accent.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pro")
                                        .font(AppTypography.section)
                                        .foregroundColor(.textPrimary)

                                    Text("高级版已激活・年度")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(.footnote, design: .default).weight(.semibold))
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                    .listRowBackground(Color.surface3)

                    // Preferences
                    Section(header: Text("偏好设置").foregroundColor(.textSecondary)) {
                        NavigationLink {
                            LanguageSettingsView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("语言")
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Text("跟随系统")
                                    .foregroundColor(.textTertiary)
                            }
                        }

                        NavigationLink {
                            AppearanceSettingsView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("外观")
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Text("深色模式")
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                    .listRowBackground(Color.surface3)

                    // Data & Storage
                    Section(header: Text("数据与存储").foregroundColor(.textSecondary)) {
                        Button {
                            showingTagManagement = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "tag")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("标签管理")
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(.footnote, design: .default).weight(.semibold))
                                    .foregroundColor(.textTertiary)
                            }
                        }

                        Button {
                            showingExport = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("数据导出")
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(.footnote, design: .default).weight(.semibold))
                                    .foregroundColor(.textTertiary)
                            }
                        }

                        Toggle(isOn: $iCloudSyncEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "icloud")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("iCloud 同步")
                                    .foregroundColor(.textPrimary)
                            }
                        }
                        .tint(.accent)
                    }
                    .listRowBackground(Color.surface3)

                    // Support
                    Section(header: Text("支持").foregroundColor(.textSecondary)) {
                        NavigationLink {
                            AboutView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("关于")
                                    .foregroundColor(.textPrimary)
                            }
                        }

                        NavigationLink {
                            PrivacyPolicyView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "hand.raised")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("隐私政策")
                                    .foregroundColor(.textPrimary)
                            }
                        }

                        NavigationLink {
                            TermsOfServiceView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("服务条款")
                                    .foregroundColor(.textPrimary)
                            }
                        }

                        Button {
                            // TODO: Feedback
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("反馈")
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(.footnote, design: .default).weight(.semibold))
                                    .foregroundColor(.textTertiary)
                            }
                        }

                        Button {
                            // TODO: Rating
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "star")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("给 \(AppBrand.name) 评分")
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(.footnote, design: .default).weight(.semibold))
                                    .foregroundColor(.textTertiary)
                            }
                        }

                        Button {
                            // TODO: QQ Group
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "message.circle")
                                    .font(AppTypography.body)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.accent)

                                Text("QQ 交流群")
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(.footnote, design: .default).weight(.semibold))
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                    .listRowBackground(Color.surface3)

                    // Other Apps
                }
                .listStyle(.insetGrouped)
                .environment(\.defaultMinListRowHeight, 52)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingTagManagement) {
                TagManagementView()
            }
            .sheet(isPresented: $showingExport) {
                DataExportView()
            }
        }
    }
}

struct TagManagementView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore
    @State private var showingCreateTag = false
    @State private var tagToDelete: Tag?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()

                List {
                    if let error = dataStore.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                    ForEach(dataStore.tags) { tag in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(tag.swiftUIColor)
                                .frame(width: 12, height: 12)

                            Text(tag.name)
                                .foregroundColor(.textPrimary)

                            Spacer()

                            Button {
                                tagToDelete = tag
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("删除标签 \(tag.name)")
                        }
                    }
                    .listRowBackground(Color.surface3)
                }
                .listStyle(.insetGrouped)
                .environment(\.defaultMinListRowHeight, 52)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("标签管理")
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
                            .font(AppTypography.body)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.accent)
                    }
                    .accessibilityIdentifier("tag.add")
                    .accessibilityLabel("新建标签")
                }
            }
            .sheet(isPresented: $showingCreateTag) {
                CreateTagView()
            }
            .alert("删除标签", isPresented: .init(
                get: { tagToDelete != nil },
                set: { if !$0 { tagToDelete = nil } }
            )) {
                Button("取消", role: .cancel) {
                    tagToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let tag = tagToDelete {
                        Task {
                            await dataStore.deleteTag(id: tag.id)
                            tagToDelete = nil
                        }
                    }
                }
            } message: {
                if let tag = tagToDelete {
                    Text("确定要删除标签「\(tag.name)」吗？")
                }
            }
        }
    }
}

struct DataExportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surface1.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "square.and.arrow.up.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.accent)

                    Text("导出数据")
                        .font(AppTypography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)

                    Text("将所有模板和标签导出为 JSON 文件")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)

                    Spacer()

                    Button {
                        exportData()
                    } label: {
                        Text("导出")
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                }
                .padding(AppSpacing.page)
            }
            .navigationTitle("数据导出")
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

    func exportData() {
        // TODO: Implement export functionality
        dismiss()
    }
}

// Placeholder views
struct LanguageSettingsView: View {
    var body: some View {
        ZStack {
            Color.surface1.ignoresSafeArea()
            Text("语言设置")
                .foregroundColor(.textPrimary)
        }
        .navigationTitle("语言")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        ZStack {
            Color.surface1.ignoresSafeArea()
            Text("外观设置")
                .foregroundColor(.textPrimary)
        }
        .navigationTitle("外观")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        ZStack {
            Color.surface1.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "app.badge")
                    .font(.system(size: 80))
                    .foregroundColor(.accent)

                AppWordmark()

                Text("版本 1.0.0")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ZStack {
            Color.surface1.ignoresSafeArea()
            Text("隐私政策")
                .foregroundColor(.textPrimary)
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ZStack {
            Color.surface1.ignoresSafeArea()
            Text("服务条款")
                .foregroundColor(.textPrimary)
        }
        .navigationTitle("服务条款")
        .navigationBarTitleDisplayMode(.inline)
    }
}
