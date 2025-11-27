import SwiftUI
import FlowStacks

enum Screen {
    case menu
}

struct Coordinator: View {
    @State var routes: [Route<Screen>] = []
    
    var body: some View {
        FlowStack($routes, withNavigation: true) {
            LoginView()
                .flowDestination(for: Screen.self) { screen in
                    switch screen {
                    case .menu:
                        MenuView()
                    }
                }
        }
    }
}
