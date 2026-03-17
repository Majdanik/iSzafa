import SwiftUI
import SwiftData

@main
struct iSzafaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ClothingItem.self)
    }
}
