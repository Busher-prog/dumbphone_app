import SwiftUI

/// The single screen: date and time, the sakura card, the launcher.
struct HomeView: View {
    @Bindable var store: LauncherStore
    @State private var managing = false
    @State private var editing: LauncherApp?
    @State private var notice: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ClockHeader()
                SakuraCard()
                launcher
                Text("Be present.")
                    .sakuraCaption(Palette.secondaryText.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(Palette.midnight.ignoresSafeArea())
        .overlay(alignment: .bottom) { noticeView }
        .sheet(isPresented: $managing) { ManageAppsView(store: store) }
        .sheet(item: $editing) { app in EditAppView(app: app) { store.update($0) } }
    }

    private var launcher: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(store.settings.sectionTitle.isEmpty ? "Essentials" : store.settings.sectionTitle)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Palette.moonlight)
                Spacer()
                Button { managing = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Palette.dustySakura)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Manage apps")
            }
            Rectangle().fill(Palette.hairline).frame(height: 1)
            LauncherGridView(
                store: store,
                onEdit: { editing = $0 },
                onManage: { managing = true },
                onFailedOpen: { app in show("\(app.name) could not be opened") }
            )
        }
    }

    @ViewBuilder private var noticeView: some View {
        if let notice {
            Text(notice)
                .font(.system(size: 14))
                .foregroundStyle(Palette.moonlight)
                .padding(.horizontal, 18).padding(.vertical, 12)
                .background(Palette.charcoal, in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.hairline))
                .padding(.bottom, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func show(_ message: String) {
        withAnimation(.easeOut(duration: 0.3)) { notice = message }
        Task {
            try? await Task.sleep(for: .seconds(2.4))
            withAnimation(.easeIn(duration: 0.4)) { if notice == message { notice = nil } }
        }
    }
}

/// THURSDAY · NOVEMBER 19 / 09:32
private struct ClockHeader: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(alignment: .leading, spacing: 6) {
                Text(context.date.formatted(.dateTime.weekday(.wide)) + " · " +
                     context.date.formatted(.dateTime.month(.wide).day()))
                    .sakuraCaption()
                Text(context.date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 52, weight: .ultraLight))
                    .monospacedDigit()
                    .foregroundStyle(Palette.moonlight)
            }
        }
        .padding(.top, 8)
    }
}

/// The card around the tree, with its quiet counters.
struct SakuraCard: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            let day = SakuraDay(date: context.date)
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("SAKURA 365")
                        .font(.system(size: 22, weight: .light))
                        .tracking(1.2)
                        .foregroundStyle(Palette.moonlight)
                    Spacer()
                    Text("Day \(day.dayOfYear) / \(day.daysInYear)")
                        .sakuraCaption(Palette.dustySakura)
                        .monospacedDigit()
                }

                SakuraTreeView()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.hairline))

                HStack {
                    Text(day.daysRemaining == 1 ? "1 day remaining" : "\(day.daysRemaining) days remaining")
                        .sakuraCaption()
                    Spacer()
                    Text(day.progress, format: .percent.precision(.fractionLength(1)))
                        .font(.system(size: 14))
                        .monospacedDigit()
                        .foregroundStyle(Palette.dustySakura)
                }
                Text(day.reflection)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Palette.secondaryText)
            }
            .padding(18)
            .background(Palette.charcoal, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Palette.hairline))
        }
    }
}

#Preview {
    HomeView(store: LauncherStore())
        .preferredColorScheme(.dark)
}
