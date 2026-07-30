import Foundation

enum AchievementKind: String, Codable, CaseIterable {
    case firstTheme
    case moodboardMaker
    case explorer
    case gettingGoing
    case powerUser
    case activeUser
    case dedicatedUser
    case threeDayStreak

    var title: String {
        switch self {
        case .firstTheme: return "First Theme"
        case .moodboardMaker: return "Moodboard Maker"
        case .explorer: return "Explorer"
        case .gettingGoing: return "Getting Going"
        case .powerUser: return "Power User"
        case .activeUser: return "Active User"
        case .dedicatedUser: return "Dedicated User"
        case .threeDayStreak: return "Three-Day Streak"
        }
    }

    var detail: String {
        switch self {
        case .firstTheme: return "Added your first mood item"
        case .moodboardMaker: return "Wrote your first moodboard caption"
        case .explorer: return "Saved five moodboard captions"
        case .gettingGoing: return "Curated ten mood items"
        case .powerUser: return "Reached fifty mood items"
        case .activeUser: return "Saved ten captions"
        case .dedicatedUser: return "Saved fifty captions"
        case .threeDayStreak: return "Used the app three days in a row"
        }
    }

    var icon: String {
        switch self {
        case .firstTheme: return "sparkles"
        case .moodboardMaker: return "rectangle.stack.fill"
        case .explorer: return "binoculars.fill"
        case .gettingGoing: return "flame.fill"
        case .powerUser: return "bolt.fill"
        case .activeUser: return "star.fill"
        case .dedicatedUser: return "crown.fill"
        case .threeDayStreak: return "calendar"
        }
    }

    var goal: Int {
        switch self {
        case .firstTheme: return 1
        case .moodboardMaker: return 1
        case .explorer: return 5
        case .gettingGoing: return 10
        case .powerUser: return 50
        case .activeUser: return 10
        case .dedicatedUser: return 50
        case .threeDayStreak: return 3
        }
    }

    func progress(stats: UserStats) -> Int {
        switch self {
        case .firstTheme, .gettingGoing, .powerUser:
            return stats.itemsAdded
        case .moodboardMaker, .explorer, .activeUser, .dedicatedUser:
            return stats.entriesWritten
        case .threeDayStreak:
            return stats.streakDays
        }
    }

    func isUnlocked(stats: UserStats) -> Bool {
        progress(stats: stats) >= goal
    }
}

struct UserStats: Codable, Equatable {
    var itemsAdded: Int = 0
    var entriesWritten: Int = 0
    var favouritesCount: Int = 0
    var streakDays: Int = 0
    var lastActiveDay: String = ""
    var activeDays: [String] = []

    enum CodingKeys: String, CodingKey {
        case itemsAdded, entriesWritten, favouritesCount, streakDays, lastActiveDay, activeDays
    }

    init(
        itemsAdded: Int = 0,
        entriesWritten: Int = 0,
        favouritesCount: Int = 0,
        streakDays: Int = 0,
        lastActiveDay: String = "",
        activeDays: [String] = []
    ) {
        self.itemsAdded = itemsAdded
        self.entriesWritten = entriesWritten
        self.favouritesCount = favouritesCount
        self.streakDays = streakDays
        self.lastActiveDay = lastActiveDay
        self.activeDays = activeDays
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        itemsAdded = try c.decodeIfPresent(Int.self, forKey: .itemsAdded) ?? 0
        entriesWritten = try c.decodeIfPresent(Int.self, forKey: .entriesWritten) ?? 0
        favouritesCount = try c.decodeIfPresent(Int.self, forKey: .favouritesCount) ?? 0
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        lastActiveDay = try c.decodeIfPresent(String.self, forKey: .lastActiveDay) ?? ""
        activeDays = try c.decodeIfPresent([String].self, forKey: .activeDays) ?? []
    }
}

extension Notification.Name {
    static let dataReset = Notification.Name("pv_dataReset")
}
