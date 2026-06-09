import SwiftUI

/// Centralised palette. Each world has a signature glow colour so progress
/// feels like moving through distinct "biomes" of light.
enum Theme {
    static let bgTop    = Color(.sRGB, red: 0.07, green: 0.08, blue: 0.13, opacity: 1)
    static let bgBottom = Color(.sRGB, red: 0.02, green: 0.02, blue: 0.05, opacity: 1)
    static let star     = Color(.sRGB, red: 1.00, green: 0.82, blue: 0.25, opacity: 1)
    static let unlit    = Color(.sRGB, red: 0.13, green: 0.15, blue: 0.22, opacity: 1)
    static let unlitStroke = Color(.sRGB, red: 0.26, green: 0.30, blue: 0.40, opacity: 1)

    static func glow(_ world: Int) -> Color {
        switch world % 4 {
        case 0:  return Color(.sRGB, red: 1.00, green: 0.72, blue: 0.22, opacity: 1) // amber
        case 1:  return Color(.sRGB, red: 0.20, green: 0.85, blue: 1.00, opacity: 1) // cyan
        case 2:  return Color(.sRGB, red: 1.00, green: 0.34, blue: 0.62, opacity: 1) // magenta
        default: return Color(.sRGB, red: 0.42, green: 0.95, blue: 0.55, opacity: 1) // green
        }
    }

    static var background: some View {
        LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

/// Small decorative 2×2 "lights" motif for the title screen.
struct LogoGlyph: View {
    private let lit = [true, true, false, true]
    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<2, id: \.self) { r in
                HStack(spacing: 5) {
                    ForEach(0..<2, id: \.self) { c in
                        let on = lit[r * 2 + c]
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(on ? Theme.glow(1) : Theme.unlit)
                            .frame(width: 24, height: 24)
                            .shadow(color: on ? Theme.glow(1).opacity(0.85) : .clear, radius: 7)
                    }
                }
            }
        }
    }
}
