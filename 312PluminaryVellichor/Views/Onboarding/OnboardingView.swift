import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page = 0
    @State private var appearScale: CGFloat = 0.7
    @State private var appearOpacity: Double = 0
    @State private var chipFloat: CGFloat = 0

    private let pages: [(title: String, body: String, symbol: String, image: String)] = [
        (
            "Explore Creativity",
            "Discover how this app helps you organize your media into thematic collections.",
            "sparkles.rectangle.stack",
            "img_banner"
        ),
        (
            "Create Moodboards",
            "Drag and drop images to create vibrant moodboards showcasing different themes.",
            "rectangle.3.group.fill",
            "img_card"
        ),
        (
            "Start Organizing",
            "Begin by selecting your first set of images to build a theme-based collection.",
            "square.grid.3x3.fill",
            "img_accent"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index], index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: page)

            HStack(spacing: 14) {
                ForEach(pages.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(index == page ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.35))
                        .frame(width: 14, height: 14)
                        .rotationEffect(.degrees(45))
                        .shadow(color: index == page ? Color("AppPrimary").opacity(0.7) : .clear, radius: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: page)
                }
            }
            .padding(.bottom, 18)

            Button {
                HapticService.light()
                if page < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                } else {
                    store.completeOnboarding()
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground").ignoresSafeArea())
        .onChange(of: page) { _ in
            appearScale = 0.7
            appearOpacity = 0
            chipFloat = 0
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1
                appearOpacity = 1
                chipFloat = 1
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1
                appearOpacity = 1
                chipFloat = 1
            }
        }
    }

    private func onboardingPage(
        _ item: (title: String, body: String, symbol: String, image: String),
        index: Int
    ) -> some View {
        VStack(spacing: 26) {
            Spacer(minLength: 20)

            ZStack {
                Image(item.image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(index == page ? appearScale : 0.92)
                    .opacity(index == page ? appearOpacity : 0.65)

                LinearGradient(
                    colors: [
                        Color("AppBackground").opacity(0.1),
                        Color("AppBackground").opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 14) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(Color("AppPrimary"))
                        .padding(20)
                        .background(
                            Circle()
                                .fill(Color("AppBackground").opacity(0.75))
                                .shadow(color: Color("AppPrimary").opacity(0.55), radius: 18)
                        )
                        .scaleEffect(index == page ? appearScale : 0.85)

                    HStack(spacing: 8) {
                        floatingLabel("Neon", offset: -8)
                        floatingLabel("Collage", offset: 6)
                        floatingLabel("Mood", offset: -4)
                    }
                    .opacity(index == page ? appearOpacity : 0.4)
                    .offset(y: chipFloat * -6)
                }
            }
            .frame(height: 280)
            .padding(10)
            .background(Color("AppTextPrimary").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color("AppPrimary"), lineWidth: 1.5)
            )
            .shadow(color: Color("AppPrimary").opacity(0.45), radius: 22, y: 0)
            .rotationEffect(.degrees(index == page ? -1.5 : 1.5))
            .padding(.horizontal, 28)

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .shadow(color: Color("AppPrimary").opacity(0.45), radius: 10)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(item.body)
                    .font(.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 28)
            }

            Spacer()
        }
    }

    private func floatingLabel(_ text: String, offset: CGFloat) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color("AppPrimary").opacity(0.55))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color("AppAccent"), lineWidth: 1))
            .offset(y: offset)
    }
}
