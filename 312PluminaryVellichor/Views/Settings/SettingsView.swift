import SwiftUI
import StoreKit
import Charts

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetAlert = false
    @State private var soundEnabled = HapticService.soundEnabled
    @State private var hapticsEnabled = HapticService.hapticsEnabled
    @State private var soundPack = HapticService.soundPack
    @State private var reminderEnabled = ReminderService.isEnabled
    @State private var reminderDeniedAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        VStack(spacing: 0) {
                            Toggle(isOn: $soundEnabled) {
                                Label {
                                    Text("Sound Effects")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                } icon: {
                                    Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                        .foregroundStyle(Color("AppPrimary"))
                                        .frame(width: 28)
                                }
                            }
                            .tint(Color("AppPrimary"))
                            .frame(minHeight: 44)
                            .padding(.vertical, 6)
                            .onChange(of: soundEnabled) { value in
                                HapticService.soundEnabled = value
                                if value { HapticService.play(HapticService.soundPack.tapSound) }
                            }

                            Divider().background(Color("AppTextSecondary").opacity(0.25))

                            Toggle(isOn: $hapticsEnabled) {
                                Label {
                                    Text("Haptic Feedback")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                } icon: {
                                    Image(systemName: "hand.tap.fill")
                                        .foregroundStyle(Color("AppPrimary"))
                                        .frame(width: 28)
                                }
                            }
                            .tint(Color("AppPrimary"))
                            .frame(minHeight: 44)
                            .padding(.vertical, 6)
                            .onChange(of: hapticsEnabled) { value in
                                HapticService.hapticsEnabled = value
                                if value { HapticService.light() }
                            }

                            Divider().background(Color("AppTextSecondary").opacity(0.25))

                            VStack(alignment: .leading, spacing: 10) {
                                Label {
                                    Text("Sound Pack")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                } icon: {
                                    Image(systemName: "waveform")
                                        .foregroundStyle(Color("AppPrimary"))
                                        .frame(width: 28)
                                }
                                .frame(minHeight: 36)

                                HStack(spacing: 8) {
                                    ForEach(SoundPack.allCases) { pack in
                                        Button {
                                            soundPack = pack
                                            HapticService.soundPack = pack
                                            HapticService.previewPack(pack)
                                            HapticService.light()
                                        } label: {
                                            Text(pack.title)
                                                .font(.caption.weight(.heavy))
                                                .foregroundStyle(
                                                    soundPack == pack ? Color("AppTextPrimary") : Color("AppTextSecondary")
                                                )
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(
                                                    Color("AppPrimary").opacity(soundPack == pack ? 0.4 : 0.15)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .strokeBorder(
                                                            soundPack == pack ? Color("AppAccent") : Color.clear,
                                                            lineWidth: 1.2
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(!soundEnabled)
                                        .opacity(soundEnabled ? 1 : 0.45)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    SoftCard {
                        Toggle(isOn: $reminderEnabled) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Daily Mood Prompt")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text("Local reminder at 7:00 PM")
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            } icon: {
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(Color("AppPrimary"))
                                    .frame(width: 28)
                            }
                        }
                        .tint(Color("AppPrimary"))
                        .frame(minHeight: 44)
                        .padding(.vertical, 6)
                        .onChange(of: reminderEnabled) { value in
                            if value {
                                ReminderService.requestAccessAndEnable { granted in
                                    if !granted {
                                        reminderEnabled = false
                                        reminderDeniedAlert = true
                                    }
                                }
                            } else {
                                ReminderService.isEnabled = false
                            }
                            HapticService.light()
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label {
                                Text("Dock Order")
                                    .foregroundStyle(Color("AppTextPrimary"))
                            } icon: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundStyle(Color("AppPrimary"))
                                    .frame(width: 28)
                            }
                            .padding(.top, 4)

                            ForEach(Array(store.dockOrder.enumerated()), id: \.element.id) { index, tab in
                                HStack(spacing: 10) {
                                    Image(systemName: tab.icon)
                                        .foregroundStyle(Color("AppAccent"))
                                        .frame(width: 24)
                                    Text(tab.title)
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    Spacer()
                                    Button {
                                        store.moveDockTabUp(tab)
                                    } label: {
                                        Image(systemName: "chevron.up")
                                            .foregroundStyle(index == 0 ? Color("AppTextSecondary").opacity(0.35) : Color("AppTextPrimary"))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(index == 0)

                                    Button {
                                        store.moveDockTabDown(tab)
                                    } label: {
                                        Image(systemName: "chevron.down")
                                            .foregroundStyle(
                                                index == store.dockOrder.count - 1
                                                    ? Color("AppTextSecondary").opacity(0.35)
                                                    : Color("AppTextPrimary")
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(index == store.dockOrder.count - 1)
                                }
                                .frame(minHeight: 40)
                                if index < store.dockOrder.count - 1 {
                                    Divider().background(Color("AppTextSecondary").opacity(0.25))
                                }
                            }
                        }
                        .padding(.bottom, 4)
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            NavigationLink {
                                StatsDetailView()
                            } label: {
                                settingsRow(title: "Stats", systemImage: "chart.bar.fill")
                            }
                            .buttonStyle(.plain)

                            Divider().background(Color("AppTextSecondary").opacity(0.25))

                            settingsButton(title: "Rate Us", systemImage: "star.fill") {
                                rateApp()
                            }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            settingsButton(title: "Privacy Policy", systemImage: "hand.raised.fill") {
                                openURL(AppLinks.privacyPolicy)
                            }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            settingsButton(title: "Terms of Use", systemImage: "doc.text.fill") {
                                openURL(AppLinks.termsOfUse)
                            }
                        }
                    }

                    Button {
                        HapticService.warning()
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset All Data")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.red.opacity(0.95))
                        .padding(16)
                        .background(Color("AppSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.red.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        )
                        .shadow(color: Color("AppPrimary").opacity(0.2), radius: 10, y: 0)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 100)
                }
                .padding(16)
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .onAppear {
                soundEnabled = HapticService.soundEnabled
                hapticsEnabled = HapticService.hapticsEnabled
                soundPack = HapticService.soundPack
                reminderEnabled = ReminderService.isEnabled
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAll()
                }
            } message: {
                Text("This clears moods, captions, favorites, and achievements on this device.")
            }
            .alert("Notifications Off", isPresented: $reminderDeniedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable notifications in iOS Settings to get the daily mood prompt.")
            }
        }
    }

    private func settingsRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Color("AppPrimary"))
                .frame(width: 28)
            Text(title)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(minHeight: 44)
        .padding(.vertical, 6)
    }

    private func settingsButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.light()
            action()
        } label: {
            settingsRow(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

// MARK: - Stats

private struct DayMoodCount: Identifiable {
    let id: Date
    let label: String
    let count: Int
}

private struct EmojiMoodCount: Identifiable {
    var id: String { emoji }
    let emoji: String
    let count: Int
}

private struct ThemeExploreCount: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
}

struct StatsDetailView: View {
    @EnvironmentObject private var store: AppDataStore

    private var moodByDay: [DayMoodCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().compactMap { offset -> DayMoodCount? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let count = store.moodEntries.filter { calendar.isDate($0.createdAt, inSameDayAs: day) }.count
            return DayMoodCount(id: day, label: formatter.string(from: day), count: count)
        }
    }

    private var moodByEmoji: [EmojiMoodCount] {
        Dictionary(grouping: store.moodEntries, by: \.emoji)
            .map { EmojiMoodCount(emoji: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(8)
            .map { $0 }
    }

    private var themeExplores: [ThemeExploreCount] {
        store.themes
            .map { ThemeExploreCount(name: $0.name, count: $0.exploreCount) }
            .sorted { $0.count > $1.count }
    }

    private var unlockProgress: Double {
        let total = Double(AchievementKind.allCases.count)
        guard total > 0 else { return 0 }
        return Double(store.unlockedAchievements.count) / total
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Overview")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                        HStack {
                            statBlock("Moods", store.stats.itemsAdded, "face.smiling")
                            statBlock("Captions", store.stats.entriesWritten, "text.quote")
                        }
                        HStack {
                            statBlock("Favorites", store.stats.favouritesCount, "heart.fill")
                            statBlock("Streak", store.stats.streakDays, "flame.fill")
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Moods · Last 7 Days")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))

                        if moodByDay.allSatisfy({ $0.count == 0 }) {
                            chartEmpty("Add moods to see daily activity.")
                        } else {
                            Chart(moodByDay) { item in
                                BarMark(
                                    x: .value("Day", item.label),
                                    y: .value("Moods", item.count)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("AppPrimary"), Color("AppAccent")],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(4)
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { _ in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                        .foregroundStyle(Color("AppTextSecondary").opacity(0.35))
                                    AxisValueLabel()
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .frame(height: 180)
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mood Mix")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))

                        if moodByEmoji.isEmpty {
                            chartEmpty("Your emoji mix will appear here.")
                        } else {
                            Chart(moodByEmoji) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Emoji", item.emoji)
                                )
                                .foregroundStyle(Color("AppPrimary").opacity(0.9))
                                .cornerRadius(3)
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                        .foregroundStyle(Color("AppTextSecondary").opacity(0.35))
                                    AxisValueLabel()
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(Color("AppTextPrimary"))
                                }
                            }
                            .frame(height: CGFloat(max(140, moodByEmoji.count * 36)))
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme Explores")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))

                        if themeExplores.allSatisfy({ $0.count == 0 }) {
                            chartEmpty("Explore themes to fill this chart.")
                        } else {
                            Chart(themeExplores) { item in
                                BarMark(
                                    x: .value("Explores", item.count),
                                    y: .value("Theme", item.name)
                                )
                                .foregroundStyle(Color("AppAccent").opacity(0.85))
                                .cornerRadius(3)
                            }
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                        .foregroundStyle(Color("AppTextSecondary").opacity(0.35))
                                    AxisValueLabel()
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(Color("AppTextPrimary"))
                                }
                            }
                            .frame(height: CGFloat(max(160, themeExplores.count * 36)))
                        }
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity Snapshot")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))

                        Chart {
                            BarMark(
                                x: .value("Metric", "Moods"),
                                y: .value("Count", store.stats.itemsAdded)
                            )
                            .foregroundStyle(Color("AppPrimary"))
                            BarMark(
                                x: .value("Metric", "Captions"),
                                y: .value("Count", store.stats.entriesWritten)
                            )
                            .foregroundStyle(Color("AppAccent"))
                            BarMark(
                                x: .value("Metric", "Favorites"),
                                y: .value("Count", store.stats.favouritesCount)
                            )
                            .foregroundStyle(Color("AppPrimary").opacity(0.55))
                            BarMark(
                                x: .value("Metric", "Streak"),
                                y: .value("Count", store.stats.streakDays)
                            )
                            .foregroundStyle(Color("AppAccent").opacity(0.55))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                                    .foregroundStyle(Color("AppTextSecondary").opacity(0.35))
                                AxisValueLabel()
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .frame(height: 180)
                    }
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Achievements Unlocked")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text("\(store.unlockedAchievements.count) / \(AchievementKind.allCases.count)")
                            .font(.title.weight(.bold))
                            .foregroundStyle(Color("AppPrimary"))
                        ProgressView(value: unlockProgress)
                            .tint(Color("AppAccent"))
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .screenBackground()
    }

    private func chartEmpty(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(Color("AppTextSecondary"))
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
    }

    private func statBlock(_ title: String, _ value: Int, _ symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(Color("AppAccent"))
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
            Text(title)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color("AppBackground").opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
