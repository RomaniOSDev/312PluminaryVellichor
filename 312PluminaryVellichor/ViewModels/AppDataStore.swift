import Foundation
import SwiftUI
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var moodEntries: [MoodEntry] = []
    @Published var captionFrames: [CaptionFrame] = []
    @Published var themes: [ThemeSample] = []
    @Published var exploredThemes: Set<String> = []
    @Published var stats: UserStats = UserStats()
    @Published var unlockedAchievements: Set<String> = []
    @Published var hasSeenOnboarding: Bool = false
    @Published var bannerTitle: String?
    @Published var showSuccessFlash: Bool = false
    @Published var dockOrder: [AppTab] = AppTab.defaultOrder
    @Published var hasSeenFABTip: Bool = false
    @Published var hasSeenCaptionsTip: Bool = false
    @Published var undoMood: MoodEntry?
    @Published var showUndoBanner: Bool = false

    private let defaults = UserDefaults.standard
    private let moodsKey = "pv_moods"
    private let captionsKey = "pv_captions"
    private let themesKey = "pv_themes"
    private let exploredKey = "pv_explored"
    private let statsKey = "pv_stats"
    private let unlockedKey = "pv_unlocked"
    private let onboardingKey = "pv_onboarding"
    private let dockKey = "pv_dock_order"
    private let fabTipKey = "pv_tip_fab"
    private let captionsTipKey = "pv_tip_captions"

    private var bannerQueue: [String] = []
    private var isShowingBanner = false
    private var undoWorkItem: DispatchWorkItem?

    static let defaultThemes: [ThemeSample] = [
        ThemeSample(
            id: "nature",
            name: "Nature",
            detail: "Leafy textures, soft greens, and organic collage pieces.",
            imageName: "img_card",
            symbolName: "leaf.fill"
        ),
        ThemeSample(
            id: "urban",
            name: "Urban",
            detail: "City grids, neon signs, and concrete mosaic energy.",
            imageName: "img_banner",
            symbolName: "building.2.fill"
        ),
        ThemeSample(
            id: "abstract",
            name: "Abstract",
            detail: "Bold shapes, floating chips, and surreal color blocks.",
            imageName: "img_accent",
            symbolName: "circle.hexagongrid.fill"
        ),
        ThemeSample(
            id: "ocean",
            name: "Ocean",
            detail: "Deep blues, wave rhythms, and calm coastal layers.",
            imageName: "img_card",
            symbolName: "water.waves"
        ),
        ThemeSample(
            id: "sunset",
            name: "Sunset",
            detail: "Warm glows, horizon bands, and evening collage light.",
            imageName: "img_banner",
            symbolName: "sun.horizon.fill"
        )
    ]

    static let defaultFrames: [CaptionFrame] = [
        CaptionFrame(title: "Neon Bloom", imageName: "img_card", symbolName: "sparkle"),
        CaptionFrame(title: "City Mosaic", imageName: "img_banner", symbolName: "square.grid.3x3.fill"),
        CaptionFrame(title: "Pink Drift", imageName: "img_accent", symbolName: "waveform"),
        CaptionFrame(title: "Harbor Glow", imageName: "img_card", symbolName: "moon.stars.fill"),
        CaptionFrame(title: "Velvet Grid", imageName: "img_banner", symbolName: "rectangle.split.3x3.fill"),
        CaptionFrame(title: "Aura Chip", imageName: "img_accent", symbolName: "circle.grid.cross.fill")
    ]

    private init() {
        load()
        if themes.isEmpty {
            themes = Self.defaultThemes
            persist()
        }
        if captionFrames.isEmpty {
            captionFrames = Self.defaultFrames
            persist()
        }
        ReminderService.refreshIfNeeded()
    }

    // MARK: - Derived

    var themeOfTheWeek: ThemeSample {
        let week = Calendar.current.component(.weekOfYear, from: Date())
        guard !themes.isEmpty else {
            return Self.defaultThemes[0]
        }
        return themes[week % themes.count]
    }

    var weeklyCaptionChallengeProgress: Int {
        let filled = captionFrames.filter {
            !$0.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
        return min(filled, 3)
    }

    var moodsThisWeek: Int {
        moodCount(inWeekOffset: 0)
    }

    var moodsLastWeek: Int {
        moodCount(inWeekOffset: -1)
    }

    var favoriteMoods: [MoodEntry] {
        moodEntries.filter(\.isFavorite)
    }

    var favoriteThemes: [ThemeSample] {
        themes.filter(\.isFavorite)
    }

    // MARK: - Moods (F1)

    @discardableResult
    func addMood(
        emoji: String,
        label: String,
        note: String = "",
        tag: String = MoodTag.chill.rawValue,
        tint: String = MoodTint.neon.rawValue
    ) -> MoodEntry? {
        let text = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let mark = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !mark.isEmpty else { return nil }
        let entry = MoodEntry(
            emoji: mark,
            label: text,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            tag: tag,
            tint: tint
        )
        moodEntries.insert(entry, at: 0)
        stats.itemsAdded += 1
        recordActivity()
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.saveFeedback()
        return entry
    }

    func updateMood(_ entry: MoodEntry) {
        guard let idx = moodEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        moodEntries[idx] = entry
        persist()
        HapticService.light()
    }

    func toggleMoodFavorite(_ entry: MoodEntry) {
        guard let idx = moodEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        moodEntries[idx].isFavorite.toggle()
        persist()
        if moodEntries[idx].isFavorite {
            HapticService.favoriteFeedback()
        } else {
            HapticService.light()
        }
    }

    func deleteMood(_ entry: MoodEntry) {
        moodEntries.removeAll { $0.id == entry.id }
        persist()
        HapticService.warning()
        presentUndo(for: entry)
    }

    func undoDeleteMood() {
        guard let entry = undoMood else { return }
        undoWorkItem?.cancel()
        moodEntries.insert(entry, at: 0)
        undoMood = nil
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showUndoBanner = false
        }
        persist()
        HapticService.tapFeedback()
    }

    func dismissUndoBanner() {
        undoWorkItem?.cancel()
        undoMood = nil
        withAnimation(.easeOut(duration: 0.25)) {
            showUndoBanner = false
        }
    }

    func shuffleMoods() {
        moodEntries.shuffle()
        persist()
        HapticService.tapFeedback()
    }

    // MARK: - Captions (F2)

    func updateCaptionFrame(_ frame: CaptionFrame) {
        guard let idx = captionFrames.firstIndex(where: { $0.id == frame.id }) else { return }
        captionFrames[idx] = frame
        persist()
    }

    func saveAllCaptions(_ frames: [CaptionFrame]) {
        captionFrames = frames
        let written = frames.filter {
            !$0.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
        stats.entriesWritten = max(stats.entriesWritten, written)
        if written > 0 {
            recordActivity()
        }
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.saveFeedback()
    }

    // MARK: - Themes (F3)

    func toggleFavorite(themeId: String) {
        guard let idx = themes.firstIndex(where: { $0.id == themeId }) else { return }
        themes[idx].isFavorite.toggle()
        stats.favouritesCount = themes.filter(\.isFavorite).count
        persist()
        if themes[idx].isFavorite {
            HapticService.favoriteFeedback()
            flashSuccess()
        } else {
            HapticService.light()
        }
        evaluateAchievements()
    }

    func exploreTheme(themeId: String) {
        guard let idx = themes.firstIndex(where: { $0.id == themeId }) else { return }
        themes[idx].exploreCount += 1
        exploredThemes.insert(themeId)
        recordActivity()
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.saveFeedback()
    }

    // MARK: - Dock / Tips

    func moveDockTab(from source: IndexSet, to destination: Int) {
        dockOrder.move(fromOffsets: source, toOffset: destination)
        saveDockOrder()
        HapticService.light()
    }

    func moveDockTabUp(_ tab: AppTab) {
        guard let idx = dockOrder.firstIndex(of: tab), idx > 0 else { return }
        dockOrder.swapAt(idx, idx - 1)
        saveDockOrder()
        HapticService.light()
    }

    func moveDockTabDown(_ tab: AppTab) {
        guard let idx = dockOrder.firstIndex(of: tab), idx < dockOrder.count - 1 else { return }
        dockOrder.swapAt(idx, idx + 1)
        saveDockOrder()
        HapticService.light()
    }

    func markFABTipSeen() {
        hasSeenFABTip = true
        defaults.set(true, forKey: fabTipKey)
    }

    func markCaptionsTipSeen() {
        hasSeenCaptionsTip = true
        defaults.set(true, forKey: captionsTipKey)
    }

    // MARK: - Onboarding / Reset

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: onboardingKey)
        HapticService.unlockFeedback()
    }

    func resetAll() {
        moodEntries = []
        captionFrames = Self.defaultFrames
        themes = Self.defaultThemes
        exploredThemes = []
        stats = UserStats()
        unlockedAchievements = []
        bannerTitle = nil
        bannerQueue.removeAll()
        isShowingBanner = false
        dismissUndoBanner()
        persist()
        NotificationCenter.default.post(name: .dataReset, object: nil)
        HapticService.warning()
    }

    // MARK: - Achievements

    func evaluateAchievements() {
        for kind in AchievementKind.allCases {
            guard kind.isUnlocked(stats: stats) else { continue }
            let key = kind.rawValue
            guard !unlockedAchievements.contains(key) else { continue }
            unlockedAchievements.insert(key)
            enqueueBanner(kind.title)
        }
        persist()
    }

    private func enqueueBanner(_ title: String) {
        bannerQueue.append(title)
        presentNextBannerIfNeeded()
    }

    private func presentNextBannerIfNeeded() {
        guard !isShowingBanner, let next = bannerQueue.first else { return }
        bannerQueue.removeFirst()
        isShowingBanner = true
        HapticService.unlockFeedback()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            bannerTitle = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.35)) {
                self?.bannerTitle = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.isShowingBanner = false
                self?.presentNextBannerIfNeeded()
            }
        }
    }

    func flashSuccess() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showSuccessFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.showSuccessFlash = false
            }
        }
    }

    // MARK: - Calendar helpers

    func isActiveDay(_ date: Date) -> Bool {
        let key = dayKey(date)
        return stats.activeDays.contains(key) || moodEntries.contains { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }
    }

    func moodCount(inWeekOffset offset: Int) -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let targetStart = calendar.date(byAdding: .weekOfYear, value: offset, to: weekStart),
              let targetEnd = calendar.date(byAdding: .day, value: 7, to: targetStart) else {
            return 0
        }
        return moodEntries.filter { $0.createdAt >= targetStart && $0.createdAt < targetEnd }.count
    }

    // MARK: - Persistence

    private func presentUndo(for entry: MoodEntry) {
        undoWorkItem?.cancel()
        undoMood = entry
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showUndoBanner = true
        }
        let work = DispatchWorkItem { [weak self] in
            self?.dismissUndoBanner()
        }
        undoWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
    }

    private func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func recordActivity() {
        let today = dayKey(Date())
        if !stats.activeDays.contains(today) {
            stats.activeDays.append(today)
            if stats.activeDays.count > 120 {
                stats.activeDays = Array(stats.activeDays.suffix(120))
            }
        }
        if stats.lastActiveDay.isEmpty {
            stats.streakDays = 1
            stats.lastActiveDay = today
            return
        }
        if stats.lastActiveDay == today { return }
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           dayKey(yesterday) == stats.lastActiveDay {
            stats.streakDays += 1
        } else {
            stats.streakDays = 1
        }
        stats.lastActiveDay = today
    }

    private func saveDockOrder() {
        defaults.set(dockOrder.map(\.rawValue), forKey: dockKey)
    }

    private func load() {
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
        hasSeenFABTip = defaults.bool(forKey: fabTipKey)
        hasSeenCaptionsTip = defaults.bool(forKey: captionsTipKey)

        if let raw = defaults.array(forKey: dockKey) as? [String] {
            let parsed = raw.compactMap(AppTab.init(rawValue:))
            if Set(parsed) == Set(AppTab.allCases), parsed.count == AppTab.allCases.count {
                dockOrder = parsed
            }
        }

        if let data = defaults.data(forKey: moodsKey),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            moodEntries = decoded
        }
        if let data = defaults.data(forKey: captionsKey),
           let decoded = try? JSONDecoder().decode([CaptionFrame].self, from: data) {
            captionFrames = decoded
        }
        if let data = defaults.data(forKey: themesKey),
           let decoded = try? JSONDecoder().decode([ThemeSample].self, from: data) {
            themes = decoded
        }
        if let arr = defaults.array(forKey: exploredKey) as? [String] {
            exploredThemes = Set(arr)
        }
        if let data = defaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(UserStats.self, from: data) {
            stats = decoded
        }
        if let arr = defaults.array(forKey: unlockedKey) as? [String] {
            unlockedAchievements = Set(arr)
        }
        stats.favouritesCount = themes.filter(\.isFavorite).count
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(moodEntries) {
            defaults.set(data, forKey: moodsKey)
        }
        if let data = try? JSONEncoder().encode(captionFrames) {
            defaults.set(data, forKey: captionsKey)
        }
        if let data = try? JSONEncoder().encode(themes) {
            defaults.set(data, forKey: themesKey)
        }
        defaults.set(Array(exploredThemes), forKey: exploredKey)
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: statsKey)
        }
        defaults.set(Array(unlockedAchievements), forKey: unlockedKey)
        defaults.set(hasSeenOnboarding, forKey: onboardingKey)
        saveDockOrder()
    }
}
