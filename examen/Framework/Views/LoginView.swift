import SwiftUI
import FlowStacks

struct LoginView: View {
    @EnvironmentObject var navigator: FlowNavigator<Screen>
    @StateObject var vm = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            TextField(text: $vm.email) {
                Text("Correo Electrónico")
            }
            .multilineTextAlignment(.center)
            .keyboardType(.emailAddress)
            .padding()
            .font(.title3)
            .textInputAutocapitalization(.never)
            
            Divider()
            
            Button {
                vm.setCurrentUser()
                // Si el usuario es válido, navegamos. 
                // La lógica original decía "navigator.presentCover(.menu)"
                // pero si setCurrentUser falla (email vacío) no deberíamos navegar.
                // Sin embargo, el VM pone showAlert = true.
                // Vamos a chequear si se guardó.
                if !vm.email.isEmpty {
                    navigator.presentCover(.menu)
                }
            } label: {
                Text("Acceder")
            }
            .padding()
        }
        .onAppear {
            vm.getCurrentUser()
            if !vm.email.isEmpty {
                navigator.presentCover(.menu)
            }
        }
        .padding()
        .alert(isPresented: $vm.showAlert) {
            Alert(title: Text("Oops!"), message: Text(vm.messageAlert))
        }
    }
}
