import SwiftUI
import Charts

struct CompareCountriesView: View {
    let country1: String
    @State private var selectedCountry2: String = ""
    @State private var showCountryPicker = false
    
    @StateObject private var vm = CompareCountriesViewModel()
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedMetric: MetricType = .cases
    
    enum MetricType: String, CaseIterable {
        case cases = "Casos"
        case deaths = "Muertes"
    }
    
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Selector de segundo país
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comparar con:")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    Button {
                        showCountryPicker = true
                    } label: {
                        HStack {
                            Text(selectedCountry2.isEmpty ? "Seleccionar país" : selectedCountry2)
                                .font(.body)
                                .foregroundColor(selectedCountry2.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if vm.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Cargando datos de comparación...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
                } else if vm.hasError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error al cargar datos")
                            .font(.headline)
                        Text(vm.errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
                } else if !selectedCountry2.isEmpty && vm.country1Data != nil && vm.country2Data != nil {
                    // Rango de fechas
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rango de Fechas")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            DatePicker("", selection: $startDate, in: ...endDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .onChange(of: startDate) { _ in
                                    vm.filterStats(start: startDate, end: endDate)
                                }
                            
                            Text("-")
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .onChange(of: endDate) { _ in
                                    vm.filterStats(start: startDate, end: endDate)
                                }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGroupedBackground))
                    
                    // Comparativa de totales
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Totales en el periodo")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            // País 1
                            VStack(alignment: .leading, spacing: 8) {
                                Text(country1)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.blue)
                                
                                HStack(spacing: 6) {
                                    Text("Casos:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatNumber(vm.country1TotalCases))
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                }
                                
                                HStack(spacing: 6) {
                                    Text("Muertes:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatNumber(vm.country1TotalDeaths))
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                            
                            // País 2
                            VStack(alignment: .leading, spacing: 8) {
                                Text(selectedCountry2)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.orange)
                                
                                HStack(spacing: 6) {
                                    Text("Casos:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatNumber(vm.country2TotalCases))
                                        .font(.caption.bold())
                                        .foregroundColor(.orange)
                                }
                                
                                HStack(spacing: 6) {
                                    Text("Muertes:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatNumber(vm.country2TotalDeaths))
                                        .font(.caption.bold())
                                        .foregroundColor(.orange)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 8)
                        .padding(.horizontal)
                    }
                    
                    Divider().padding(.horizontal)
                    
                    // Gráficas comparativas
                    if !vm.filteredCountry1Cases.isEmpty || !vm.filteredCountry2Cases.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Comparativa")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            // Selector de métrica
                            Picker("Métrica", selection: $selectedMetric) {
                                ForEach(MetricType.allCases, id: \.self) { metric in
                                    Text(metric.rawValue).tag(metric)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            // Gráfica comparativa
                            if #available(iOS 16.0, *) {
                                Chart {
                                    if selectedMetric == .cases {
                                        // Casos país 1
                                        ForEach(vm.filteredCountry1Cases, id: \.name) { stat in
                                            if let date = dateFormatter.date(from: stat.name) {
                                                LineMark(
                                                    x: .value("Fecha", date),
                                                    y: .value("Casos", stat.value)
                                                )
                                                .foregroundStyle(Color.blue)
                                                .interpolationMethod(.catmullRom)
                                            }
                                        }
                                        
                                        // Casos país 2
                                        ForEach(vm.filteredCountry2Cases, id: \.name) { stat in
                                            if let date = dateFormatter.date(from: stat.name) {
                                                LineMark(
                                                    x: .value("Fecha", date),
                                                    y: .value("Casos", stat.value)
                                                )
                                                .foregroundStyle(Color.orange)
                                                .interpolationMethod(.catmullRom)
                                            }
                                        }
                                    } else {
                                        // Muertes país 1
                                        ForEach(vm.filteredCountry1Deaths, id: \.name) { stat in
                                            if let date = dateFormatter.date(from: stat.name) {
                                                LineMark(
                                                    x: .value("Fecha", date),
                                                    y: .value("Muertes", stat.value)
                                                )
                                                .foregroundStyle(Color.blue)
                                                .interpolationMethod(.catmullRom)
                                            }
                                        }
                                        
                                        // Muertes país 2
                                        ForEach(vm.filteredCountry2Deaths, id: \.name) { stat in
                                            if let date = dateFormatter.date(from: stat.name) {
                                                LineMark(
                                                    x: .value("Fecha", date),
                                                    y: .value("Muertes", stat.value)
                                                )
                                                .foregroundStyle(Color.orange)
                                                .interpolationMethod(.catmullRom)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 300)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 8)
                                .padding(.horizontal)
                                
                                // Leyenda
                                HStack(spacing: 24) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 12, height: 12)
                                        Text(country1)
                                            .font(.caption)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 12, height: 12)
                                        Text(selectedCountry2)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                } else if selectedCountry2.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.5))
                        Text("Selecciona un país para comparar")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("Comparar Países")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry2, currentCountry: country1)
                .onDisappear {
                    if !selectedCountry2.isEmpty {
                        Task {
                            await vm.loadComparisonData(country1: country1, country2: selectedCountry2)
                            initializeDates()
                            vm.filterStats(start: startDate, end: endDate)
                        }
                    }
                }
        }
    }
    
    func initializeDates() {
        if let stats = vm.country1Data?.stats, !stats.isEmpty {
            let sorted = stats.sorted { $0.name < $1.name }
            if let first = sorted.first, let date = dateFormatter.date(from: first.name) {
                startDate = date
            }
            if let last = sorted.last, let date = dateFormatter.date(from: last.name) {
                endDate = date
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

// Vista para seleccionar país
struct CountryPickerView: View {
    @Binding var selectedCountry: String
    let currentCountry: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = ItemListViewModel()
    @State private var searchText = ""
    
    var filteredCountries: [ItemBase] {
        if searchText.isEmpty {
            return vm.items.filter { $0.ref.name != currentCountry }
        }
        return vm.items.filter {
            $0.ref.name != currentCountry &&
            $0.ref.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Buscar país...", text: $searchText)
                        .textInputAutocapitalization(.words)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding()
                
                if vm.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    List(filteredCountries) { country in
                        Button {
                            selectedCountry = country.ref.name
                            dismiss()
                        } label: {
                            Text(country.ref.name)
                                .font(.body)
                        }
                    }
                }
            }
            .navigationTitle("Seleccionar País")
            .navigationBarItems(trailing: Button("Cancelar") { dismiss() })
        }
        .onAppear {
            if vm.items.isEmpty {
                Task { await vm.loadItems() }
            }
        }
    }
}
