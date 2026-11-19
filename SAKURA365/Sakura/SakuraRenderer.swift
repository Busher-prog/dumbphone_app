import SwiftUI

/// Draws one frame of the tree into a SwiftUI `GraphicsContext`.
///
/// Cost per frame (≈30 fps while visible): forward kinematics for ~300 branches,
/// one combined fill for all wood, three combined fills for all blossoms,
/// a handful of gradients. Fallen petals are cached per day.
final class SakuraRenderer {
    private let tree = SakuraTree.shared
    private lazy var pose = TreePose(tree: tree)

    private var cachedGroundIndex = -1
    private var groundPaths: [[Path]] = []           // [tone][ageBucket]
    private static let groundAlpha: [Double] = [0.66, 0.5, 0.36]

    /// Length of the "today's petal" cycle: tremble, detach, fall, rest.
    static let fallCycle: Double = 20

    func draw(in context: inout GraphicsContext, size: CGSize, time: Double, day: SakuraDay, animated: Bool) {
        let scene = SakuraTree.sceneSize
        let scale = size.width / scene.width
        context.scaleBy(x: scale, y: scale)
        let bounds = CGRect(origin: .zero, size: scene)

        drawAtmosphere(in: &context, bounds: bounds)

        pose.update(time: time, still: !animated)
        let idx = day.petalIndex
        let remaining = SakuraDay.petalCount - idx
        let fullness = 0.45 + 0.55 * Double(remaining) / Double(SakuraDay.petalCount)

        drawGround(in: &context, petalIndex: idx)
        drawHaze(in: &context, fullness: fullness)
        drawWood(in: &context)
        drawBlossoms(in: &context, time: time, petalIndex: idx, animated: animated)
        drawTodaysPetal(in: &context, time: time, petalIndex: idx, animated: animated)
        if animated { drawLoosePetals(in: &context, time: time, petalIndex: idx) }
    }

    // MARK: Atmosphere

    private func drawAtmosphere(in context: inout GraphicsContext, bounds: CGRect) {
        context.fill(Path(bounds), with: .color(Palette.illustration))
        // A faint moon-glow behind the crown.
        context.fill(Path(bounds), with: .radialGradient(
            Gradient(colors: [Palette.moonlight.opacity(0.06), Palette.moonlight.opacity(0)]),
            center: CGPoint(x: 700, y: 120), startRadius: 10, endRadius: 600))
        // Dusk settling on moss.
        let g = SakuraTree.ground
        let floor = CGRect(x: 0, y: g - 40, width: bounds.width, height: bounds.height - g + 40)
        context.fill(Path(floor), with: .linearGradient(
            Gradient(colors: [Palette.moss.opacity(0), Palette.moss.opacity(0.10)]),
            startPoint: CGPoint(x: 0, y: floor.minY), endPoint: CGPoint(x: 0, y: floor.maxY)))
    }

    // MARK: Fallen petals (past days)

    private func drawGround(in context: inout GraphicsContext, petalIndex idx: Int) {
        if idx != cachedGroundIndex { rebuildGround(petalIndex: idx) }
        for tone in 0..<3 {
            for bucket in 0..<3 where !groundPaths[tone][bucket].isEmpty {
                context.fill(groundPaths[tone][bucket],
                             with: .color(Palette.blossomTones[tone].opacity(Self.groundAlpha[bucket])))
            }
        }
    }

    private func rebuildGround(petalIndex idx: Int) {
        groundPaths = Array(repeating: Array(repeating: Path(), count: 3), count: 3)
        for k in 0..<idx {
            let i = tree.fallOrder[k]
            let spot = tree.groundSpots[i]
            // Older petals have faded into the earth.
            let age = Double(idx - k) / Double(SakuraDay.petalCount)
            let bucket = age < 0.15 ? 0 : (age < 0.5 ? 1 : 2)
            let petal = SakuraTree.petal(x: spot.x, y: spot.y, rotation: spot.rot,
                                         size: 6 * spot.scale, squash: 0.5)
            groundPaths[tree.blossoms[i].tone][bucket].addPath(petal)
        }
        cachedGroundIndex = idx
    }

    // MARK: Canopy haze

