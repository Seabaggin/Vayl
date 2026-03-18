import SwiftUI

/// Root router: shows OnboardingFlowView or the main tabbed app
/// depending on `hasCompletedOnboarding` (persisted via @AppStorage).



struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if hasCompletedOnboarding {
            tabBar
        } else {
            OnboardingFlowView()
        }
    }
    
    private var tabBar: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)
            
            SessionView()
                .tabItem {
                    Label("Session", systemImage: "flame.fill")
                }
                .tag(AppTab.session)
            
            DesireMapView()
                .tabItem {
                    Label("Desire Map", systemImage: "map.fill")
                }
                .tag(AppTab.kinkMap)
            
            ProgressDashboardView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.progress)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(AppColors.cyan)
        .preferredColorScheme(.dark)
    }
}

enum AppTab: Hashable {
    case home, session, kinkMap, progress, settings
}

#Preview {
    ContentView()
}
