import SwiftUI

/// The procedurally drawn — but fully deterministic — sakura tree.
///
/// Built once from a fixed seed. Composition follows the reference: a thick
/// trunk entering from the bottom-right corner, leaning up and to the left;
/// a long expressive limb reaching left; dense blossom masses in the upper
/// and left parts of the crown; open dark space on the left for drifting petals.
///
/// Scene space is `SakuraTree.sceneSize` (1000 × 580), y pointing down.
final class SakuraTree {
    static let sceneSize = CGSize(width: 1000, height: 580)
    static let ground: Double = 556
    static let segments = 6               // polyline segments per branch
    static let seed: UInt32 = 365

    struct Branch {
        let parent: Int
        let attachT: Double
        let angle: Double                  // radians from "up", relative to parent; negative = left
        let length: Double
        let w0: Double, w1: Double         // base / tip width
        let depth: Int
        let bend: Double                   // curvature along the branch
        let world: Double                  // rest world angle (used while growing)
        let phase: Double, freq: Double    // individual sway timing
        let flex: Double                   // sway amplitude: thin twigs move, the trunk barely does
    }

    struct BarkStroke { let u0, u1, side, width, alpha: Double; let k: Int }

    /// One day. Its flower plus four buds/florets, pre-built as paths relative
    /// to the branch anchor so a frame only applies one transform per blossom.
    struct Blossom {
        let branch: Int
        let t: Double
        let ox: Double, oy: Double
        let size: Double
        let rot: Double
        let tone: Int
        let lag: Double
        var shapes: [Path?] = [nil, nil, nil]   // by tone
        var centers = Path()
    }

    struct Haze { let branch: Int; let t, ox, oy, size: Double; let tone: Int }
    struct GroundSpot { let x, y, rot, scale: Double }

    private(set) var branches: [Branch] = []
    private(set) var bark: [[BarkStroke]] = []
    private(set) var blossoms: [Blossom] = []
    private(set) var haze: [Haze] = []
    /// `fallOrder[k]` = blossom that falls on petal-day k.
    private(set) var fallOrder: [Int] = []
    /// `rank[blossom]` = petal-day on which that blossom falls.
    private(set) var rank: [Int] = []
    private(set) var groundSpots: [GroundSpot] = []

    static let shared = SakuraTree()

    private init() { build() }

    // MARK: - Growth

