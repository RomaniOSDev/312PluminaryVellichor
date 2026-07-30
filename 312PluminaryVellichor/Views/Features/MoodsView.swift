import SwiftUI

struct MoodsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showEditor = false
    @State private var editing: MoodEntry?
    @State private var selectedChip: String = "All"
    @State private var selectedTag: String = "All"
    @State private var searchText = ""
    @State private var mosaicPulse = false

    private let emojiPool = ["😊", "🤩", "🌙", "🔥", "💫", "🌸", "🌊", "🎨", "💜", "✨"]

    private var filtered: [MoodEntry] {
        store.moodEntries.filter { entry in
            let emojiOK = selectedChip == "All" || entry.emoji == selectedChip
            let tagOK = selectedTag == "All" || entry.tag == selectedTag
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchOK = query.isEmpty
                || entry.label.localizedCaseInsensitiveContains(query)
                || entry.note.localizedCaseInsensitiveContains(query)
                || entry.tag.localizedCaseInsensitiveContains(query)
            return emojiOK && tagOK && searchOK
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.moodEntries.isEmpty {
                    EmptyStateView(
                        symbol: "face.smiling",
                        title: "No moods yet",
                        message: "Pin emoji moods as floating collage chips to start your board.",
                        actionTitle: "Add Mood"
                    ) {
                        editing = nil
                        showEditor = true
                    }
                } else {
                    VStack(spacing: 0) {
                        searchField
                        chipRow
                            .padding(.top, 6)
                            .padding(.bottom, 4)
                        tagRow
                            .padding(.bottom, 8)

                        ScrollView {
                            SoftCard {
                                HStack(spacing: 14) {
                                    Image("img_accent")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 72)
                                        .clipped()
                                        .rotationEffect(.degrees(-4))
                                        .scaleEffect(mosaicPulse ? 1.04 : 1.0)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Mood Mosaic")
                                            .font(.headline.weight(.heavy))
                                            .foregroundStyle(Color("AppTextPrimary"))
                                        Text("\(store.moodEntries.count) chips curated")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                    Spacer(minLength: 0)
                                    Button {
                                        store.shuffleMoods()
                                    } label: {
                                        Image(systemName: "shuffle")
                                            .font(.body.weight(.bold))
                                            .foregroundStyle(Color("AppAccent"))
                                            .frame(width: 40, height: 40)
                                            .background(Color("AppPrimary").opacity(0.25))
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Shuffle collage")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 14),
                                    GridItem(.flexible(), spacing: 14)
                                ],
                                spacing: 18
                            ) {
                                ForEach(Array(filtered.enumerated()), id: \.element.id) { index, entry in
                                    moodTile(entry, tilted: index.isMultiple(of: 2))
                                        .contextMenu {
                                            Button {
                                                editing = entry
                                                showEditor = true
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            Button {
                                                store.toggleMoodFavorite(entry)
                                            } label: {
                                                Label(
                                                    entry.isFavorite ? "Unfavorite" : "Favorite",
                                                    systemImage: entry.isFavorite ? "heart.slash" : "heart"
                                                )
                                            }
                                            Button(role: .destructive) {
                                                store.deleteMood(entry)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .onTapGesture {
                                            HapticService.light()
                                            editing = entry
                                            showEditor = true
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 110)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                if !store.moodEntries.isEmpty {
                    ZStack(alignment: .bottomTrailing) {
                        if !store.hasSeenFABTip {
                            CoachTipBubble(text: "Tap + to pin a new mood chip to your mosaic.") {
                                store.markFABTipSeen()
                            }
                            .frame(maxWidth: 220)
                            .padding(.trailing, 18)
                            .padding(.bottom, 92)
                        }

                        Button {
                            HapticService.tapFeedback()
                            editing = nil
                            showEditor = true
                            if !store.hasSeenFABTip {
                                store.markFABTipSeen()
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.black))
                                .foregroundStyle(Color("AppAccent"))
                                .frame(width: 58, height: 58)
                                .background(Color("AppPrimary").opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .rotationEffect(.degrees(45))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(Color("AppPrimary"), lineWidth: 2)
                                        .rotationEffect(.degrees(45))
                                )
                                .shadow(color: Color("AppPrimary").opacity(0.7), radius: 16, y: 0)
                        }
                        .padding(26)
                        .padding(.bottom, 100)
                        .accessibilityLabel("Add Mood")
                    }
                }
            }
            .navigationTitle("Moods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .sheet(isPresented: $showEditor) {
                MoodEditorSheet(entry: editing) { emoji, label, note, tag, tint in
                    if var current = editing {
                        current.emoji = emoji
                        current.label = label
                        current.note = note
                        current.tag = tag
                        current.tint = tint
                        store.updateMood(current)
                    } else {
                        store.addMood(emoji: emoji, label: label, note: note, tag: tag, tint: tint)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    mosaicPulse = true
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("AppTextSecondary"))
            TextField("Search moods & notes", text: $searchText)
                .foregroundStyle(Color("AppTextPrimary"))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(12)
        .background(Color("AppSurface").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FloatingChip(title: "All", selected: selectedChip == "All") {
                    HapticService.light()
                    selectedChip = "All"
                }
                ForEach(emojiPool, id: \.self) { emoji in
                    FloatingChip(title: emoji, selected: selectedChip == emoji) {
                        HapticService.light()
                        selectedChip = emoji
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FloatingChip(title: "All tags", selected: selectedTag == "All") {
                    HapticService.light()
                    selectedTag = "All"
                }
                ForEach(MoodTag.allCases) { tag in
                    FloatingChip(title: tag.rawValue, selected: selectedTag == tag.rawValue) {
                        HapticService.light()
                        selectedTag = tag.rawValue
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func moodTile(_ entry: MoodEntry, tilted: Bool) -> some View {
        let tint = MoodTintStyle.color(for: entry.tint)
        return VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Text(entry.emoji)
                    .font(.system(size: 42))
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(tint.opacity(0.22))
                if entry.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                        .padding(6)
                }
            }
            Text(entry.label)
                .font(.caption.weight(.heavy))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 6)
            Text(entry.tag)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }
            Text(entry.createdAt, style: .date)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .padding(.bottom, 4)
        }
        .padding(.top, 10)
        .padding(.horizontal, 8)
        .padding(.bottom, 14)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(tint.opacity(0.7), lineWidth: 1.2)
        )
        .shadow(color: tint.opacity(0.35), radius: 12, y: 4)
        .rotationEffect(.degrees(tilted ? -3.5 : 3.5))
    }
}

struct MoodEditorSheet: View {
    let entry: MoodEntry?
    var onSave: (_ emoji: String, _ label: String, _ note: String, _ tag: String, _ tint: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var emoji: String = "😊"
    @State private var label: String = ""
    @State private var note: String = ""
    @State private var tag: String = MoodTag.chill.rawValue
    @State private var tint: String = MoodTint.neon.rawValue

    private let emojiPool = ["😊", "🤩", "🌙", "🔥", "💫", "🌸", "🌊", "🎨", "💜", "✨"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Pick an emoji")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 5),
                        spacing: 10
                    ) {
                        ForEach(emojiPool, id: \.self) { mark in
                            Button {
                                HapticService.light()
                                emoji = mark
                            } label: {
                                Text(mark)
                                    .font(.system(size: 28))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(emoji == mark ? Color("AppPrimary").opacity(0.4) : Color("AppSurface"))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(emoji == mark ? Color("AppAccent") : Color.clear, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Short mood text")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    TextField("Soft neon calm", text: $label)
                        .padding(14)
                        .background(Color("AppSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text("Note")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    TextField("Optional longer note…", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(Color("AppSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text("Tag")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MoodTag.allCases) { item in
                                FloatingChip(title: item.rawValue, selected: tag == item.rawValue) {
                                    HapticService.light()
                                    tag = item.rawValue
                                }
                            }
                        }
                    }

                    Text("Color")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    HStack(spacing: 10) {
                        ForEach(MoodTint.allCases) { item in
                            Button {
                                HapticService.light()
                                tint = item.rawValue
                            } label: {
                                Circle()
                                    .fill(MoodTintStyle.color(for: item.rawValue))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                tint == item.rawValue ? Color("AppTextPrimary") : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.title)
                        }
                    }

                    Button {
                        HapticService.saveFeedback()
                        onSave(emoji, label, note, tag, tint)
                        dismiss()
                    } label: {
                        Text("Save Mood")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle(entry == nil ? "Add Mood" : "Edit Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .onAppear {
                if let entry {
                    emoji = entry.emoji
                    label = entry.label
                    note = entry.note
                    tag = entry.tag
                    tint = entry.tint
                }
            }
        }
    }
}
