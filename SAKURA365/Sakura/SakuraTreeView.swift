import SwiftUI

/// The living tree. Animates only while it is on screen and the app is active.
///
/// Battery notes:
/// * `TimelineView(.animation(minimumInterval:paused:))` caps redraws at 30 fps
///   and stops scheduling frames entirely when paused.
/// * Paused when the scene is inactive or in the background, and when the view
///   leaves the screen. With Reduce Motion a still tree is drawn instead.
/// * In Low Power Mode the frame rate drops to 15 fps.
/// * The canvas is opaque (no blending with what is behind it).
struct SakuraTreeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOnScreen = false
    @State private var renderer = SakuraRenderer()
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        let animated = isOnScreen && scenePhase == .active && !reduceMotion
        TimelineView(.animation(minimumInterval: lowPower ? 1.0 / 15 : 1.0 / 30, paused: !animated)) { timeline in
            let date = timeline.date
            let day = SakuraDay(date: date)
            Canvas(opaque: true) { context, size in
                renderer.draw(in: &context, size: size,
                              time: date.timeIntervalSinceReferenceDate,
                              day: day, animated: animated)
            }
        }
        .aspectRatio(SakuraTree.sceneSize.width / SakuraTree.sceneSize.height, contentMode: .fit)
        .onAppear { isOnScreen = true }
        .onDisappear { isOnScreen = false }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .accessibilityElement()
        .accessibilityLabel(Text(accessibilityText))
    }

    private var accessibilityText: String {
        let d = SakuraDay(date: .now)
        return "Sakura tree. \(d.fallenCount) petals have fallen, \(d.remainingOnTree) remain on the branches, and today's petal is falling."
    }
}

#Preview {
    SakuraTreeView()
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding()
        .background(Palette.midnight)
}
