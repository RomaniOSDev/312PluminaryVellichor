import Foundation

enum MoodTag: String, CaseIterable, Codable, Identifiable {
    case chill = "Chill"
    case energy = "Energy"
    case dream = "Dream"
    case focus = "Focus"
    case soft = "Soft"

    var id: String { rawValue }
}

enum MoodTint: String, CaseIterable, Codable, Identifiable {
    case neon
    case accent
    case soft
    case cool
    case warm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neon: return "Neon"
        case .accent: return "Accent"
        case .soft: return "Soft"
        case .cool: return "Cool"
        case .warm: return "Warm"
        }
    }
}

struct MoodEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var emoji: String
    var label: String
    var createdAt: Date
    var note: String
    var tag: String
    var tint: String
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        emoji: String,
        label: String,
        createdAt: Date = Date(),
        note: String = "",
        tag: String = MoodTag.chill.rawValue,
        tint: String = MoodTint.neon.rawValue,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.emoji = emoji
        self.label = label
        self.createdAt = createdAt
        self.note = note
        self.tag = tag
        self.tint = tint
        self.isFavorite = isFavorite
    }

    enum CodingKeys: String, CodingKey {
        case id, emoji, label, createdAt, note, tag, tint, isFavorite
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        emoji = try c.decode(String.self, forKey: .emoji)
        label = try c.decode(String.self, forKey: .label)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        tag = try c.decodeIfPresent(String.self, forKey: .tag) ?? MoodTag.chill.rawValue
        tint = try c.decodeIfPresent(String.self, forKey: .tint) ?? MoodTint.neon.rawValue
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
}

enum AppTab: String, CaseIterable, Identifiable, Codable {
    case moods
    case boards
    case glow
    case setup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .moods: return "Moods"
        case .boards: return "Boards"
        case .glow: return "Glow"
        case .setup: return "Setup"
        }
    }

    var icon: String {
        switch self {
        case .moods: return "face.smiling.fill"
        case .boards: return "square.grid.2x2.fill"
        case .glow: return "sparkles"
        case .setup: return "slider.horizontal.2.square"
        }
    }

    static let defaultOrder: [AppTab] = [.moods, .boards, .glow, .setup]
}
