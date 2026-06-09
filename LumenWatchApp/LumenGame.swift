import SwiftUI

/// The whole game: the level set, current puzzle state, progression and
/// persistence. Turn-based, so plain `@Published` state drives the SwiftUI
/// views directly (no per-frame loop).
@MainActor
final class LumenGame: ObservableObject {

    // Navigation / puzzle state
    @Published private(set) var phase: GamePhase = .title
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var board: UInt32 = 0
    @Published private(set) var moves: Int = 0
    @Published private(set) var hintCell: Int?
    @Published private(set) var won: Bool = false
    @Published private(set) var earnedStars: Int = 0
    @Published private(set) var justLitStars: Int = 0   // for staggered star reveal

    // Progression (persisted)
    @Published private(set) var stars: [Int] = []        // best stars per level id
    @Published private(set) var unlockedCount: Int = 1

    let worlds: [World]
    let levels: [Level]
    private var hintUsed = false

    private let starsKey = "Lumen.stars.v1"
    private let unlockedKey = "Lumen.unlocked.v1"

    var currentLevel: Level { levels[currentIndex] }
    var totalStars: Int { stars.reduce(0, +) }
    var maxStars: Int { levels.count * 3 }

    init() {
        // World definitions + per-level par schedules (40 levels, 4 worlds).
        let defs: [(World, [Int])] = [
            (World(name: "Spark",  rows: 3, cols: 3, count: 8),  [2, 2, 3, 3, 4, 4, 5, 5]),
            (World(name: "Glow",   rows: 4, cols: 4, count: 12), [3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8]),
            (World(name: "Beacon", rows: 5, cols: 5, count: 12), [4, 5, 5, 6, 6, 7, 7, 8, 9, 9, 10, 11]),
            (World(name: "Nova",   rows: 5, cols: 5, count: 8),  [8, 9, 10, 11, 12, 12, 13, 14]),
        ]
        var built: [Level] = []
        var gid = 0
        for (wi, def) in defs.enumerated() {
            for par in def.1 {
                let seed = 0xA11CE &+ UInt64(gid) &* 0x9E3779B1
                let made = LevelFactory.makeBoard(rows: def.0.rows, cols: def.0.cols,
                                                  targetPar: par, seed: seed)
                built.append(Level(id: gid, world: wi, rows: def.0.rows, cols: def.0.cols,
                                   start: made.board, par: made.par))
                gid += 1
            }
        }
        worlds = defs.map(\.0)
        levels = built

        if let saved = UserDefaults.standard.array(forKey: starsKey) as? [Int],
           saved.count == levels.count {
            stars = saved
        } else {
            stars = Array(repeating: 0, count: levels.count)
        }
        unlockedCount = max(1, UserDefaults.standard.integer(forKey: unlockedKey))

        #if DEBUG
        applyLaunchDemo()
        #endif
    }

    // MARK: Navigation

    func showLevels() { phase = .levelSelect }
    func showTitle()  { phase = .title }

    func isUnlocked(_ index: Int) -> Bool { index < unlockedCount }

    func play(index: Int) {
        guard levels.indices.contains(index) else { return }
        currentIndex = index
        board = levels[index].start
        moves = 0
        hintCell = nil
        hintUsed = false
        won = false
        earnedStars = 0
        justLitStars = 0
        phase = .playing
    }

    func replay() { play(index: currentIndex) }

    func nextLevel() {
        let n = currentIndex + 1
        if levels.indices.contains(n) && isUnlocked(n) { play(index: n) }
        else { phase = .levelSelect }
    }

    // MARK: Gameplay

    func tap(row: Int, col: Int) {
        guard phase == .playing, !won else { return }
        let lvl = currentLevel
        board ^= Bits.toggleMask(row, col, rows: lvl.rows, cols: lvl.cols)
        moves += 1
        if let h = hintCell, h == row * lvl.cols + col { hintCell = nil }
        Haptic.tapLight()

        if board == Bits.full(lvl.cellCount) { finishLevel() }
    }

    func reset() {
        board = currentLevel.start
        moves = 0
        hintCell = nil
        hintUsed = false
        won = false
        Haptic.uiTap()
    }

    /// Reveal one tap from an optimal solution for the current board.
    /// Forfeits the 3rd star for this attempt.
    func useHint() {
        guard phase == .playing, !won else { return }
        let lvl = currentLevel
        guard let sol = LightsSolver.optimalSolution(board: board, rows: lvl.rows, cols: lvl.cols),
              let pick = sol.first else { return }
        hintCell = pick
        hintUsed = true
        Haptic.hint()
    }

    private func finishLevel() {
        var s = moves <= currentLevel.par ? 3 : (moves <= currentLevel.par + 2 ? 2 : 1)
        if hintUsed { s = min(s, 2) }
        earnedStars = s

        if s > stars[currentIndex] {
            stars[currentIndex] = s
            UserDefaults.standard.set(stars, forKey: starsKey)
        }
        let unlockTo = min(levels.count, currentIndex + 2)
        if unlockTo > unlockedCount {
            unlockedCount = unlockTo
            UserDefaults.standard.set(unlockedCount, forKey: unlockedKey)
        }

        won = true
        Haptic.win()
        revealStars(upTo: s)
    }

    /// Light the earned stars one-by-one with a little haptic each.
    private func revealStars(upTo s: Int) {
        justLitStars = 0
        for i in 1...max(1, s) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + 0.28 * Double(i)) { [weak self] in
                guard let self, self.won, i <= self.earnedStars else { return }
                self.justLitStars = i
                Haptic.star()
            }
        }
    }
}

#if DEBUG
extension LumenGame {
    /// Jump straight to a state for screenshots/QA. Activated only by the
    /// `LUMEN_DEMO` launch environment variable; compiled out of Release.
    func applyLaunchDemo() {
        guard let mode = ProcessInfo.processInfo.environment["LUMEN_DEMO"] else { return }
        switch mode {
        case "levels":
            unlockedCount = 15
            let pattern = [3, 2, 3, 3, 2, 3, 1, 2, 3, 2, 3, 1, 2]
            for i in 0..<min(pattern.count, stars.count) { stars[i] = pattern[i] }
            phase = .levelSelect
        case "play":
            unlockedCount = max(unlockedCount, 26)
            play(index: 25)          // a 5×5 Beacon level
        case "hint":
            unlockedCount = max(unlockedCount, 26)
            play(index: 25)
            useHint()
        case "win":
            unlockedCount = max(unlockedCount, 20)
            play(index: 9)
            moves = currentLevel.par  // a genuine "perfect"
            earnedStars = 3
            justLitStars = 3
            won = true
        default:
            break
        }
    }
}
#endif
