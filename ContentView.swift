import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingCreateMenu = false
    @State private var showingCreateSheet = false
    @State private var createKind: PromptKind = .note

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                TemplateListView()
                    .tabItem { Label("home", systemImage: "house.fill") }
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)
                QuickAccessView()
                    .tabItem { Label("个人收藏", systemImage: "star.fill") }
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)
                SettingsView()
                    .tabItem { Label("设置", systemImage: "gearshape.fill") }
                    .tag(2)
                    .toolbar(.hidden, for: .tabBar)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
        .background(Color.surface1.ignoresSafeArea())
        .font(AppTypography.body)
        .tint(.accent)
        .preferredColorScheme(.dark)
        .confirmationDialog("新建内容", isPresented: $showingCreateMenu, titleVisibility: .visible) {
            Button("新建提示词笔记") {
                createKind = .note
                showingCreateSheet = true
            }
            .accessibilityIdentifier("prompt.create.note")
            Button("新建模板") {
                createKind = .template
                showingCreateSheet = true
            }
            .accessibilityIdentifier("prompt.create.template")
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $showingCreateSheet) {
            EditPromptView(prompt: nil, initialKind: createKind)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "home", symbol: "house.fill", tag: 0)
            tabButton(title: "个人收藏", symbol: "star.fill", tag: 1)
            tabButton(title: "设置", symbol: "gearshape.fill", tag: 2)

            Button {
                showingCreateMenu = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(.surface1)
                    .frame(width: 48, height: 48)
                    .background(Color.accent, in: Circle())
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("prompt.add")
            .accessibilityLabel("新建提示词")

        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .background {
            Color.surface3
                .overlay(alignment: .top) { Rectangle().fill(Color.outline).frame(height: 1) }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tabButton(title: String, symbol: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .frame(height: 22)
                Text(title)
                    .font(.system(.caption2, design: .default).weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(selectedTab == tag ? .accent : .textSecondary)
            .frame(maxWidth: .infinity, minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("navigation.\(tag)")
        .accessibilityLabel(title)
        .accessibilityAddTraits(selectedTab == tag ? .isSelected : [])
        .accessibilityShowsLargeContentViewer {
            Label(title, systemImage: symbol)
        }
    }
}
