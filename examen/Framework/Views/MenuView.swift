import SwiftUI

struct MenuView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Listado")
                }
            
            PerfilView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Perfil")
                }
        }
    }
}
