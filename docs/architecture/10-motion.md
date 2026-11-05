# 10 - Motion

Source of truth: `Packages/VNCalendarDesignSystem/Sources/VNCalendarDesignSystem/Tokens/AnimationTokens.swift`
and `Modifiers/VNMotion.swift`, `VNCellPressButtonStyle.swift`, `VNHaptics.swift`.

## Tokens (`VNAnimation`)

| Token | Value | Use for |
|---|---|---|
| `pressDown` | easeOut 0.12s | finger down (instant, no bounce) |
| `press` | snappy 0.25s, bounce 0.15 | release settle after a tap |
| `selection` | snappy 0.25s | focus, toggle, selected state, small text swaps |
| `layout` | smooth 0.3s | insert/remove/reorder, counters (`numericText`) |
| `appear` | smooth 0.4s | entrance fade + slide (`vnAppear`) |
| `expand` | snappy 0.35s, bounce 0.08 | expand/collapse of cards and sections |
| `reduced` | easeOut 0.15s | automatic Reduce Motion fallback, do not use directly |
| `monthTransition`, `cellSelection`, `sheetSpring`, `cardExpansion` | legacy | calendar grid / sheets, names kept |

## Rules

1. Durations stay within 0.2-0.45s (except `pressDown`, which must feel instant). No bounce above 0.15.
2. Never write raw `.animation(...)` / `withAnimation` with ad-hoc numbers in features. Use a token via `vnAnimation(_:value:)`.
3. Press feedback: `.buttonStyle(.vnPress)` (cells), `.vnPress(scale: 0.98)` (cards), `.vnRowPress` (list rows), `VNButton` (built in).
4. Haptics only through `VNHaptics` / `vnSelectionFeedback` / `vnImpactFeedback` / `vnSuccessFeedback`. All honor the `hapticFeedbackEnabled` setting. One haptic per user action.
5. No animation inside scroll-heavy lists (year grid, month cells, long reminder lists): no `vnAppear`, no per-row `.animation`. Press feedback is fine.
6. `vnAppear(delay:)` only for small static groups (headers, empty states). Stagger with `Double(index) * 0.05`, max 4-5 items.
7. Reduce Motion is mandatory: `vnAnimation`, `vnAppear`, `vnTransition` and the press styles degrade automatically (opacity only, 0.15s, no movement or scale). Any custom animation must read `\.accessibilityReduceMotion`.
8. Animate state, not frames: prefer `contentTransition(.numericText())` / `.opacity` and `symbolEffect` over manual keyframes. Reach for `PhaseAnimator` / `KeyframeAnimator` only for one-off celebratory moments.
