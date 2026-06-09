import SwiftUI

struct GameView: View {
    @EnvironmentObject private var game: LumenGame

    var body: some View {
        let lvl = game.currentLevel
        let glow = Theme.glow(lvl.world)
        ZStack {
            VStack(spacing: 4) {
                topBar
                boardArea(lvl, glow)
                bottomBar
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 4)

            if game.won {
                WinOverlay().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: game.won)
    }

    private var topBar: some View {
        HStack {
            Button { Haptic.uiTap(); game.showLevels() } label: {
                Image(systemName: "chevron.left").font(.system(size: 15, weight: .bold))
            }
            .buttonStyle(.plain)
            Spacer()
            Text("LEVEL \(game.currentIndex + 1)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.left").font(.system(size: 15, weight: .bold)).opacity(0)
        }
    }

    private func boardArea(_ lvl: Level, _ glow: Color) -> some View {
        GeometryReader { geo in
            let spacing: CGFloat = lvl.cols >= 5 ? 5 : 7
            let side = min(geo.size.width, geo.size.height)
            let tile = (side - spacing * CGFloat(lvl.cols - 1)) / CGFloat(lvl.cols)
            VStack(spacing: spacing) {
                ForEach(0..<lvl.rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<lvl.cols, id: \.self) { c in
                            let i = r * lvl.cols + c
                            Tile(lit: Bits.isSet(game.board, i),
                                 color: glow,
                                 hinted: game.hintCell == i,
                                 size: tile) {
                                game.tap(row: r, col: c)
                            }
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Button { game.reset() } label: {
                Image(systemName: "arrow.counterclockwise").font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.8))

            Spacer()
            VStack(spacing: 0) {
                Text("\(game.moves)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("par \(game.currentLevel.par)")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()

            Button { game.useHint() } label: {
                Image(systemName: "lightbulb.fill").font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.star.opacity(0.9))
        }
        .padding(.horizontal, 4)
    }
}

private struct Tile: View {
    let lit: Bool
    let color: Color
    let hinted: Bool
    let size: CGFloat
    let onTap: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(lit ? color : Theme.unlit)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .strokeBorder(lit ? Color.white.opacity(0.25) : Theme.unlitStroke, lineWidth: 1)
                )
                .overlay {
                    if lit {
                        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                            .fill(LinearGradient(colors: [Color.white.opacity(0.35), .clear],
                                                 startPoint: .topLeading, endPoint: .center))
                    }
                }
                .overlay {
                    if hinted {
                        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                            .strokeBorder(Theme.star, lineWidth: 2.5)
                            .opacity(pulse ? 0.35 : 1)
                    }
                }
                .frame(width: size, height: size)
                .shadow(color: lit ? color.opacity(0.8) : .clear, radius: lit ? size * 0.3 : 0)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.14), value: lit)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

private struct WinOverlay: View {
    @EnvironmentObject private var game: LumenGame

    var body: some View {
        ZStack {
            Color.black.opacity(0.74).ignoresSafeArea()
            VStack(spacing: 6) {
                Text(game.earnedStars >= 3 ? "PERFECT!" : "SOLVED")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(game.earnedStars >= 3 ? Theme.star : .white)

                HStack(spacing: 7) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= game.justLitStars ? "star.fill" : "star")
                            .font(.system(size: i == 2 ? 28 : 23, weight: .bold))
                            .foregroundStyle(i <= game.justLitStars ? Theme.star : .white.opacity(0.3))
                            .scaleEffect(i <= game.justLitStars ? 1.0 : 0.7)
                            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: game.justLitStars)
                    }
                }
                .padding(.vertical, 2)

                Text("\(game.moves) moves · par \(game.currentLevel.par)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 8) {
                    Button { Haptic.uiTap(); game.showLevels() } label: {
                        Image(systemName: "square.grid.2x2.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button { Haptic.uiTap(); game.replay() } label: {
                        Image(systemName: "arrow.counterclockwise").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button { Haptic.uiTap(); game.nextLevel() } label: {
                        Image(systemName: "arrow.right").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.glow(game.currentLevel.world))
                }
                .font(.system(size: 14, weight: .bold))
                .padding(.top, 4)
            }
            .padding(.horizontal, 14)
        }
    }
}
