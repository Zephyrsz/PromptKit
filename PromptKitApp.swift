import SwiftUI

@main
struct PromptKitApp: App {
    @StateObject private var dataStore = DataStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
    }
}
