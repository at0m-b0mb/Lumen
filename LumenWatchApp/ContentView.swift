import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var game: LumenGame

    var body: some View {
        ZStack {
            Theme.background
            switch game.phase {
            case .title:       TitleView()
            case .levelSelect: LevelSelectView()
            case .playing:     GameView()
            }
        }
    }
}
