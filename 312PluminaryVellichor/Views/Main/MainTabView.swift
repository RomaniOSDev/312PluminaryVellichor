import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedTab: AppTab = .moods

    private var orderedTabs: [AppTab] {
        store.dockOrder
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("AppBackground")
                .ignoresSafeArea()

            Group {
                switch selectedTab {
                case .moods: MoodsView()
                case .boards: BoardsView()
                case .glow: AchievementsView()
                case .setup: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            NeonDockBar(
                selected: Binding(
                    get: { orderedTabs.firstIndex(of: selectedTab) ?? 0 },
                    set: { index in
                        guard orderedTabs.indices.contains(index) else { return }
                        selectedTab = orderedTabs[index]
                    }
                ),
                items: orderedTabs.map { ($0.title, $0.icon) }
            )
            .zIndex(5)

            if store.showUndoBanner {
                UndoBanner {
                    store.undoDeleteMood()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 120)
                .zIndex(12)
            }

            if let title = store.bannerTitle {
                AchievementBanner(title: title)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 8)
                    .zIndex(10)
            }

            if store.showSuccessFlash {
                Image(systemName: "sparkle")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(Color("AppPrimary"))
                    .shadow(color: Color("AppPrimary").opacity(0.9), radius: 20)
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
                    .zIndex(9)
            }
        }
        .ignoresSafeArea(.keyboard)
        .dismissKeyboardOnTap()
        .onChange(of: store.dockOrder) { order in
            if !order.contains(selectedTab), let first = order.first {
                selectedTab = first
            }
        }
    }
}
