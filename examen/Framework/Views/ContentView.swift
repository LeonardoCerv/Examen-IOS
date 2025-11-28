import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject var vm = ItemListViewModel()
    @State private var showDatePicker = false
    @State private var shouldNavigateToLastCountry = false
    @State private var navigateToCountry: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filtro de fecha y totales globales
                VStack(spacing: 8) {
                    // Fecha
                    HStack {
                        Text("Fecha:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            HStack {
                                Text(vm.selectedDate)
                                    .font(.body)
                                Image(systemName: "calendar")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    
                    // Totales globales
                    if !vm.isLoading && !vm.hasError && !vm.items.isEmpty {
                        HStack(spacing: 6) {
                            Text("Casos globales:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Text(formatNumber(vm.totalGlobalCases))
                                .font(.body.bold())
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 6) {
                            Text("Muertes globales:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Text(formatNumber(vm.totalGlobalDeaths))
                                .font(.body.bold())
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Buscar país...", text: $vm.searchText)
                        .textInputAutocapitalization(.words)
                        .onChange(of: vm.searchText) { _ in
                            vm.filterItems()
                        }
                        .onSubmit {
                            // Al presionar Enter, abrir el primer país de la lista
                            if let firstCountry = vm.filteredItems.first {
                                navigateToCountry = firstCountry.ref.name
                                shouldNavigateToLastCountry = true
                            }
                        }
                    
                    if !vm.searchText.isEmpty {
                        Button {
                            vm.searchText = ""
                            vm.filterItems()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                
                if vm.isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Cargando datos de COVID-19...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if vm.hasError {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Ocurrió un error")
                            .font(.headline)
                        Text(vm.errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 32)
                        
                        Button("Reintentar") {
                            Task { await vm.loadItems() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else if vm.filteredItems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.5))
                        Text(vm.searchText.isEmpty ? "Cargando lista de países..." : "No se encontraron países")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ZStack {
                        List(vm.filteredItems) { item in
                            NavigationLink {
                                ItemDetailView(country: item.ref.name)
                                    .onAppear {
                                        // Guardar último país visitado
                                        vm.saveLastCountry(item.ref.name)
                                    }
                            } label: {
                                HStack(alignment: .top, spacing: 0) {
                                    // Primera columna: Nombre del país (alineado a la izquierda)
                                    Text(item.ref.name)
                                        .font(.title3.bold())
                                        .foregroundColor(.black)
                                        .frame(width: 140, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    
                                    // Segunda columna: Casos (alineados a la izquierda)
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            Text("Casos:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text(formatNumber(item.cases))
                                                .font(.subheadline.bold())
                                                .foregroundColor(.blue)
                                        }
                                        
                                        HStack(spacing: 6) {
                                            Text("Muertes:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text(formatNumber(item.deaths))
                                                .font(.subheadline.bold())
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .frame(minWidth: 140, alignment: .leading)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                        .listStyle(PlainListStyle())
                        
                        // NavigationLink invisible para navegación automática
                        if let country = navigateToCountry {
                            NavigationLink(
                                destination: ItemDetailView(country: country)
                                    .onAppear {
                                        vm.saveLastCountry(country)
                                    },
                                isActive: $shouldNavigateToLastCountry
                            ) {
                                EmptyView()
                            }
                            .hidden()
                        }
                    }
                }
            }
            .navigationTitle("Datos COVID-19")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $vm.selectedDate) {
                Task { await vm.loadItems() }
            }
        }
        .onAppear {
            if vm.items.isEmpty {
                // Verificar si hay un último país guardado para navegación automática
                if let lastCountry = vm.getLastCountry() {
                    navigateToCountry = lastCountry
                }
                Task { 
                    await vm.loadItems()
                    
                    // Activar navegación después de cargar
                    if let country = navigateToCountry, !vm.items.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            shouldNavigateToLastCountry = true
                        }
                    }
                }
            }
        }
    }
    
    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// Sheet para seleccionar fecha
struct DatePickerSheet: View {
    @Binding var selectedDate: String
    var onDateSelected: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Selecciona una fecha")
                    .font(.headline)
                    .padding()
                
                DatePicker(
                    "Fecha",
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Text("Nota: Los datos están disponibles desde enero 2020")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(
                leading: Button("Cancelar") { dismiss() },
                trailing: Button("Aplicar") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    selectedDate = formatter.string(from: date)
                    dismiss()
                    onDateSelected()
                }
            )
        }
        .onAppear {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let existingDate = formatter.date(from: selectedDate) {
                date = existingDate
            }
        }
    }
}