    private func build() {
        var r = Mulberry32(seed: Self.seed)

        func grow(_ parent: Int, _ attachT: Double, _ angleIn: Double, _ length: Double,
                  _ w0: Double, _ w1: Double, _ depth: Int, _ bend: Double, auto: Bool = true) -> Int {
            let id = branches.count
            let pw = parent < 0 ? 0 : branches[parent].world + branches[parent].bend * (attachT - 0.5)
            var angle = angleIn
            var world = pw + angle
            // Keep limbs reaching for the light instead of drooping.
            if world < -1.75 { angle += (-1.75 - world) * 0.8; world = pw + angle }
            if world > 1.45 { angle -= (world - 1.45) * 0.8; world = pw + angle }
            let phase = r.range(0, .pi * 2)
            let freq = r.range(0.55, 0.95)
            let flex = depth == 0 ? 0.004 : min(0.12, 1.1 / pow(w0 + 2, 1.1))
            branches.append(Branch(parent: parent, attachT: attachT, angle: angle, length: length,
                                   w0: w0, w1: w1, depth: depth, bend: bend, world: world,
                                   phase: phase, freq: freq, flex: flex))
            if !auto || depth >= 6 || w1 < 1.3 { return id }

            let forks = depth < 2 ? 2 : (r.next() < 0.7 ? 2 : 3)
            for k in 0..<forks {
                let side = Double(forks == 2 ? (k == 0 ? -1 : 1) : (k - 1))
                var a = side * r.range(0.26, 0.6)
                a -= 0.16 * r.range(0.2, 1.0)
                a += r.range(-0.14, 0.14)
                let cw = w1 * (side == 0 ? 0.82 : r.range(0.6, 0.84))
                let len = length * r.range(0.64, 0.84)
                let tip = cw * r.range(0.5, 0.64)
                let bd = r.range(-0.4, 0.4)
                _ = grow(id, 1, a, len, cw, tip, depth + 1, bd)
            }
            let laterals = depth < 4 ? Int(r.range(1, 3.4)) : (r.next() < 0.5 ? 1 : 0)
            for _ in 0..<laterals {
                let t = r.range(0.3, 0.8)
                let side: Double = r.next() < 0.6 ? -1 : 1
                let cw = (w0 + (w1 - w0) * t) * r.range(0.34, 0.52)
                let a = side * r.range(0.55, 1.1)
                let len = length * r.range(0.36, 0.6)
                let bd = r.range(-0.45, 0.45)
                _ = grow(id, t, a, len, cw, cw * 0.48, depth + 1, bd)
            }
            return id
        }

        // Trunk and hand-composed main limbs (the character of the tree).
        let t1 = grow(-1, 0, -0.5, 250, 92, 64, 0, 0.3, auto: false)
        let t2 = grow(t1, 1, -0.12, 190, 64, 44, 0, -0.35, auto: false)
        _ = grow(t1, 0.52, -1.32, 360, 34, 13, 1, 0.5)    // great limb reaching left
        _ = grow(t1, 0.8, -1.7, 210, 15, 4, 3, 0.3)       // low, nearly horizontal branch
        _ = grow(t2, 0.45, -1.05, 250, 26, 11, 1, 0.35)   // mid limb, up-left
        _ = grow(t2, 1, -0.55, 220, 30, 14, 1, 0.2)       // crown leader
        _ = grow(t2, 1, 0.35, 160, 22, 10, 2, -0.3)       // crown toward the right edge
        _ = grow(t1, 0.95, 0.75, 140, 16, 7, 2, -0.2)     // short stub to the right

        // Bark grain for thick limbs.
        bark = branches.indices.map { i -> [BarkStroke] in
            let b = branches[i]
            guard b.w0 > 20 else { return [] }
            var rr = Mulberry32(seed: UInt32(truncatingIfNeeded: i * 131 + 7))
            return (0..<Int(ceil(b.w0 / 7))).map { k -> BarkStroke in
                let u0 = rr.next() * 0.7
                let u1 = min(1, u0 + 0.15 + rr.next() * 0.3)
                let side = rr.next() * 1.5 - 0.75
                let width = 1 + rr.next() * 2.2
                let alpha = 0.5 + rr.next() * 0.4
                return BarkStroke(u0: u0, u1: u1, side: side, width: width, alpha: alpha, k: k)
            }
        }

        // Blossom candidates along the finer branches, in the rest pose.
        let rest = TreePose(tree: self)
        rest.update(time: 0, still: true)
        struct Candidate { var branch: Int; var t, ox, oy, w: Double; var key = 0.0 }
        var cand: [Candidate] = []
        for (i, b) in branches.enumerated() where b.depth >= 2 {
            let n = max(1, Int((b.length / 7 * (b.depth >= 4 ? 1.3 : 0.7)).rounded()))
            for _ in 0..<n {
                let t = 0.2 + 0.8 * r.next()
                let ox = r.range(-20, 20)
                let oy = r.range(-18, 12)
                let p = rest.point(branch: i, t: t).point
                let x = Double(p.x) + ox, y = Double(p.y) + oy
                if x < -10 || x > Self.sceneSize.width + 10 || y < -20 || y > Self.ground - 40 { continue }
                // Density favours the upper crown and the left-reaching canopy.
                let up = 1 - y / Self.ground
                let left = 1 - abs(x - 560) / 520
                let w = pow(max(0.02, up), 1.6) * (0.4 + max(0, left))
                cand.append(Candidate(branch: i, t: t, ox: ox, oy: oy, w: w))
            }
        }
        // Weighted sampling without replacement (Efraimidis–Spirakis).
        for i in cand.indices { cand[i].key = pow(r.next(), 1 / cand[i].w) }
        cand.sort { $0.key > $1.key }

        blossoms = cand.prefix(SakuraDay.petalCount).map { c -> Blossom in
            let size = r.range(7, 11.5)
            let rot = r.range(0, .pi * 2)
            let tone = Int(r.next() * 3)
            let lag = r.range(0.15, 0.6)
            return Blossom(branch: c.branch, t: c.t, ox: c.ox, oy: c.oy,
                           size: size, rot: rot, tone: tone, lag: lag)
        }
        haze = cand[min(cand.count, SakuraDay.petalCount)..<min(cand.count, SakuraDay.petalCount + 36)].map { c -> Haze in
            let size = r.range(45, 80)
            let tone = Int(r.next() * 3)
            return Haze(branch: c.branch, t: c.t, ox: c.ox, oy: c.oy, size: size, tone: tone)
        }

        // Pre-build each blossom's flower + florets relative to its anchor.
        for i in blossoms.indices {
            var shapes: [Path] = [Path(), Path(), Path()]
            let b = blossoms[i]
            shapes[b.tone].addPath(Self.flowerPath(size: b.size, rotation: b.rot)
                .applying(CGAffineTransform(translationX: b.ox, y: b.oy)))
            for _ in 0..<4 {
                let fx = b.ox + r.range(-15, 15)
                let fy = b.oy + r.range(-12, 12)
                let fs = r.range(2.4, 4.6)
                let fr = r.range(0, 6.28)
                let tone = Int(r.next() * 3)
                let floret = Path(ellipseIn: CGRect(x: -fs, y: -fs * 0.75, width: fs * 2, height: fs * 1.5))
                    .applying(CGAffineTransform(rotationAngle: fr).concatenating(.init(translationX: fx, y: fy)))
                shapes[tone].addPath(floret)
            }
            blossoms[i].shapes = shapes.map { $0.isEmpty ? nil : $0 }
            let c = b.size * 0.16
            blossoms[i].centers = Path(ellipseIn: CGRect(x: b.ox - c, y: b.oy - c, width: c * 2, height: c * 2))
        }

        // The order in which blossoms fall through the year (deterministic shuffle),
        // so the crown thins evenly rather than branch by branch.
        var order = Array(0..<blossoms.count)
        for i in stride(from: order.count - 1, to: 0, by: -1) {
            let j = Int(r.next() * Double(i + 1))
            order.swapAt(i, j)
        }
        fallOrder = order
        rank = Array(repeating: 0, count: order.count)
        for (k, b) in order.enumerated() { rank[b] = k }

        // Where each fallen petal rests, gathered beneath the canopy.
        groundSpots = blossoms.indices.map { _ -> GroundSpot in
            let x = 560 + (r.range(-1, 1) + r.range(-1, 1) + r.range(-1, 1)) * 170
            let y = Self.ground + r.range(-10, 20)
            let rot = r.range(0, .pi)
            let s = r.range(0.7, 1.1)
            return GroundSpot(x: x, y: y, rot: rot, scale: s)
        }
    }

