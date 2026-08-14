import SwiftUI

@main
struct NanoBananaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 860, minHeight: 640)
        }
        .windowResizability(.contentMinSize)
    }
}
