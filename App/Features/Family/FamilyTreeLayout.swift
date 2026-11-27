import CoreGraphics

/// Pure geometry for the genealogy canvas (prototype `layoutTree`).
///
/// Reminders carry no parent/spouse links, so the tree is one row per generation, rows are
/// centred on the widest row and a single trunk joins consecutive generations.
struct FamilyTreeLayout: Equatable, Sendable {
    struct Node: Equatable, Sendable {
        let generation: Int
        let index: Int
        /// Top-left corner in unscaled canvas coordinates.
        let origin: CGPoint
    }

    struct Edge: Equatable, Sendable {
        let start: CGPoint
        let end: CGPoint
    }

    static let nodeSize = CGSize(width: 132, height: 176)
    static let columnGap: CGFloat = 22
    static let rowPitch: CGFloat = 236
    static let padding = CGSize(width: 56, height: 36)
    static let scaleRange: ClosedRange<CGFloat> = 0.32...1.6

    let generationCount: Int
    let nodes: [Node]
    let edges: [Edge]
    let size: CGSize

    /// `memberCounts[g]` is the number of people in generation `g`; empty generations are skipped by callers.
    init(memberCounts: [Int]) {
        let node = Self.nodeSize
        let widest = memberCounts.map(Self.rowWidth(for:)).max() ?? 0
        let width = widest + Self.padding.width * 2
        var nodes: [Node] = []
        for (generation, count) in memberCounts.enumerated() {
            let startX = (width - Self.rowWidth(for: count)) / 2
            let originY = Self.rowY(generation)
            for index in 0..<count {
                let originX = startX + CGFloat(index) * (node.width + Self.columnGap)
                nodes.append(Node(generation: generation, index: index, origin: CGPoint(x: originX, y: originY)))
            }
        }
        let edges = memberCounts.indices.dropLast().map { generation in
            Edge(
                start: CGPoint(x: width / 2, y: Self.rowY(generation) + node.height),
                end: CGPoint(x: width / 2, y: Self.rowY(generation + 1))
            )
        }
        self.generationCount = memberCounts.count
        self.nodes = nodes
        self.edges = edges
        let rows = CGFloat(memberCounts.count)
        self.size = memberCounts.isEmpty
            ? .zero
            : CGSize(width: width, height: Self.padding.height * 2 + rows * Self.rowPitch - (Self.rowPitch - node.height))
    }

    static func rowY(_ generation: Int) -> CGFloat {
        padding.height + CGFloat(generation) * rowPitch
    }

    static func rowWidth(for count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        return CGFloat(count) * nodeSize.width + CGFloat(count - 1) * columnGap
    }

    func node(generation: Int, index: Int) -> Node? {
        nodes.first { $0.generation == generation && $0.index == index }
    }

    /// Centre of a node, handy for scroll targets.
    func center(of node: Node) -> CGPoint {
        CGPoint(x: node.origin.x + Self.nodeSize.width / 2, y: node.origin.y + Self.nodeSize.height / 2)
    }

    static func clamped(_ scale: CGFloat) -> CGFloat {
        min(max(scale, scaleRange.lowerBound), scaleRange.upperBound)
    }

    /// Scale that shows the whole tree in `viewport`, never above 1 (prototype `fitTree`).
    func fitScale(in viewport: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return 1 }
        return Self.clamped(min(1, viewport.width / size.width, viewport.height / size.height) * 0.96)
    }
}
