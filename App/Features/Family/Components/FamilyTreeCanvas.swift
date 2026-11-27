import SwiftUI
import VNCalendarDomain
import VNCalendarDesignSystem

/// Pannable, zoomable genealogy canvas on the night backdrop (prototype `.tree-canvas`).
///
/// Panning is the native 2D `ScrollView`; zoom is applied to layout (not just rendering) so
/// `scrollTo` targets stay correct. Positions come from the pure `FamilyTreeLayout`.
struct FamilyTreeCanvas: View {
    let groups: [FamilyMemberGroup]
    let layout: FamilyTreeLayout
    let emphasis: (ReminderEvent) -> FamilyTreeNodeView.Emphasis
    let info: (ReminderEvent) -> FamilyMemberInfo
    /// Member to centre on; changes re-centre the canvas.
    let focusMemberID: UUID?
    /// Target of the "back to next memorial" control.
    let homeMemberID: UUID?
    let onSelect: (ReminderEvent) -> Void

    static let height: CGFloat = 540
    private static let initialScale: CGFloat = 0.72
    private static let zoomStep: CGFloat = 1.25

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = FamilyTreeCanvas.initialScale
    @State private var pinchStartScale: CGFloat?
    @State private var viewport = CGSize(width: 0, height: FamilyTreeCanvas.height)
    @State private var lastFocusID: UUID?

    private var placed: [(member: ReminderEvent, node: FamilyTreeLayout.Node)] {
        Array(zip(groups.flatMap(\.members), layout.nodes)).map { (member: $0, node: $1) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                content
            }
            .defaultScrollAnchor(.center)
            .simultaneousGesture(pinch)
            .overlay(alignment: .bottomLeading) { legend }
            .overlay(alignment: .bottomTrailing) { zoomControls(proxy) }
            .onGeometryChangeCompat { viewport = $0 }
            .task { await centerOnFocus(proxy, animated: false) }
            .onChange(of: focusMemberID) { _, _ in
                Task { await centerOnFocus(proxy, animated: true) }
            }
        }
        .frame(height: Self.height)
        .background(canvasBackground)
        .clipShape(RoundedRectangle(cornerRadius: VNCornerRadius.sheet))
        .overlay(
            RoundedRectangle(cornerRadius: VNCornerRadius.sheet)
                .strokeBorder(Color.vnAccentImperialGold.opacity(0.22), lineWidth: VNBorderWidth.hairline)
        )
        .shadow(color: VNShadow.floating.color, radius: VNShadow.floating.radius, x: 0, y: VNShadow.floating.y)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Content

