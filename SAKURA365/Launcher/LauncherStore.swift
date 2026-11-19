import SwiftUI
import Observation

/// Owns the launcher's apps and layout and persists them as JSON in UserDefaults.
@Observable
final class LauncherStore {
    private(set) var apps: [LauncherApp]
    var settings: LauncherSettings { didSet { save() } }

    private let defaults: UserDefaults
    private static let appsKey = "sakura365.launcher.apps.v1"
    private static let settingsKey = "sakura365.launcher.settings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: Self.appsKey),
           let saved = try? decoder.decode([LauncherApp].self, from: data) {
            apps = saved
        } else {
            apps = CatalogApp.defaultSelection.compactMap { id in
                CatalogApp.all.first { $0.id == id }?.makeLauncherApp()
            }
        }
        if let data = defaults.data(forKey: Self.settingsKey),
           let saved = try? decoder.decode(LauncherSettings.self, from: data) {
            settings = saved
        } else {
            settings = LauncherSettings()
        }
    }

    // MARK: Mutations

    func add(_ app: LauncherApp) {
        apps.append(app)
        save()
    }

    func remove(atOffsets offsets: IndexSet) {
        apps.remove(atOffsets: offsets)
        save()
    }

    func remove(_ app: LauncherApp) {
        apps.removeAll { $0.id == app.id }
        save()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        apps.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func update(_ app: LauncherApp) {
        guard let i = apps.firstIndex(where: { $0.id == app.id }) else { return }
        apps[i] = app
        save()
    }

    func contains(catalogID: String) -> Bool {
        apps.contains { $0.catalogID == catalogID }
    }

    func resetToDefaults() {
        apps = CatalogApp.defaultSelection.compactMap { id in
            CatalogApp.all.first { $0.id == id }?.makeLauncherApp()
        }
        settings = LauncherSettings()
        save()
    }

    // MARK: Persistence

    private func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(apps) { defaults.set(data, forKey: Self.appsKey) }
        if let data = try? encoder.encode(settings) { defaults.set(data, forKey: Self.settingsKey) }
    }
}
