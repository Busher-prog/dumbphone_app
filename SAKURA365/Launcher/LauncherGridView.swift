import SwiftUI

/// The launcher on the home screen: monochrome symbols, muted names,
/// one or two columns as the user prefers.
struct LauncherGridView: View {
    @Bindable var store: LauncherStore
    var onEdit: (LauncherApp) -> Void
    var onManage: () -> Void
    var onFailedOpen: (LauncherApp) -> Void

    @Environment(\.openURL) private var openURL

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: store.settings.columns.rawValue)
    }

    var body: some View {
        if store.apps.isEmpty {
            Button(action: onManage) {
                Text("Add your first app")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.hairline, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            }
            .buttonStyle(.plain)
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.apps) { app in
                    Button { open(app) } label: {
                        LauncherTile(app: app, compact: store.settings.columns == .two)
                    }
                    .buttonStyle(TileButtonStyle())
                    .contextMenu {
                        Button { onEdit(app) } label: { Label("Rename", systemImage: "pencil") }
                        Button { onManage() } label: { Label("Arrange apps", systemImage: "arrow.up.arrow.down") }
                        Divider()
                        Button(role: .destructive) { withAnimation(.easeOut(duration: 0.25)) { store.remove(app) } } label: {
                            Label("Remove from launcher", systemImage: "minus.circle")
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: store.settings.columns)
            .animation(.easeInOut(duration: 0.3), value: store.apps)
        }
    }

    private func open(_ app: LauncherApp) {
        guard let url = URL(string: app.url) else { onFailedOpen(app); return }
        openURL(url) { accepted in
            if !accepted { onFailedOpen(app) }
        }
    }
}

struct LauncherTile: View {
    let app: LauncherApp
    let compact: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: app.symbol)
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 19, weight: .light))
                .foregroundStyle(Palette.moonlight.opacity(0.85))
                .frame(width: 26)
            Text(app.name)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Palette.moonlight.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            if !compact {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Palette.secondaryText.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.charcoal, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.hairline, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityLabel(Text("Open \(app.name)"))
    }
}

private struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}
