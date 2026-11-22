import SwiftUI

enum AppTab: String {
    case dashboard, flocks, farm, settings
}

struct MainTabView: View {
    @EnvironmentObject private var flocks: FlockService
    // @AppStorage : l'onglet choisi est conservé même quand l'interface est reconstruite
    @AppStorage("selectedTab") private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("tab.dashboard".localized, systemImage: "house.fill") }
                .tag(AppTab.dashboard)

            FlockListView()
                .tabItem { Label("tab.flocks".localized, systemImage: "bird.fill") }
                .tag(AppTab.flocks)

            FarmView()
                .tabItem { Label("tab.farm".localized, systemImage: "map.fill") }
                .tag(AppTab.farm)

            SettingsView()
                .tabItem { Label("tab.settings".localized, systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        // Bandes Firestore de l'éleveur connecté, mises à jour en temps réel
        .onAppear {
            flocks.startListening()
        }
        // Une lecture ou une écriture Firestore a échoué : message clair pour l'utilisateur
        .alert("state.error.title".localized, isPresented: $flocks.showError) {
        } message: {
            Text("error.firestore".localized)
        }
    }
}
