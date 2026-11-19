import SwiftUI

@main
struct Sakura365App: App {
    @State private var store = LauncherStore()

    init() {
        Self.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            HomeView(store: store)
                // Dark only. Also enforced by UIUserInterfaceStyle = Dark in Info.plist.
                .preferredColorScheme(.dark)
                .tint(Palette.dustySakura)
        }
    }

    /// UIKit-backed chrome (navigation bars, segmented controls) in the same palette.
    private static func configureAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(hex: 0x101113)
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor(hex: 0xC5BFB4)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(hex: 0xC5BFB4)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav

        let seg = UISegmentedControl.appearance()
        seg.selectedSegmentTintColor = UIColor(hex: 0xB77D91).withAlphaComponent(0.35)
        seg.backgroundColor = UIColor(hex: 0x17171C)
        seg.setTitleTextAttributes([.foregroundColor: UIColor(hex: 0x8D8780)], for: .normal)
        seg.setTitleTextAttributes([.foregroundColor: UIColor(hex: 0xC5BFB4)], for: .selected)
    }
}
