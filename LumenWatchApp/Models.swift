import Foundation

enum GamePhase {
    case title
    case levelSelect
    case playing
}

/// One puzzle. The board is a 32-bit mask (bit `row*cols + col`), `1` = lit.
/// The goal is to light **every** cell. `par` is the provably-minimum number
/// of taps to do so, used for star scoring and hints.
struct Level: Identifiable {
    let id: Int        // global 0-based index
    let world: Int     // 0-based world index
    let rows: Int
    let cols: Int
    let start: UInt32  // initially-lit cells
    let par: Int
    var cellCount: Int { rows * cols }
}

struct World {
    let name: String
    let rows: Int
    let cols: Int
    let count: Int
}

/// Deterministic RNG (SplitMix64) so generated levels are identical every launch.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Bit helpers for boards (bit index = row*cols + col).
enum Bits {
    @inline(__always) static func index(_ r: Int, _ c: Int, cols: Int) -> Int { r * cols + c }
    @inline(__always) static func isSet(_ mask: UInt32, _ i: Int) -> Bool { (mask >> i) & 1 == 1 }
    @inline(__always) static func full(_ count: Int) -> UInt32 {
        count >= 32 ? .max : (UInt32(1) << count) - 1
    }

    /// Cells a tap at (r,c) toggles: itself + orthogonal neighbours.
    static func toggleMask(_ r: Int, _ c: Int, rows: Int, cols: Int) -> UInt32 {
        var m = UInt32(1) << index(r, c, cols: cols)
        if r > 0        { m |= UInt32(1) << index(r - 1, c, cols: cols) }
        if r < rows - 1 { m |= UInt32(1) << index(r + 1, c, cols: cols) }
        if c > 0        { m |= UInt32(1) << index(r, c - 1, cols: cols) }
        if c < cols - 1 { m |= UInt32(1) << index(r, c + 1, cols: cols) }
        return m
    }
}
