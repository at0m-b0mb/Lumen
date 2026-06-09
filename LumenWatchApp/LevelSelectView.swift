import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject private var game: LumenGame

    private let columns = [GridItem(.adaptive(minimum: 44, maximum: 58), spacing: 7)]

    private var worldStart: [Int] {
        var starts: [Int] = []
        var acc = 0
        for w in game.worlds { starts.append(acc); acc += w.count }
        return starts
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                ForEach(Array(game.worlds.enumerated()), id: \.offset) { wi, world in
                    section(worldIndex: wi, world: world, start: worldStart[wi])
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private var header: some View {
        HStack {
            Button { Haptic.uiTap(); game.showTitle() } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold))
            }
            .buttonStyle(.plain)
            Spacer()
            Label("\(game.totalStars)", systemImage: "star.fill")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.star)
        }
    }

    private func section(worldIndex: Int, world: World, start: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(Theme.glow(worldIndex)).frame(width: 8, height: 8)
                Text(world.name.uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(world.rows)×\(world.cols)")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(0..<world.count, id: \.self) { i in
                    LevelChip(index: start + i, label: i + 1)
                }
            }
        }
    }
}

private struct LevelChip: View {
    @EnvironmentObject private var game: LumenGame
    let index: Int
    let label: Int

    var body: some View {
        let unlocked = game.isUnlocked(index)
        let s = game.stars[index]
        let world = game.levels[index].world
        Button {
            if unlocked { Haptic.uiTap(); game.play(index: index) }
            else { Haptic.locked() }
        } label: {
            VStack(spacing: 3) {
                if unlocked {
                    Text("\(label)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    HStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { k in
                            Image(systemName: k < s ? "star.fill" : "star")
                                .font(.system(size: 6))
                                .foregroundStyle(k < s ? Theme.star : .white.opacity(0.25))
                        }
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(height: 22)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(unlocked ? Theme.glow(world).opacity(0.16) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(unlocked ? Theme.glow(world).opacity(0.6) : Color.white.opacity(0.08),
                                  lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
