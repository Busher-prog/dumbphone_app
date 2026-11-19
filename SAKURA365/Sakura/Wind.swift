import Foundation

/// A calm, slowly varying wind field.
///
/// Intensity in [0, 1] is a blend of three octaves of smooth value noise
/// (slow swells, medium gusts, faint flutter) multiplied by a very slow
/// "calm envelope". When that envelope dips, the whole tree becomes almost
/// completely still for tens of seconds — then the breeze returns.
///
/// It is a pure function of time, so it costs nothing to store and is
/// identical across launches.
enum Wind {
    static func intensity(at t: Double) -> Double {
        let raw = 0.55 * valueNoise(t / 19)
                + 0.30 * valueNoise(t / 6.1 + 11)
                + 0.15 * valueNoise(t / 2.3 + 5)
        let calm = smoothstep(0.22, 0.5, valueNoise(t / 53 + 3))
        return raw * calm
    }
}
