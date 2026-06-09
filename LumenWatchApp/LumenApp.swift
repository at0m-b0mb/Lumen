import SwiftUI

@main
struct LumenApp: App {
    @StateObject private var game = LumenGame()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
        }
    }
}