    private var content: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<layout.generationCount, id: \.self) { generation in
                generationBand(generation)
            }
            FamilyTreeTrunk(edges: layout.edges, scale: scale)
                .stroke(Color.vnAccentImperialGold.opacity(0.8), style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round))
                .accessibilityHidden(true)
            ForEach(Array(placed.enumerated()), id: \.element.member.id) { index, item in
                nodeView(item.member, node: item.node, index: index)
            }
        }
        .frame(width: layout.size.width * scale, height: layout.size.height * scale, alignment: .topLeading)
    }

    private func nodeView(_ member: ReminderEvent, node: FamilyTreeLayout.Node, index: Int) -> some View {
        let size = FamilyTreeLayout.nodeSize
        return FamilyTreeNodeView(
            member: member,
            info: info(member),
            emphasis: emphasis(member),
            riseIndex: index
        ) { onSelect(member) }
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: size.width * scale, height: size.height * scale, alignment: .topLeading)
        .id(member.id)
        .padding(.leading, node.origin.x * scale)
        .padding(.top, node.origin.y * scale)
    }

    private func generationBand(_ generation: Int) -> some View {
        let tint = generation.isMultiple(of: 2) ? Color.vnOnNight : Color.vnAccentImperialGold
        let rowY = FamilyTreeLayout.rowY(generation)
        let bandWidth = max(0, layout.size.width - 48) * scale
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 26 * scale)
                .fill(LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: tint.opacity(0.06), location: 0.14),
                        .init(color: tint.opacity(0.06), location: 0.86),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(width: bandWidth, height: (FamilyTreeLayout.nodeSize.height + 36) * scale)
                .padding(.leading, 24 * scale)
                .padding(.top, (rowY - 18) * scale)
            Text(groups[generation].generationRank)
                .font(.vnDisplay(.caption2, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.vnAccentImperialGold.opacity(0.7))
                .fixedSize()
                .scaleEffect(scale)
                .rotationEffect(.degrees(-90))
                .frame(width: 14 * scale, height: 90 * scale)
                .padding(.leading, 14 * scale)
                .padding(.top, (rowY + FamilyTreeLayout.nodeSize.height / 2 - 45) * scale)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Chrome

    private var canvasBackground: some View {
        Color.vnNight
            .overlay(Image("Pattern/pattern-wave-tree").resizable(resizingMode: .tile).opacity(0.9))
            .overlay(LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .top, endPoint: .bottom))
    }

    private var legend: some View {
        HStack(spacing: VNSpacing.md - 2) {
            legendItem(String(localized: "family.legend.deceased")) {
                Circle().strokeBorder(Color.vnAccentImperialGold, lineWidth: 2)
            }
            legendItem(String(localized: "family.legend.living")) {
                Circle().fill(Color.vnAccentSky)
            }
        }
        .padding(.horizontal, VNSpacing.md)
        .padding(.vertical, VNSpacing.sm - 2)
        .background(.ultraThinMaterial, in: Capsule())
        .environment(\.colorScheme, .dark)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(VNSpacing.md)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func legendItem<Mark: View>(_ title: String, @ViewBuilder mark: () -> Mark) -> some View {
        HStack(spacing: 5) {
            mark().frame(width: 10, height: 10)
            Text(title).font(.vnDisplay(.caption2, weight: .semibold)).foregroundColor(.vnOnNight.opacity(0.86))
        }
    }

    private func zoomControls(_ proxy: ScrollViewProxy) -> some View {
        VStack(spacing: VNSpacing.sm - 2) {
            zoomButton("plus", "family.zoom.in") { zoom(by: Self.zoomStep, proxy) }
            zoomButton("minus", "family.zoom.out") { zoom(by: 1 / Self.zoomStep, proxy) }
            zoomButton("arrow.up.left.and.arrow.down.right", "family.zoom.fit") {
                setScale(layout.fitScale(in: viewport))
            }
            zoomButton("scope", "family.zoom.next") {
                lastFocusID = homeMemberID
                Task { await centerOnFocus(proxy, animated: true, id: homeMemberID) }
            }
        }
        .padding(VNSpacing.sm + 2)
    }

    private func zoomButton(_ symbol: String, _ label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundColor(.vnOnNight)
                .frame(width: VNSize.minTapTarget, height: VNSize.minTapTarget)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .environment(\.colorScheme, .dark)
        }
        .buttonStyle(.vnPress)
        .accessibilityLabel(label)
    }

    // MARK: - Zoom & scroll

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let base = pinchStartScale ?? scale
                pinchStartScale = base
                scale = FamilyTreeLayout.clamped(base * value.magnification)
            }
            .onEnded { _ in pinchStartScale = nil }
    }

    private func setScale(_ newScale: CGFloat) {
        withAnimation(reduceMotion ? nil : VNMotion.Easing.card) { scale = FamilyTreeLayout.clamped(newScale) }
    }

    private func zoom(by factor: CGFloat, _ proxy: ScrollViewProxy) {
        setScale(scale * factor)
        // Layout grows from the top-left, so re-centre on the last focused person to keep the view stable.
        Task { await centerOnFocus(proxy, animated: false, id: lastFocusID) }
    }

    private func centerOnFocus(_ proxy: ScrollViewProxy, animated: Bool, id: UUID? = nil) async {
        guard let target = id ?? focusMemberID else { return }
        lastFocusID = target
        // Let the freshly laid-out nodes exist before scrolling to them.
        await Task.yield()
        withAnimation(animated && !reduceMotion ? VNMotion.Easing.card : nil) {
            proxy.scrollTo(target, anchor: .center)
        }
    }
}

/// Straight trunk segments joining consecutive generations (rows share one centre line).
private struct FamilyTreeTrunk: Shape {
    let edges: [FamilyTreeLayout.Edge]
    var scale: CGFloat

    var animatableData: CGFloat {
        get { scale }
        set { scale = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            path.move(to: CGPoint(x: edge.start.x * scale, y: edge.start.y * scale))
            path.addLine(to: CGPoint(x: edge.end.x * scale, y: edge.end.y * scale))
        }
        return path
    }
}

private extension View {
    /// `onGeometryChange` is iOS 18; this container is iOS 17+, so measure with a background reader.
    func onGeometryChangeCompat(_ update: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.onAppear { update(proxy.size) }.onChange(of: proxy.size) { _, size in update(size) }
            }
        )
    }
}