    private func drawHaze(in context: inout GraphicsContext, fullness: Double) {
        for h in tree.haze {
            let p = pose.point(branch: h.branch, t: h.t).point
            let c = CGPoint(x: Double(p.x) + h.ox, y: Double(p.y) + h.oy)
            let color = Palette.blossomTones[h.tone]
            context.fill(
                Path(ellipseIn: CGRect(x: c.x - h.size, y: c.y - h.size, width: h.size * 2, height: h.size * 2)),
                with: .radialGradient(Gradient(colors: [color.opacity(0.13 * fullness), color.opacity(0)]),
                                      center: c, startRadius: 0, endRadius: h.size))
        }
    }

    // MARK: Wood

    private func drawWood(in context: inout GraphicsContext) {
        var wood = Path()
        var litEdges: [(Path, Double)] = []
        let n = SakuraTree.segments

        for (i, b) in tree.branches.enumerated() {
            let pts = Array(pose.branchPoints(i))
            let angs = Array(pose.branchAngles(i))
            var left: [CGPoint] = [], right: [CGPoint] = []
            left.reserveCapacity(n + 1); right.reserveCapacity(n + 1)
            for k in 0...n {
                let u = Double(k) / Double(n)
                let w = (b.w0 + (b.w1 - b.w0) * u) / 2
                let nx = cos(angs[k]), ny = sin(angs[k])
                let px = Double(pts[k].x), py = Double(pts[k].y)
                left.append(CGPoint(x: px - nx * w, y: py - ny * w))
                right.append(CGPoint(x: px + nx * w, y: py + ny * w))
            }
            var shape = Path()
            shape.move(to: left[0])
            for k in 1...n { shape.addLine(to: left[k]) }
            // Rounded tip.
            let tip = pts[n], a = angs[n]
            let ctrl = CGPoint(x: Double(tip.x) + sin(a) * b.w1, y: Double(tip.y) - cos(a) * b.w1)
            shape.addQuadCurve(to: right[n], control: ctrl)
            for k in stride(from: n - 1, through: 0, by: -1) { shape.addLine(to: right[k]) }
            shape.closeSubpath()
            wood.addPath(shape)

            if b.w0 > 6 {
                var edge = Path()
                edge.move(to: left[0])
                for k in 1...n { edge.addLine(to: left[k]) }
                litEdges.append((edge, max(1, b.w0 * 0.09)))
            }
        }
        context.fill(wood, with: .color(Palette.branch))
        for (edge, width) in litEdges {
            context.stroke(edge, with: .color(Palette.branchLit), lineWidth: width)
        }
        drawBark(in: &context)
    }

    private func drawBark(in context: inout GraphicsContext) {
        for (i, strokes) in tree.bark.enumerated() where !strokes.isEmpty {
            let b = tree.branches[i]
            for s in strokes {
                var line = Path()
                for step in 0...6 {
                    let u = s.u0 + (s.u1 - s.u0) * Double(step) / 6
                    let q = pose.point(branch: i, t: u)
                    let w = (b.w0 + (b.w1 - b.w0) * u) / 2 * (s.side + sin(u * 20 + Double(s.k)) * 0.06)
                    let pt = CGPoint(x: Double(q.point.x) + cos(q.angle) * w, y: Double(q.point.y) + sin(q.angle) * w)
                    if step == 0 { line.move(to: pt) } else { line.addLine(to: pt) }
                }
                context.stroke(line, with: .color(Palette.bark.opacity(s.alpha)),
                               style: StrokeStyle(lineWidth: s.width, lineCap: .round))
            }
        }
    }

    // MARK: Blossoms (future days)

    private func blossomTransform(_ b: SakuraTree.Blossom, time: Double, animated: Bool) -> CGAffineTransform {
        let q = pose.point(branch: b.branch, t: b.t).point
        // Clusters follow their branch, then settle a moment later.
        var angle = pose.sway[b.branch] * 0.9
        if animated { angle += sin(time * 1.9 + b.lag * 9) * 0.02 * Wind.intensity(at: time - b.lag) }
        return CGAffineTransform(rotationAngle: angle).concatenating(.init(translationX: q.x, y: q.y))
    }

    private func drawBlossoms(in context: inout GraphicsContext, time: Double, petalIndex idx: Int, animated: Bool) {
        var tones = [Path(), Path(), Path()]
        var centers = Path()
        for (i, b) in tree.blossoms.enumerated() where tree.rank[i] > idx {
            let t = blossomTransform(b, time: time, animated: animated)
            for tone in 0..<3 { if let s = b.shapes[tone] { tones[tone].addPath(s, transform: t) } }
            centers.addPath(b.centers, transform: t)
        }
        for tone in 0..<3 {
            context.fill(tones[tone], with: .color(Palette.blossomTones[tone].opacity(0.92)))
        }
        context.fill(centers, with: .color(Palette.blossomCenter))
    }

