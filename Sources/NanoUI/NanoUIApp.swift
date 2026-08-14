import SwiftUI

@main
struct NanoUIApp: App {
    var body: some Scene {
        WindowGroup("NanoUI") {
            ContentView()
                .frame(minWidth: 860, minHeight: 640)
        }
        .windowResizability(.contentMinSize)
    }
}
