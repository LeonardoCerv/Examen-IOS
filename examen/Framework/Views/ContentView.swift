import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject var vm = ItemListViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Buscar país (ej. Canada, Italy)", text: $vm.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.words)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await vm.search() }
                        }
                    
                    Button {
                        Task { await vm.search() }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                if vm.isLoading {
                    Spacer()
                    ProgressView("Cargando datos...")
                    Spacer()
                } else if vm.hasError {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Ocurrió un error")
                            .font(.headline)
                        Text(vm.errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button("Reintentar") {
                            Task { await vm.search() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else if vm.items.isEmpty {
                    Spacer()
                    Text("Ingresa un país para ver los datos.")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(vm.items) { item in
                        NavigationLink {
                            ItemDetailView(item: item)
                        } label: {
                            HStack {
                                if let urlStr = item.detail?.media?.primary, let url = URL(string: urlStr) {
                                    WebImage(url: url).resizable().scaledToFit().frame(width: 48, height: 48)
                                }
                                Text(item.ref.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Regiones Covid")
        }
        .onAppear {
            // Cargar automáticamente si hay un país guardado
            if !vm.searchText.isEmpty && vm.items.isEmpty {
                Task { await vm.search() }
            }
        }
    }
}