    // MARK: Today's petal

    private func drawTodaysPetal(in context: inout GraphicsContext, time: Double, petalIndex idx: Int, animated: Bool) {
        let i = tree.fallOrder[idx]
        let b = tree.blossoms[i]
        let t = blossomTransform(b, time: time, animated: animated)

        // Today's blossom is still on the branch, but already letting go.
        var faded = context
        faded.opacity = 0.5
        for tone in 0..<3 { if let s = b.shapes[tone] { faded.fill(s.applying(t), with: .color(Palette.blossomTones[tone])) } }

        let start = CGPoint(x: b.ox, y: b.oy).applying(t)
        let spot = tree.groundSpots[i]
        let phase = animated ? time.truncatingRemainder(dividingBy: Self.fallCycle) / Self.fallCycle : 0.08

        let sx = Double(start.x), sy = Double(start.y)
        var x = sx, y = sy, rot = b.rot, squash = 1.0, alpha = 1.0
        if phase < 0.18 {
            // Trembling at the stem.
            x += sin(time * 18) * 1.4 * (phase / 0.18)
        } else if phase < 0.72 {
            // Detached: spins, flutters, drifts with the wind, descends.
            let u = (phase - 0.18) / 0.54
            let e = smoothCurve(u)
            let flutter: Double = sin(u * 7.5) * 38 * (1 - u * 0.4)
            let push: Double = Wind.intensity(at: time) * 60 * u
            x = sx + (spot.x - sx) * e + flutter - push
            y = sy + (spot.y - sy) * (0.15 * u + 0.85 * e)
            rot = b.rot + u * 9
            squash = abs(cos(u * 14)) * 0.8 + 0.2
        } else {
            // Resting on the ground, then quietly returning for the next cycle.
            x = spot.x; y = spot.y; rot = spot.rot; squash = 0.5
            if phase > 0.9 { alpha = 1 - (phase - 0.9) / 0.1 }
        }
        var ctx = context
        ctx.opacity = alpha
        ctx.fill(SakuraTree.petal(x: x, y: y, rotation: rot, size: 6.5, squash: squash),
                 with: .color(Palette.blossom))
    }

    // MARK: Loose petals (ambient)

    /// Every few seconds a single petal may slip from a blossom still on the tree.
    /// Slots are hashed from time, so the sequence is deterministic and bounded
    /// (never more than ~4 in the air).
    private func drawLoosePetals(in context: inout GraphicsContext, time: Double, petalIndex idx: Int) {
        let remaining = SakuraDay.petalCount - idx - 1
        guard remaining > 0 else { return }
        let slot = 3.6
        let current = Int((time / slot).rounded(.down))
        // Calmer air releases fewer petals.
        let windNow = Wind.intensity(at: time)
        var petals = Path()
        var alphas: [(Path, Double)] = []
        for k in (current - 4)...current {
            if hash01(k * 7 + 1) > 0.25 + 0.45 * windNow { continue }
            let age = time - Double(k) * slot - hash01(k * 7 + 2) * slot
            guard age >= 0 else { continue }
            let life = 12 + hash01(k * 7 + 3) * 5
            let u = age / life
            guard u <= 1 else { continue }
            let pick = idx + 1 + Int(hash01(k * 7 + 4) * Double(remaining))
            let b = tree.blossoms[tree.fallOrder[min(pick, SakuraDay.petalCount - 1)]]
            let anchor = pose.point(branch: b.branch, t: b.t).point
            let ox = Double(anchor.x), oy = Double(anchor.y)
            let drift: Double = u * (260 + 140 * hash01(k * 7 + 5))
            let sway: Double = sin(age * 1.3 + Double(k)) * 22
            let px: Double = ox + b.ox - drift + sway
            let py: Double = oy + b.oy + u * (SakuraTree.ground - oy) * 0.95
            let fade = min(1, u * 8) * min(1, (1 - u) * 4)
            let shape = SakuraTree.petal(x: px, y: py, rotation: age * 1.7 + Double(k), size: 4.8,
                                         squash: abs(cos(age * 2.1)) * 0.75 + 0.25)
            if fade >= 0.99 { petals.addPath(shape) } else { alphas.append((shape, fade)) }
        }
        context.fill(petals, with: .color(Palette.blossom.opacity(0.75)))
        for (shape, a) in alphas { context.fill(shape, with: .color(Palette.blossom.opacity(0.75 * a))) }
    }
}
