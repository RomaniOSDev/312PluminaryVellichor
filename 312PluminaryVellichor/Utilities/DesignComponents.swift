import SwiftUI

// MARK: - Neon collage / polaroid language (distinct from soft utility cards)

struct SoftCard<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        content()
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 22)
            .background(Color("AppTextPrimary").opacity(0.08))
            .background(Color("AppSurface"))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color("AppAccent").opacity(0.9),
                                Color("AppPrimary").opacity(0.35),
                                Color("AppAccent").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color("AppPrimary").opacity(0.35), radius: 16, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.35), radius: 4, y: 2)
    }
}

/// Neon outline CTA — hollow glow, not solid gradient fill.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(Color("AppAccent"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(Color("AppPrimary").opacity(configuration.isPressed ? 0.35 : 0.18))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color("AppPrimary"), lineWidth: 2)
            )
            .shadow(color: Color("AppPrimary").opacity(0.65), radius: configuration.isPressed ? 4 : 14, y: 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct FloatingChip: View {
    let title: String
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(selected ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selected ? Color("AppPrimary").opacity(0.35) : Color("AppSurface").opacity(0.85))
                        .rotationEffect(.degrees(selected ? -2 : 2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            selected ? Color("AppAccent") : Color("AppTextSecondary").opacity(0.35),
                            style: StrokeStyle(lineWidth: 1.2, dash: selected ? [] : [4, 3])
                        )
                        .rotationEffect(.degrees(selected ? -2 : 2))
                )
                .shadow(color: selected ? Color("AppPrimary").opacity(0.55) : .clear, radius: 10, y: 0)
        }
        .buttonStyle(.plain)
    }
}

struct AchievementBanner: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Color("AppPrimary"))
                .shadow(color: Color("AppPrimary").opacity(0.9), radius: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(title)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color("AppSurface").opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color("AppPrimary"), lineWidth: 1.5)
        )
        .shadow(color: Color("AppPrimary").opacity(0.55), radius: 18, y: 0)
        .padding(.horizontal, 16)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    let actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color("AppSurface"))
                        .frame(width: 88, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(Color("AppAccent").opacity(0.5), lineWidth: 1)
                        )
                        .rotationEffect(.degrees(Double(i - 1) * 8))
                        .offset(x: CGFloat(i - 1) * 10, y: CGFloat(i - 1) * 4)
                        .shadow(color: Color("AppPrimary").opacity(0.25), radius: 8, y: 4)
                }
                Image(systemName: symbol)
                    .font(.system(size: 36))
                    .foregroundStyle(Color("AppPrimary"))
                    .shadow(color: Color("AppPrimary").opacity(0.8), radius: 12)
            }
            .frame(height: 120)
            Text(title)
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 28)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(actionTitle) {
                HapticService.light()
                action()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Floating neon dock — diamond markers, not system tab look.
struct NeonDockBar: View {
    @Binding var selected: Int
    let items: [(title: String, icon: String)]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    HapticService.tapFeedback()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selected = index }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            if selected == index {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color("AppPrimary").opacity(0.35))
                                    .frame(width: 42, height: 42)
                                    .rotationEffect(.degrees(45))
                                    .shadow(color: Color("AppPrimary").opacity(0.7), radius: 12, y: 0)
                            }
                            Image(systemName: items[index].icon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(selected == index ? Color("AppAccent") : Color("AppTextSecondary"))
                        }
                        .frame(height: 44)
                        Text(items[index].title)
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(selected == index ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color("AppBackground").opacity(0.92))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color("AppPrimary").opacity(0.55), lineWidth: 1.5)
                )
                .shadow(color: Color("AppPrimary").opacity(0.4), radius: 20, y: 0)
                .shadow(color: .black.opacity(0.45), radius: 10, y: 6)
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }
}

struct HexBadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.25))
        path.addLine(to: CGPoint(x: w, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.5, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * 0.75))
        path.addLine(to: CGPoint(x: 0, y: h * 0.25))
        path.closeSubpath()
        return path
    }
}

enum MoodTintStyle {
    static func color(for tint: String) -> Color {
        switch MoodTint(rawValue: tint) {
        case .neon: return Color("AppPrimary")
        case .accent: return Color("AppAccent")
        case .soft: return Color(red: 1.0, green: 0.55, blue: 0.75)
        case .cool: return Color(red: 0.35, green: 0.85, blue: 0.95)
        case .warm: return Color(red: 1.0, green: 0.62, blue: 0.35)
        case .none: return Color("AppPrimary")
        }
    }
}

struct CoachTipBubble: View {
    let text: String
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Color("AppAccent"))
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
                .fixedSize(horizontal: false, vertical: true)
            Button {
                HapticService.light()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color("AppSurface").opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color("AppPrimary").opacity(0.55), lineWidth: 1.2)
        )
        .shadow(color: Color("AppPrimary").opacity(0.35), radius: 12, y: 0)
    }
}

struct UndoBanner: View {
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("Mood deleted")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
            Spacer(minLength: 0)
            Button("Undo") {
                onUndo()
            }
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(Color("AppAccent"))
        }
        .padding(14)
        .background(Color("AppSurface").opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color("AppAccent").opacity(0.55), lineWidth: 1.2)
        )
        .padding(.horizontal, 16)
    }
}
