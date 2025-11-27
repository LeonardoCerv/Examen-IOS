import SwiftUI
import FlowStacks

struct PerfilView: View {
    @StateObject var vm = PerfilViewModel()
    @EnvironmentObject var navigator: FlowNavigator<Screen>
    
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Text(vm.email.isEmpty ? "—" : vm.email)
                .font(.headline)
            
            Button {
                vm.logOut()
                navigator.goBackToRoot()
            } label: {
                Label("Cerrar sesión", systemImage: "power")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            vm.getCurrentUser()
        }
        .padding()
    }
}
