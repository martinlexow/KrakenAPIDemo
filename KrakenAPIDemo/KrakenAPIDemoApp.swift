

import SwiftUI

@main
struct KrakenAPIDemoApp: App {
    
    @StateObject private var model: Model = Model()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.model)
        }
    }
    
}