    // MARK: - Shapes

    /// A five-petal flower centred at the origin.
    static func flowerPath(size s: Double, rotation: Double) -> Path {
        var p = Path()
        for k in 0..<5 {
            let a = rotation + Double(k) * 1.2566
            let petal = Path(ellipseIn: CGRect(x: -s * 0.52, y: -s * 0.36, width: s * 1.04, height: s * 0.72))
                .applying(CGAffineTransform(rotationAngle: a)
                    .concatenating(.init(translationX: cos(a) * s * 0.55, y: sin(a) * s * 0.55)))
            p.addPath(petal)
        }
        return p
    }

    /// A single notched sakura petal centred at the origin, pointing along +x.
    static let unitPetal: Path = {
        var p = Path()
        p.move(to: CGPoint(x: -1, y: 0))
        p.addQuadCurve(to: CGPoint(x: 0.8, y: -0.25), control: CGPoint(x: -0.2, y: -0.9))
        p.addLine(to: CGPoint(x: 0.55, y: 0))
        p.addLine(to: CGPoint(x: 0.8, y: 0.25))
        p.addQuadCurve(to: CGPoint(x: -1, y: 0), control: CGPoint(x: -0.2, y: 0.9))
        p.closeSubpath()
        return p
    }()

    static func petal(x: Double, y: Double, rotation: Double, size: Double, squash: Double) -> Path {
        unitPetal.applying(
            CGAffineTransform(scaleX: size, y: size * squash)
                .concatenating(.init(rotationAngle: rotation))
                .concatenating(.init(translationX: x, y: y))
        )
    }
}

