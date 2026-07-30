import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -27, to: today) else { return [] }
        return (0..<28).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private var weekDelta: Int {
        store.moodsThisWeek - store.moodsLastWeek
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Glow Meter")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(Color("AppTextPrimary"))
                        HStack(spacing: 8) {
                            metric("Moods", store.stats.itemsAdded)
                            metric("Captions", store.stats.entriesWritten)
                            metric("Favs", store.stats.favouritesCount)
                            metric("Streak", store.stats.streakDays)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week vs Last")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(Color("AppTextPrimary"))
                        HStack(spacing: 12) {
                            weekBlock(title: "This week", value: store.moodsThisWeek)
                            weekBlock(title: "Last week", value: store.moodsLastWeek)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: weekDelta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .foregroundStyle(weekDelta >= 0 ? Color("AppAccent") : Color("AppTextSecondary"))
                            Text(weekDelta == 0 ? "Same as last week" : "\(abs(weekDelta)) \(weekDelta > 0 ? "more" : "fewer") moods")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Streak Calendar")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text("Last 28 days")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))

                        let days = calendarDays
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7),
                            spacing: 6
                        ) {
                            ForEach(days, id: \.self) { day in
                                let active = store.isActiveDay(day)
                                let isToday = Calendar.current.isDateInToday(day)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(active ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.18))
                                    .frame(height: 28)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .strokeBorder(
                                                isToday ? Color("AppAccent") : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                    .overlay(
                                        Text("\(Calendar.current.component(.day, from: day))")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(active ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                LazyVGrid(columns: columns, spacing: 22) {
                    ForEach(Array(AchievementKind.allCases.enumerated()), id: \.element.rawValue) { index, kind in
                        hexCard(kind, tilt: index.isMultiple(of: 2) ? -3 : 3)
                    }
                }
                .padding(18)
                .padding(.bottom, 100)
            }
            .navigationTitle("Glow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
        }
    }

    private func weekBlock(title: String, value: Int) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.title2.weight(.heavy))
                .foregroundStyle(Color("AppAccent"))
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color("AppBackground").opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func metric(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color("AppAccent"))
                .shadow(color: Color("AppPrimary").opacity(0.5), radius: 6)
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func hexCard(_ kind: AchievementKind, tilt: Double) -> some View {
        let unlocked = store.unlockedAchievements.contains(kind.rawValue) || kind.isUnlocked(stats: store.stats)
        let progress = min(kind.progress(stats: store.stats), kind.goal)
        return VStack(spacing: 10) {
            ZStack {
                HexBadgeShape()
                    .fill(Color("AppSurface"))
                    .frame(width: 72, height: 80)
                    .overlay(
                        HexBadgeShape()
                            .stroke(unlocked ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.35), lineWidth: 2)
                    )
                    .shadow(color: unlocked ? Color("AppPrimary").opacity(0.55) : .clear, radius: 12, y: 0)
                Image(systemName: kind.icon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(unlocked ? Color("AppAccent") : Color("AppTextSecondary"))
            }
            Text(kind.title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(height: 32)
            Text(kind.detail)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
                .frame(height: 42)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color("AppTextSecondary").opacity(0.25))
                    Capsule()
                        .fill(Color("AppPrimary"))
                        .frame(width: geo.size.width * CGFloat(progress) / CGFloat(max(kind.goal, 1)))
                        .shadow(color: Color("AppPrimary").opacity(0.6), radius: 4)
                }
            }
            .frame(height: 5)
            Text("\(progress)/\(kind.goal)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(12)
        .background(Color("AppBackground").opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color("AppAccent").opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
        )
        .rotationEffect(.degrees(tilt))
        .opacity(unlocked ? 1 : 0.7)
    }
}
