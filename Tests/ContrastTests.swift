import XCTest
import VNCalendarDesignSystem

final class ContrastTests: XCTestCase {
    private func lum(_ hex: UInt32) -> Double {
        func ch(_ v: UInt32) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * ch((hex >> 16) & 0xFF) + 0.7152 * ch((hex >> 8) & 0xFF) + 0.0722 * ch(hex & 0xFF)
    }
    private func ratio(_ a: UInt32, _ b: UInt32) -> Double {
        let (x, y) = (lum(a), lum(b))
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }

    func testBodyTextMeetsAAOnAllBackgrounds() {
        for useDark in [false, true] {
            let bgs = [VNPalette.backgroundPrimary, VNPalette.backgroundSecondary, VNPalette.backgroundTertiary]
            let texts = [VNPalette.textPrimary, VNPalette.textSecondary]
            for bg in bgs { for t in texts {
                XCTAssertGreaterThanOrEqual(ratio(useDark ? t.dark : t.light, useDark ? bg.dark : bg.light), 4.5)
            } }
        }
    }

    func testTertiaryTextAndAccentsOnPrimary() {
        for useDark in [false, true] {
            let bg = useDark ? VNPalette.backgroundPrimary.dark : VNPalette.backgroundPrimary.light
            for token in [VNPalette.textTertiary, VNPalette.accentHeritageRed, VNPalette.accentJade] {
                XCTAssertGreaterThanOrEqual(ratio(useDark ? token.dark : token.light, bg), 4.5)
            }
        }
    }

    func testOnAccentAgainstRedAndJade() {
        for useDark in [false, true] {
            let on = useDark ? VNPalette.onAccent.dark : VNPalette.onAccent.light
            for fill in [VNPalette.accentHeritageRed, VNPalette.accentJade] {
                XCTAssertGreaterThanOrEqual(ratio(on, useDark ? fill.dark : fill.light), 4.5)
            }
        }
    }
}
