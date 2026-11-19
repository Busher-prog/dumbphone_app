import SwiftUI

/// Add, remove, reorder and rename apps; choose one or two columns.
struct ManageAppsView: View {
    @Bindable var store: LauncherStore
    @Environment(\.dismiss) private var dismiss
    @State private var editing: LauncherApp?
    @State private var showingAdd = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Layout", selection: $store.settings.columns) {
                        ForEach(LauncherColumns.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Palette.charcoal)

                    HStack {
                        Text("Section title").foregroundStyle(Palette.secondaryText)
                        TextField("Essentials", text: $store.settings.sectionTitle)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Palette.moonlight)
                    }
                    .listRowBackground(Palette.charcoal)
                } header: {
                    Text("Layout").sakuraCaption()
                }

                Section {
                    ForEach(store.apps) { app in
                        Button { editing = app } label: {
                            HStack(spacing: 14) {
                                Image(systemName: app.symbol)
                                    .symbolRenderingMode(.monochrome)
                                    .font(.system(size: 17, weight: .light))
                                    .foregroundStyle(Palette.moonlight.opacity(0.8))
                                    .frame(width: 24)
                                Text(app.name).foregroundStyle(Palette.moonlight)
                                Spacer()
                                Text("Rename").font(.footnote).foregroundStyle(Palette.secondaryText)
                            }
                        }
                        .listRowBackground(Palette.charcoal)
                    }
                    .onMove { store.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { store.remove(atOffsets: $0) }

                    Button { showingAdd = true } label: {
                        Label("Add app", systemImage: "plus")
                            .foregroundStyle(Palette.dustySakura)
                    }
                    .listRowBackground(Palette.charcoal)
                } header: {
                    Text("Apps").sakuraCaption()
                } footer: {
                    Text("Drag to reorder. Swipe to remove. Removing an app only takes it off the launcher.")
                        .foregroundStyle(Palette.secondaryText)
                }

                Section {
                    Button("Restore default apps", role: .destructive) { confirmReset = true }
                        .listRowBackground(Palette.charcoal)
                }
            }
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .background(Palette.midnight)
            .navigationTitle("Launcher")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(Palette.blossom)
                }
            }
            .sheet(item: $editing) { app in
                EditAppView(app: app) { store.update($0) }
            }
            .sheet(isPresented: $showingAdd) {
                AddAppView(store: store)
            }
            .confirmationDialog("Restore the default apps and layout?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Restore", role: .destructive) { store.resetToDefaults() }
            }
        }
        .tint(Palette.dustySakura)
    }
}

/// Rename an app, change its symbol or URL.
struct EditAppView: View {
    @State var app: LauncherApp
    var onSave: (LauncherApp) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AppForm(app: $app)
                .navigationTitle("Edit app")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }.foregroundStyle(Palette.secondaryText)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { onSave(app.trimmed); dismiss() }
                            .disabled(!app.isValid)
                            .foregroundStyle(Palette.blossom)
                    }
                }
        }
        .tint(Palette.dustySakura)
    }
}

/// Pick from the catalog or add a custom app by URL.
struct AddAppView: View {
    @Bindable var store: LauncherStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var custom = LauncherApp(name: "", url: "", symbol: "circle")
    @State private var showingCustom = false

    private var results: [CatalogApp] {
        let available = CatalogApp.all.filter { !store.contains(catalogID: $0.id) }
        guard !query.isEmpty else { return available }
        return available.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { showingCustom = true } label: {
                        Label("Custom app with URL…", systemImage: "link")
                            .foregroundStyle(Palette.dustySakura)
                    }
                    .listRowBackground(Palette.charcoal)
                }
                Section {
                    ForEach(results) { item in
                        Button {
                            store.add(item.makeLauncherApp())
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: item.symbol)
                                    .symbolRenderingMode(.monochrome)
                                    .font(.system(size: 17, weight: .light))
                                    .foregroundStyle(Palette.moonlight.opacity(0.8))
                                    .frame(width: 24)
                                Text(item.name).foregroundStyle(Palette.moonlight)
                                Spacer()
                                Image(systemName: "plus").foregroundStyle(Palette.secondaryText)
                            }
                        }
                        .listRowBackground(Palette.charcoal)
                    }
                } header: {
                    Text("Apps").sakuraCaption()
                }
            }
            .searchable(text: $query, prompt: "Search")
            .scrollContentBackground(.hidden)
            .background(Palette.midnight)
            .navigationTitle("Add app")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(Palette.blossom)
                }
            }
            .navigationDestination(isPresented: $showingCustom) {
                AppForm(app: $custom)
                    .navigationTitle("Custom app")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                store.add(custom.trimmed)
                                custom = LauncherApp(name: "", url: "", symbol: "circle")
                                showingCustom = false
                            }
                            .disabled(!custom.isValid)
                            .foregroundStyle(Palette.blossom)
                        }
                    }
            }
        }
        .tint(Palette.dustySakura)
    }
}

/// Shared form for editing a launcher entry.
struct AppForm: View {
    @Binding var app: LauncherApp
    private let symbolGrid = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $app.name)
                    .foregroundStyle(Palette.moonlight)
                    .listRowBackground(Palette.charcoal)
                TextField("URL, e.g. tg:// or https://…", text: $app.url)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .foregroundStyle(Palette.moonlight)
                    .listRowBackground(Palette.charcoal)
            } header: {
                Text("App").sakuraCaption()
            } footer: {
                Text("Any URL scheme or link works — for example shortcuts://run-shortcut?name=Camera.")
                    .foregroundStyle(Palette.secondaryText)
            }
            Section {
                LazyVGrid(columns: symbolGrid, spacing: 8) {
                    ForEach(symbolOptions, id: \.self) { symbol in
                        Button { app.symbol = symbol } label: {
                            Image(systemName: symbol)
                                .symbolRenderingMode(.monochrome)
                                .font(.system(size: 18, weight: .light))
                                .foregroundStyle(app.symbol == symbol ? Palette.blossom : Palette.moonlight.opacity(0.7))
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(app.symbol == symbol ? Palette.dustySakura.opacity(0.14) : .clear))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(app.symbol == symbol ? Palette.dustySakura.opacity(0.5) : Palette.hairline))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(symbol))
                    }
                }
                .padding(.vertical, 6)
                .listRowBackground(Palette.charcoal)
            } header: {
                Text("Symbol").sakuraCaption()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.midnight)
    }

    private var symbolOptions: [String] {
        CatalogApp.symbolChoices.contains(app.symbol) ? CatalogApp.symbolChoices : [app.symbol] + CatalogApp.symbolChoices
    }
}

extension LauncherApp {
    var trimmed: LauncherApp {
        var copy = self
        copy.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.url = url.trimmingCharacters(in: .whitespacesAndNewlines)
        return copy
    }

    var isValid: Bool {
        let t = trimmed
        return !t.name.isEmpty && URL(string: t.url)?.scheme != nil
    }
}
