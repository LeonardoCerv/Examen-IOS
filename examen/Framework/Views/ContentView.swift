import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject var vm = ItemListViewModel()
    @State private var showDatePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filtro de fecha
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
                
                // Totales Globales
                if !vm.isLoading && !vm.hasError && !vm.items.isEmpty {
                    VStack(spacing: 12) {
                        Text("Totales Globales")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Total Casos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatNumber(vm.totalGlobalCases))
                                    .font(.title3.bold())
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Total Muertes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatNumber(vm.totalGlobalDeaths))
                                    .font(.title3.bold())
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGroupedBackground))
                }
                
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
                    List(vm.filteredItems) { item in
                        NavigationLink {
                            ItemDetailView(country: item.ref.name)
                        } label: {
                            HStack(spacing: 12) {
                                // Nombre del país
                                Text(item.ref.name)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                // Casos y muertes en columnas
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text("Casos: \(formatNumber(item.cases))")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        
                                        if item.newCases > 0 {
                                            Text("+\(formatNumber(item.newCases))")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    HStack(spacing: 6) {
                                        Text("Muertes: \(formatNumber(item.deaths))")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        
                                        if item.newDeaths > 0 {
                                            Text("+\(formatNumber(item.newDeaths))")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("COVID-19")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $vm.selectedDate) {
                Task { await vm.loadItems() }
            }
        }
        .onAppear {
            if vm.items.isEmpty {
                Task { await vm.loadItems() }
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
