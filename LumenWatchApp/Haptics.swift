import WatchKit

/// Taptic Engine feedback, addressed by intent so the whole game's feel lives
/// in one place.
enum Haptic {
    private static func play(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }

    static func tapLight() { play(.click) }
    static func win()      { play(.success) }
    static func star()     { play(.notification) }
    static func uiTap()    { play(.click) }
    static func locked()   { play(.failure) }
    static func hint()     { play(.directionUp) }
}
