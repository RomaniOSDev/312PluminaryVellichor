import SwiftUI

struct BoardsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var segment = 0
    @State private var draftFrames: [CaptionFrame] = []
    @State private var savedFlash = false
    @State private var searchText = ""

    private var filteredThemes: [ThemeSample] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return store.themes }
        return store.themes.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.detail.localizedCaseInsensitiveContains(query)
        }
    }

    private func matchesCaptionSearch(_ frame: CaptionFrame) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return frame.title.localizedCaseInsensitiveContains(query)
            || frame.caption.localizedCaseInsensitiveContains(query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    FloatingChip(title: "Captions", selected: segment == 0) {
                        HapticService.light()
                        segment = 0
                    }
                    FloatingChip(title: "Themes", selected: segment == 1) {
                        HapticService.light()
                        segment = 1
                    }
                    FloatingChip(title: "Favorites", selected: segment == 2) {
                        HapticService.light()
                        segment = 2
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                if segment != 2 {
                    searchField
                }

                if segment == 0 {
                    captionsPane
                } else if segment == 1 {
                    themesPane
                } else {
                    favoritesPane
                }
            }
            .navigationTitle("Boards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .overlay(alignment: .top) {
                if segment == 0, !store.hasSeenCaptionsTip {
                    CoachTipBubble(text: "Write captions on cards, then tap Save All to lock your board.") {
                        store.markCaptionsTipSeen()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 58)
                    .zIndex(20)
                }
            }
            .onAppear {
                draftFrames = store.captionFrames
            }
            .onChange(of: store.captionFrames) { frames in
                if !savedFlash {
                    draftFrames = frames
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
                draftFrames = store.captionFrames
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("AppTextSecondary"))
            TextField(segment == 0 ? "Search captions" : "Search themes", text: $searchText)
                .foregroundStyle(Color("AppTextPrimary"))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(12)
        .background(Color("AppSurface").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Captions

    private var captionsPane: some View {
        VStack(spacing: 0) {
            ScrollView {
                themeOfWeekCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 14
                ) {
                    ForEach($draftFrames) { $frame in
                        if matchesCaptionSearch(frame) {
                            captionCard($frame)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()

            Button {
                if !store.hasSeenCaptionsTip {
                    store.markCaptionsTipSeen()
                }
                savedFlash = true
                store.saveAllCaptions(draftFrames)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    savedFlash = false
                }
            } label: {
                Text("Save All")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }

    private var themeOfWeekCard: some View {
        let theme = store.themeOfTheWeek
        let progress = store.weeklyCaptionChallengeProgress
        return SoftCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Theme of the Week")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Image(systemName: theme.symbolName)
                        .foregroundStyle(Color("AppAccent"))
                }
                HStack(spacing: 12) {
                    Image(theme.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text("Write 3 captions this week")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                ProgressView(value: Double(progress), total: 3)
                    .tint(Color("AppPrimary"))
                Text("\(progress)/3 captions filled")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
            }
        }
    }

    private func captionCard(_ frame: Binding<CaptionFrame>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                Image(frame.wrappedValue.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 96)
                    .clipped()

                LinearGradient(
                    colors: [.clear, Color("AppBackground").opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack {
                    Image(systemName: frame.wrappedValue.symbolName)
                        .foregroundStyle(Color("AppAccent"))
                    Text(frame.wrappedValue.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))

            TextField("Caption", text: frame.caption, axis: .vertical)
                .lineLimit(2...3)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color("AppTextPrimary"))
                .padding(8)
                .background(Color("AppBackground").opacity(0.45))
                .overlay(
                    Rectangle()
                        .strokeBorder(Color("AppAccent").opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                )

            DatePicker(
                "",
                selection: frame.date,
                displayedComponents: .date
            )
            .labelsHidden()
            .tint(Color("AppPrimary"))
            .colorScheme(.dark)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(Color("AppPrimary").opacity(0.45), lineWidth: 1.2)
        )
        .shadow(color: Color("AppPrimary").opacity(0.28), radius: 12, y: 5)
        .rotationEffect(.degrees(frame.wrappedValue.title.hashValue % 2 == 0 ? -2.2 : 2.2))
    }

    // MARK: - Themes

    private var themesPane: some View {
        ScrollView {
            VStack(spacing: 14) {
                SoftCard {
                    HStack {
                        Image("img_banner")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Theme Sampler")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("\(store.exploredThemes.count) explored · \(store.stats.favouritesCount) favorites")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer(minLength: 0)
                    }
                }

                ForEach(filteredThemes) { theme in
                    themeCard(theme)
                }
            }
            .padding(16)
            .padding(.bottom, 110)
        }
    }

    private func themeCard(_ theme: ThemeSample) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Image(theme.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipped()
                        Color("AppBackground").opacity(0.25)
                        Image(systemName: theme.symbolName)
                            .font(.title2)
                            .foregroundStyle(Color("AppPrimary"))
                            .shadow(color: Color("AppPrimary").opacity(0.6), radius: 8)
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color("AppAccent").opacity(0.45), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(theme.name)
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            if store.exploredThemes.contains(theme.id) {
                                Text("Explored")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color("AppPrimary").opacity(0.45))
                                    .clipShape(Capsule())
                            }
                        }
                        Text(theme.detail)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                        Text("Explored \(theme.exploreCount)×")
                            .font(.caption2)
                            .foregroundStyle(Color("AppAccent"))
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        store.toggleFavorite(themeId: theme.id)
                    } label: {
                        Label(
                            theme.isFavorite ? "Favorited" : "Favorite",
                            systemImage: theme.isFavorite ? "heart.fill" : "heart"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color("AppPrimary").opacity(theme.isFavorite ? 0.45 : 0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.exploreTheme(themeId: theme.id)
                    } label: {
                        Label("Explore", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color("AppPrimary"), Color("AppAccent")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Favorites

    private var favoritesPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favorites Board")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text("\(store.favoriteMoods.count) moods · \(store.favoriteThemes.count) themes")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }

                if store.favoriteMoods.isEmpty && store.favoriteThemes.isEmpty {
                    Text("Heart a mood or theme to collect it here.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }

                if !store.favoriteThemes.isEmpty {
                    Text("Themes")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(Color("AppAccent"))
                    ForEach(store.favoriteThemes) { theme in
                        themeCard(theme)
                    }
                }

                if !store.favoriteMoods.isEmpty {
                    Text("Moods")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(Color("AppAccent"))
                        .padding(.top, 4)
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 14
                    ) {
                        ForEach(store.favoriteMoods) { entry in
                            favoriteMoodCard(entry)
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 110)
        }
    }

    private func favoriteMoodCard(_ entry: MoodEntry) -> some View {
        let tint = MoodTintStyle.color(for: entry.tint)
        return VStack(spacing: 8) {
            Text(entry.emoji)
                .font(.system(size: 36))
            Text(entry.label)
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text(entry.tag)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(tint.opacity(0.6), lineWidth: 1.2)
        )
        .onTapGesture {
            store.toggleMoodFavorite(entry)
        }
    }
}
