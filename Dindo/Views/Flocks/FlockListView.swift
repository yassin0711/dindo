import SwiftUI

/// Liste des bandes (en cours ou terminées)
struct FlockListView: View {
    @EnvironmentObject private var flocks: FlockService

    @State private var showFinished = false
    @State private var showForm = false
    @State private var flockToDelete: Flock?   // demande de confirmation avant suppression

    private var list: [Flock] {
        flocks.flocks.filter { $0.isFinished == showFinished }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("flocks.filter".localized, selection: $showFinished) {
                    Text("flocks.active".localized).tag(false)
                    Text("flocks.finished".localized).tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if flocks.isLoading {
                    LoadingStateView()
                } else if list.isEmpty {
                    ContentUnavailableView {
                        Label("flocks.empty.title".localized, systemImage: "bird")
                    } description: {
                        Text("flocks.empty.message".localized)
                    } actions: {
                        Button("flocks.add".localized) { showForm = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(list) { flock in
                            NavigationLink {
                                FlockDetailView(flockID: flock.id ?? "")
                            } label: {
                                FlockRow(flock: flock)
                            }
                            .swipeActions {
                                Button("common.delete".localized, role: .destructive) {
                                    flockToDelete = flock
                                }
                            }
                        }
                    }
                    .animation(.default, value: list)
                }
            }
            .navigationTitle("tab.flocks".localized)
            .toolbar {
                Button {
                    showForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showForm) {
                FlockFormView(flock: nil)
            }
            .alert("flocks.delete.title".localized, isPresented: Binding(
                get: { flockToDelete != nil },
                set: { if !$0 { flockToDelete = nil } }
            )) {
                Button("common.delete".localized, role: .destructive) {
                    if let flockToDelete {
                        flocks.delete(flockToDelete)
                    }
                }
                Button("common.cancel".localized, role: .cancel) {}
            } message: {
                Text("flocks.delete.message".localized)
            }
        }
    }
}
