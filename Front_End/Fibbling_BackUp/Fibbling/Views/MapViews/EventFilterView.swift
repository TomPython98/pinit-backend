import SwiftUI

struct EventFilterView: View {
    @Binding var filterQuery: String
    @Binding var filterPrivateOnly: Bool
    @Binding var filterCertifiedOnly: Bool
    @Binding var filterEventType: EventType?
    @Binding var isPresented: Bool
    @State private var useSemanticSearch: Bool = false
    
    var onApply: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Search")) {
                    TextField("Search events", text: $filterQuery)
                    
                    Toggle("Use AI-powered semantic search", isOn: $useSemanticSearch)
                        .tint(.blue)
                    
                    if useSemanticSearch {
                        Text("Semantic search finds events based on meaning, not just keywords")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Filters")) {
                    Toggle("Private Events Only", isOn: $filterPrivateOnly)
                        .tint(.blue)
                    
                    Toggle("Certified Hosts Only", isOn: $filterCertifiedOnly)
                        .tint(.blue)
                }
                
                Section(header: Text("Event Type")) {
                    Picker("Event Type", selection: $filterEventType) {
                        Text("All Types").tag(nil as EventType?)
                        ForEach(EventType.allCases) { type in
                            Text(type.displayName).tag(type as EventType?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Button("Apply Filters") {
                    // Save the semantic search setting to UserDefaults
                    UserDefaults.standard.set(useSemanticSearch, forKey: "useSemanticSearch")
                    onApply()
                    isPresented = false
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Filter Events")
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
            .onAppear {
                // Load the semantic search setting from UserDefaults
                useSemanticSearch = UserDefaults.standard.bool(forKey: "useSemanticSearch")
            }
        }
    }
}
