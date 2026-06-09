import Foundation

/// Solves Lights Out over GF(2). Each cell gives a linear equation
/// (sum of taps touching it ≡ "does it need to flip" mod 2); we reduce to
/// reduced row-echelon form, then enumerate the null space to find the
/// minimum-weight tap set — the true optimal solution / par.
enum LightsSolver {

    /// Minimum-weight set of tap indices that lights the whole board, or nil
    /// if the position is unsolvable (shouldn't happen for generated levels).
    static func optimalSolution(board: UInt32, rows: Int, cols: Int) -> [Int]? {
        let n = rows * cols
        var rowMask = [UInt32](repeating: 0, count: n)   // taps affecting cell i
        var rhs = [UInt8](repeating: 0, count: n)
        for r in 0..<rows {
            for c in 0..<cols {
                let i = r * cols + c
                rowMask[i] = Bits.toggleMask(r, c, rows: rows, cols: cols)
                rhs[i] = Bits.isSet(board, i) ? 0 : 1   // OFF cells must flip
            }
        }

        // Gauss–Jordan elimination over GF(2).
        var pivotCols: [Int] = []
        var top = 0
        for col in 0..<n {
            var sel = -1
            for rr in top..<n where (rowMask[rr] >> col) & 1 == 1 { sel = rr; break }
            if sel == -1 { continue }
            rowMask.swapAt(top, sel); rhs.swapAt(top, sel)
            for rr in 0..<n where rr != top && (rowMask[rr] >> col) & 1 == 1 {
                rowMask[rr] ^= rowMask[top]
                rhs[rr] ^= rhs[top]
            }
            pivotCols.append(col)
            top += 1
        }

        // Consistency: any all-zero row with rhs 1 ⇒ no solution.
        for rr in top..<n where rowMask[rr] == 0 && rhs[rr] == 1 { return nil }

        var isPivot = [Bool](repeating: false, count: n)
        for c in pivotCols { isPivot[c] = true }
        let freeCols = (0..<n).filter { !isPivot[$0] }

        func solution(freeAssign: UInt32) -> UInt32 {
            var x: UInt32 = 0
            for (k, fc) in freeCols.enumerated() where (freeAssign >> k) & 1 == 1 {
                x |= UInt32(1) << fc
            }
            for (pi, col) in pivotCols.enumerated() {
                var v = rhs[pi] & 1
                let freeBits = (rowMask[pi] & ~(UInt32(1) << col)) & x
                v ^= UInt8(freeBits.nonzeroBitCount & 1)
                if v == 1 { x |= UInt32(1) << col }
            }
            return x
        }

        let freeCount = freeCols.count
        let maxCombos = freeCount >= 20 ? (1 << 20) : (1 << freeCount)
        var best: UInt32 = 0
        var bestWeight = Int.max
        var assign = 0
        while assign < maxCombos {
            let x = solution(freeAssign: UInt32(assign))
            let w = x.nonzeroBitCount
            if w < bestWeight { bestWeight = w; best = x }
            assign += 1
        }

        return (0..<n).filter { (best >> $0) & 1 == 1 }
    }

    static func par(board: UInt32, rows: Int, cols: Int) -> Int {
        optimalSolution(board: board, rows: rows, cols: cols)?.count ?? 0
    }
}

/// Builds solvable boards with a controlled optimal-solution length.
enum LevelFactory {
    /// Deterministically produce a board whose par equals `targetPar`
    /// (or the closest achievable), by scrambling the solved board.
    static func makeBoard(rows: Int, cols: Int, targetPar: Int, seed: UInt64) -> (board: UInt32, par: Int) {
        let n = rows * cols
        var rng = SeededRNG(seed: seed)
        let full = Bits.full(n)
        var best: (board: UInt32, par: Int)?

        for _ in 0..<500 {
            var board = full
            var taps = Set<Int>()
            let k = max(1, min(targetPar, n))
            while taps.count < k { taps.insert(Int(rng.next() % UInt64(n))) }
            for t in taps {
                board ^= Bits.toggleMask(t / cols, t % cols, rows: rows, cols: cols)
            }
            if board == full { continue }   // already solved — skip
            let p = LightsSolver.par(board: board, rows: rows, cols: cols)
            if p == targetPar { return (board, p) }
            if best == nil || abs(p - targetPar) < abs(best!.par - targetPar) {
                best = (board, p)
            }
        }

        if let best { return best }
        let fallback = full ^ Bits.toggleMask(0, 0, rows: rows, cols: cols)
        return (fallback, LightsSolver.par(board: fallback, rows: rows, cols: cols))
    }
}
