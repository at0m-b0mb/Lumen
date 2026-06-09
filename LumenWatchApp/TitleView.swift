import SwiftUI

struct TitleView: View {
    @EnvironmentObject private var game: LumenGame

    var body: some View {
        VStack(spacing: 5) {
            LogoGlyph()
                .padding(.bottom, 4)

            Text("LUMEN")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("light up the grid")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            if game.totalStars > 0 {
                Label("\(game.totalStars) / \(game.maxStars)", systemImage: "star.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.star)
                    .padding(.top, 3)
            }

            Button {
                Haptic.uiTap()
                game.showLevels()
            } label: {
                Text("PLAY")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.glow(1))
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
    }
}
