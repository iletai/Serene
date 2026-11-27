import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

/// One person card on the genealogy canvas (prototype `.fnode`). Always rendered on the night canvas,
/// so it uses night-ink colours in both appearances.
struct FamilyTreeNodeView: View {
    enum Emphasis: Equatable {
        case normal, highlighted, dimmed
    }

    let member: ReminderEvent
    let info: FamilyMemberInfo
    let emphasis: Emphasis
    let riseIndex: Int
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accessibilityText: String {
        var parts = [member.relationship ?? "", member.title].filter { !$0.isEmpty }
        if let year = FamilyMemberInfo.yearText(member) { parts.append(year) }
        if info.isWorshipped {
            parts.append("\(FamilyMemberInfo.anniversaryText(member)), \(info.countdownText)")
        } else {
            parts.append(String(localized: "family.status_living"))
        }
        return parts.joined(separator: ". ")
    }

    var body: some View {
        Button(action: action) {
            card
        }
        .buttonStyle(.plain)
        .opacity(emphasis == .dimmed ? 0.32 : 1)
        .scaleEffect(emphasis == .highlighted && !reduceMotion ? 1.05 : 1)
        .offset(y: emphasis == .highlighted && !reduceMotion ? -4 : 0)
        .vnAnimation(VNMotion.Easing.card, value: emphasis)
        .vnRise(index: min(riseIndex, 8), stagger: 0.05)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(String(localized: "family.a11y_open_profile"))
        .accessibilityAddTraits(.isButton)
    }

    private var card: some View {
        VStack(spacing: VNSpacing.space2 + 1) {
            avatar
            if let relationship = member.relationship, !relationship.isEmpty {
                Text(relationship.uppercased())
                    .font(.vnDisplay(.caption2, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(.vnAccentImperialGold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(member.title)
                .font(.vnDisplay(.footnote, weight: .semibold))
                .foregroundColor(.vnOnNight)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if let year = FamilyMemberInfo.yearText(member) {
                Text(year)
                    .font(.vnDisplay(.caption2, weight: .medium))
                    .foregroundColor(.vnOnNight.opacity(0.72))
            }
            if info.isWorshipped {
                memorialLines
            } else {
                Text("family.status_living")
                    .font(.vnDisplay(.caption2, weight: .semibold))
                    .foregroundColor(.vnOnNight.opacity(0.85))
                    .padding(.top, VNSpacing.xs)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.large) // fixed-size canvas card: users zoom the canvas instead
        .padding(.horizontal, VNSpacing.sm)
        .padding(.top, VNSpacing.md)
        .padding(.bottom, VNSpacing.sm + 2)
        .frame(width: FamilyTreeLayout.nodeSize.width, height: FamilyTreeLayout.nodeSize.height, alignment: .top)
        .background(background)
        .overlay(border)
        .shadow(color: .black.opacity(emphasis == .highlighted ? 0 : 0.32), radius: 13, y: 12)
        .shadow(color: Color.vnAccentImperialGold.opacity(emphasis == .highlighted ? 0.6 : 0), radius: 14)
    }

    private var memorialLines: some View {
        VStack(spacing: VNSpacing.space2 + 1) {
            HStack(spacing: VNSpacing.xs) {
                Image(systemName: "moon.stars.fill").accessibilityHidden(true)
                Text(FamilyMemberInfo.anniversaryText(member))
            }
            .font(.vnDisplay(.caption2, weight: .bold))
            .foregroundColor(.vnAccentImperialGold)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text(info.countdownText)
                .font(.vnDisplay(.caption2, weight: .semibold))
                .foregroundColor(info.isSoon ? .vnNight : .vnOnNight.opacity(0.86))
                .padding(.horizontal, VNSpacing.sm)
                .padding(.vertical, 1)
                .background(info.isSoon ? Color.vnAccentImperialGold : Color.vnOnNight.opacity(0.12), in: Capsule())
        }
    }

    private var avatar: some View {
        let dead = info.isWorshipped
        return Text(FamilyMemberInfo.initial(of: member.title))
            .font(.vnDisplay(.title3, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(
                LinearGradient(
                    colors: [.vnAccentSky, .vnAccentSky.opacity(0.65)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: Circle()
            )
            .overlay(
                Circle().strokeBorder(dead ? Color.vnAccentImperialGold.opacity(0.6) : Color.vnOnNight.opacity(0.18), lineWidth: 3)
            )
            .saturation(dead ? 0.6 : 1)
            .overlay(alignment: .bottomTrailing) {
                if dead { FamilyIncenseBadge().offset(x: 6, y: 4) }
            }
            .padding(.bottom, VNSpacing.xs)
            .accessibilityHidden(true)
    }

    private var background: some View {
        let tint = info.isWorshipped ? Color.vnAccentImperialGold : Color.vnOnNight
        return RoundedRectangle(cornerRadius: VNCornerRadius.card)
            .fill(LinearGradient(
                colors: [tint.opacity(info.isWorshipped ? 0.18 : 0.15), tint.opacity(0.05)],
                startPoint: .top, endPoint: .bottom
            ))
    }

    private var border: some View {
        let highlighted = emphasis == .highlighted
        let color: Color = highlighted
            ? .vnAccentImperialGold
            : (info.isWorshipped ? Color.vnAccentImperialGold.opacity(0.5) : Color.vnOnNight.opacity(0.2))
        return RoundedRectangle(cornerRadius: VNCornerRadius.card)
            .strokeBorder(color, lineWidth: highlighted ? VNBorderWidth.active : VNBorderWidth.hairline)
    }
}

/// Tiny incense burner on a memorial avatar (prototype `.fn-incense`): a lit stick with looping smoke.
struct FamilyIncenseBadge: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.vnNight)
            Circle().strokeBorder(Color.vnAccentImperialGold, lineWidth: VNBorderWidth.regular)
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.vnOnNight.opacity(0.7))
                    .frame(width: 1.5, height: 5)
                    .vnSmoke()
                Capsule().fill(Color.vnAccentHeritageRed).frame(width: 2, height: 2)
                Capsule().fill(Color.vnAccentImperialGold).frame(width: 2, height: 8)
            }
            .offset(y: -1)
        }
        .frame(width: 20, height: 20)
        .accessibilityHidden(true)
    }
}
