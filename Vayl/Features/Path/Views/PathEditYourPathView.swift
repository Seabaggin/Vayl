import SwiftUI

struct PathEditYourPathView: View {
    @Bindable var store: PathStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.phases) { phase in
                    Section(phase.name) {
                        ForEach(store.landmarks.filter { $0.phaseId == phase.id }) { landmark in
                            Toggle(landmark.title, isOn: Binding(
                                get: { store.state(for: landmark.id) != .skipped },
                                set: { isOn in
                                    Task {
                                        if isOn {
                                            try? await store.restore(landmark.id)
                                        } else {
                                            try? await store.skip(landmark.id)
                                        }
                                    }
                                }
                            ))
                        }
                    }
                }
            }
            .navigationTitle("Edit your path")
        }
    }
}
