import Foundation

/// Mulberry32 — a tiny, fast, fully deterministic PRNG.
/// The same seed always yields the same tree, blossoms and fallen-petal positions,
/// on every launch and every device. Nothing about the tree is random at runtime.
struct Mulberry32 {
    private var state: UInt32

    init(seed: UInt32) { state = seed }

    /// Uniform value in [0, 1).
    mutating func next() -> Double {
        state = state &+ 0x6D2B_79F5
        var t = state
        t = (t ^ (t >> 15)) &* (t | 1)
        t = t ^ (t &+ ((t ^ (t >> 7)) &* (t | 61)))
        return Double(t ^ (t >> 14)) / 4_294_967_296
    }

    /// Uniform value in [a, b).
    mutating func range(_ a: Double, _ b: Double) -> Double {
        a + (b - a) * next()
    }
}

/// Stateless hash of an integer to [0, 1). Used for time-slot decisions
/// (wind noise, ambient petals) so animation is reproducible, not random.
@inline(__always)
func hash01(_ n: Int) -> Double {
    var r = Mulberry32(seed: UInt32(truncatingIfNeeded: n) &* 2_654_435_761)
    return r.next()
}

@inline(__always)
func smoothCurve(_ x: Double) -> Double { x * x * (3 - 2 * x) }

@inline(__always)
func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
    smoothCurve(min(1, max(0, (x - a) / (b - a))))
}

/// 1D value noise in [0, 1], smooth between integer lattice points.
@inline(__always)
func valueNoise(_ x: Double) -> Double {
    let i = Int(x.rounded(.down))
    let f = x - Double(i)
    let a = hash01(i), b = hash01(i + 1)
    return a + (b - a) * smoothCurve(f)
}
