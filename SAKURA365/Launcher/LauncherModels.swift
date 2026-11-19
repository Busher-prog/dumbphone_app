import Foundation

/// One entry in the launcher.
struct LauncherApp: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    /// Display name — editable by the user.
    var name: String
    /// URL that opens the app (scheme or universal link).
    var url: String
    /// SF Symbol, always rendered monochrome.
    var symbol: String
    /// Catalog identifier when the entry came from the catalog (nil = custom).
    var catalogID: String?
}

enum LauncherColumns: Int, Codable, CaseIterable, Identifiable {
    case one = 1, two = 2
    var id: Int { rawValue }
    var title: String { self == .one ? "One column" : "Two columns" }
}

struct LauncherSettings: Codable, Equatable {
    var columns: LauncherColumns = .two
    var sectionTitle: String = "Essentials"
}

/// Apps the user can pick from. URL schemes for Apple apps are widely used but
/// not all are officially documented; anything else can be added as a custom
/// app with its own URL (including `shortcuts://run-shortcut?name=…`).
struct CatalogApp: Identifiable, Hashable {
    let id: String
    let name: String
    let url: String
    let symbol: String

    func makeLauncherApp() -> LauncherApp {
        LauncherApp(name: name, url: url, symbol: symbol, catalogID: id)
    }

    static let all: [CatalogApp] = [
        // Apple
        .init(id: "phone",     name: "Phone",     url: "mobilephone://",          symbol: "phone"),
        .init(id: "messages",  name: "Messages",  url: "sms://",                  symbol: "bubble"),
        .init(id: "mail",      name: "Mail",      url: "message://",              symbol: "envelope"),
        .init(id: "maps",      name: "Maps",      url: "maps://",                 symbol: "mappin.circle"),
        .init(id: "camera",    name: "Camera",    url: "shortcuts://run-shortcut?name=Camera", symbol: "camera"),
        .init(id: "photos",    name: "Photos",    url: "photos-redirect://",      symbol: "photo"),
        .init(id: "music",     name: "Music",     url: "music://",                symbol: "music.note"),
        .init(id: "calendar",  name: "Calendar",  url: "calshow://",              symbol: "calendar"),
        .init(id: "wallet",    name: "Wallet",    url: "shoebox://",              symbol: "wallet.pass"),
        .init(id: "notes",     name: "Notes",     url: "mobilenotes://",          symbol: "note.text"),
        .init(id: "reminders", name: "Reminders", url: "x-apple-reminderkit://",  symbol: "checklist"),
        .init(id: "safari",    name: "Safari",    url: "x-web-search://",         symbol: "safari"),
        .init(id: "weather",   name: "Weather",   url: "weather://",              symbol: "cloud"),
        .init(id: "clock",     name: "Clock",     url: "clock-alarm://",          symbol: "clock"),
        .init(id: "podcasts",  name: "Podcasts",  url: "podcasts://",             symbol: "mic"),
        .init(id: "books",     name: "Books",     url: "ibooks://",               symbol: "book"),
        .init(id: "files",     name: "Files",     url: "shareddocuments://",      symbol: "folder"),
        .init(id: "health",    name: "Health",    url: "x-apple-health://",       symbol: "heart"),
        .init(id: "shortcuts", name: "Shortcuts", url: "shortcuts://",            symbol: "square.on.square"),
        .init(id: "settings",  name: "Settings",  url: "App-prefs:",              symbol: "gearshape"),
        .init(id: "appstore",  name: "App Store", url: "itms-apps://",            symbol: "bag"),
        // Third party
        .init(id: "telegram",  name: "Telegram",  url: "tg://",                   symbol: "paperplane"),
        .init(id: "whatsapp",  name: "WhatsApp",  url: "whatsapp://",             symbol: "phone.bubble"),
        .init(id: "instagram", name: "Instagram", url: "instagram://",            symbol: "camera.aperture"),
        .init(id: "youtube",   name: "YouTube",   url: "youtube://",              symbol: "play.rectangle"),
        .init(id: "spotify",   name: "Spotify",   url: "spotify://",              symbol: "waveform"),
        .init(id: "notion",    name: "Notion",    url: "notion://",               symbol: "doc.text"),
        .init(id: "gmail",     name: "Gmail",     url: "googlegmail://",          symbol: "envelope.open"),
        .init(id: "gmaps",     name: "Google Maps", url: "comgooglemaps://",      symbol: "map"),
        .init(id: "chrome",    name: "Chrome",    url: "googlechrome://",         symbol: "globe"),
        .init(id: "slack",     name: "Slack",     url: "slack://",                symbol: "number"),
        .init(id: "obsidian",  name: "Obsidian",  url: "obsidian://",             symbol: "diamond"),
    ]

    static let defaultSelection = ["phone", "messages", "maps", "camera", "music", "calendar", "wallet", "notes"]

    /// Restrained outline symbols offered for custom apps.
    static let symbolChoices = [
        "circle", "app", "square.grid.2x2", "leaf", "moon", "sun.min", "drop", "wind",
        "book", "bookmark", "pencil", "doc.text", "folder", "tray", "archivebox",
        "phone", "bubble", "envelope", "paperplane", "camera", "photo", "music.note",
        "headphones", "play.rectangle", "film", "mic", "globe", "map", "mappin.circle",
        "calendar", "clock", "timer", "checklist", "list.bullet", "cart", "bag",
        "creditcard", "wallet.pass", "banknote", "chart.line.uptrend.xyaxis", "heart",
        "figure.walk", "dumbbell", "fork.knife", "cup.and.saucer", "house", "car",
        "tram", "airplane", "gearshape", "lock", "key", "person", "person.2",
        "graduationcap", "lightbulb", "paintbrush", "camera.aperture", "waveform", "terminal",
    ]
}
