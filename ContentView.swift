import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TemplateListView()
                .tabItem {
                    Label("提示词", systemImage: "doc.text")
                }
                .tag(0)

            QuickAccessView()
                .tabItem {
                    Label("快捷贴贴", systemImage: "keyboard")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(2)
        }
        .accentColor(Color(hex: "38BDF8"))
        .preferredColorScheme(.dark)
    }
}
