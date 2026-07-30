import UIKit
import AudioToolbox
import UserNotifications

enum SoundPack: String, CaseIterable, Identifiable {
    case soft
    case neon
    case crisp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soft: return "Soft"
        case .neon: return "Neon"
        case .crisp: return "Crisp"
        }
    }

    var tapSound: SystemSoundID {
        switch self {
        case .soft: return 1104
        case .neon: return 1113
        case .crisp: return 1105
        }
    }

    var saveSound: SystemSoundID {
        switch self {
        case .soft: return 1003
        case .neon: return 1057
        case .crisp: return 1306
        }
    }

    var favoriteSound: SystemSoundID {
        switch self {
        case .soft: return 1007
        case .neon: return 1114
        case .crisp: return 1103
        }
    }
}

enum HapticService {
    private static let soundKey = "pv_sound_enabled"
    private static let hapticsKey = "pv_haptics_enabled"
    private static let packKey = "pv_sound_pack"

    static var soundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: soundKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: soundKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: soundKey)
            UserDefaults.standard.synchronize()
        }
    }

    static var hapticsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: hapticsKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: hapticsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hapticsKey)
            UserDefaults.standard.synchronize()
        }
    }

    static var soundPack: SoundPack {
        get {
            let raw = UserDefaults.standard.string(forKey: packKey) ?? SoundPack.neon.rawValue
            return SoundPack(rawValue: raw) ?? .neon
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: packKey)
            UserDefaults.standard.synchronize()
        }
    }

    static func light() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func medium() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    static func heavy() {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    static func success() {
        unlockFeedback()
    }

    static func warning() {
        guard hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    static func saveFeedback() {
        if hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                guard hapticsEnabled else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        play(soundPack.saveSound)
    }

    static func favoriteFeedback() {
        if hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.prepare()
            generator.impactOccurred()
        }
        play(soundPack.favoriteSound)
    }

    static func unlockFeedback() {
        if hapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                guard hapticsEnabled else { return }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
        play(soundPack.saveSound)
    }

    static func tapFeedback() {
        light()
        play(soundPack.tapSound)
    }

    static func play(_ id: SystemSoundID) {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(id)
    }

    static func previewPack(_ pack: SoundPack) {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(pack.tapSound)
    }
}

enum ReminderService {
    static let reminderId = "pv_daily_mood_reminder"
    private static let enabledKey = "pv_daily_reminder_enabled"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
            if newValue {
                scheduleDaily()
            } else {
                cancel()
            }
        }
    }

    static func requestAccessAndEnable(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    isEnabled = true
                    scheduleDaily()
                } else {
                    isEnabled = false
                }
                completion?(granted)
            }
        }
    }

    static func scheduleDaily() {
        guard isEnabled else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderId])

        let content = UNMutableNotificationContent()
        content.title = "Mood check-in"
        content.body = "How are you feeling? Pin a mood chip for today."
        content.sound = .default

        var date = DateComponents()
        date.hour = 19
        date.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: reminderId, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderId])
    }

    static func refreshIfNeeded() {
        if isEnabled { scheduleDaily() }
    }
}
