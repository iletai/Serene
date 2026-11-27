import SwiftUI

/// Motion tokens lifted from the prototype's CSS custom properties
/// (`--ease-card`, `--ease-cell`, `--ease-sheet`, `--ease-push`, `--dur-*`).
///
/// Use these curves for prototype-matched transitions; `VNAnimation` keeps the
/// interaction springs (press, selection, month paging) used across the app.
public enum VNMotion {
    public enum Duration {
        /// `--dur-cell`
        public static let cell: Double = 0.28
        /// `--dur-card`
        public static let card: Double = 0.35
        /// `--dur-sheet`
        public static let sheet: Double = 0.45
        /// `--dur-push`
        public static let push: Double = 0.38
        /// `.bloc` / `bloc-in`
        public static let rise: Double = 0.62
        /// `.carousel > *`
        public static let carouselRise: Double = 0.52
    }

    public enum Easing {
        /// `--ease-card`: cubic-bezier(.22, 1, .36, 1)
        public static let card = Animation.timingCurve(0.22, 1, 0.36, 1, duration: Duration.card)
        /// `--ease-sheet`: cubic-bezier(.22, 1, .36, 1)
        public static let sheet = Animation.timingCurve(0.22, 1, 0.36, 1, duration: Duration.sheet)
        /// `--ease-cell`: cubic-bezier(.3, 1.3, .5, 1) — a light overshoot.
        public static let cell = Animation.timingCurve(0.3, 1.3, 0.5, 1, duration: Duration.cell)
        /// `--ease-push`: cubic-bezier(.32, .72, 0, 1)
        public static let push = Animation.timingCurve(0.32, 0.72, 0, 1, duration: Duration.push)
    }

    /// Idle-loop periods from the prototype keyframes (full cycle, seconds).
    public enum Loop {
        public static let bob: Double = 3.6
        public static let sway: Double = 3.8
        public static let glow: Double = 3.6
        public static let moonGlow: Double = 4.2
        public static let crownShine: Double = 3.2
        public static let spinSlow: Double = 14
        public static let twinkle: Double = 4
        public static let swing: Double = 4.4
    }
}