/// Forward kinematics for one frame. Reuses its buffers; no allocation per frame
/// beyond SwiftUI path building.
final class TreePose {
    private let tree: SakuraTree
    private let n = SakuraTree.segments
    private(set) var points: [CGPoint]
    private(set) var angles: [Double]
    private(set) var sway: [Double]
    private var windByDepth = [Double](repeating: 0, count: 8)

    init(tree: SakuraTree) {
        self.tree = tree
        let count = tree.branches.count * (SakuraTree.segments + 1)
        points = Array(repeating: .zero, count: count)
        angles = Array(repeating: 0, count: count)
        sway = Array(repeating: 0, count: tree.branches.count)
    }

    func update(time: Double, still: Bool = false) {
        // Wind arrives at the thinner branches slightly later than at the trunk.
        for d in 0..<windByDepth.count {
            windByDepth[d] = still ? 0 : Wind.intensity(at: time - Double(d) * 0.22)
        }
        let rowStride = n + 1
        let trunkBase = CGPoint(x: 985, y: SakuraTree.sceneSize.height + 70)
        for (i, b) in tree.branches.enumerated() {
            let base: CGPoint
            let baseAngle: Double
            if b.parent < 0 {
                base = trunkBase; baseAngle = 0
            } else {
                let a = point(branch: b.parent, t: b.attachT)
                base = a.point; baseAngle = a.angle
            }
            let w = windByDepth[min(b.depth, windByDepth.count - 1)]
            // Two incommensurate sines per branch -> no visible loop; plus a steady lean with the wind.
            let s = sin(time * b.freq * 1.4 + b.phase) * 0.65
                  + sin(time * b.freq * 2.45 + b.phase * 1.7) * 0.35
            let sw = b.flex * w * (0.55 * s + 0.45)
            sway[i] = sw
            let ang = baseAngle + b.angle + sw
            let step = b.length / Double(n)
            var p = base
            for k in 0...n {
                let u = Double(k) / Double(n)
                let a = ang + b.bend * (u - 0.5) + sw * u
                if k > 0 { p = CGPoint(x: Double(p.x) + sin(a) * step, y: Double(p.y) - cos(a) * step) }
                points[i * rowStride + k] = p
                angles[i * rowStride + k] = a
            }
        }
    }

    /// Position and direction at parameter t ∈ [0, 1] along a branch.
    @inline(__always)
    func point(branch i: Int, t: Double) -> (point: CGPoint, angle: Double) {
        let f = min(Double(n) - 1e-6, max(0, t * Double(n)))
        let k = Int(f), u = f - Double(k)
        let o = i * (n + 1) + k
        let a = points[o], c = points[o + 1]
        return (CGPoint(x: a.x + (c.x - a.x) * u, y: a.y + (c.y - a.y) * u),
                angles[o] + (angles[o + 1] - angles[o]) * u)
    }

    func branchPoints(_ i: Int) -> ArraySlice<CGPoint> {
        let o = i * (n + 1)
        return points[o...(o + n)]
    }

    func branchAngles(_ i: Int) -> ArraySlice<Double> {
        let o = i * (n + 1)
        return angles[o...(o + n)]
    }
}
