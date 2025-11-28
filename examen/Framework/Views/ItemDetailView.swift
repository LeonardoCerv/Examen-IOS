import SwiftUI
import SDWebImageSwiftUI
import Combine
import Charts

struct ItemDetailView: View {
    let country: String
    
    @StateObject private var vm = ItemDetailViewModel()
    @StateObject private var compareVM = CompareCountriesViewModel()
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedTab: GraphTab = .cases
    @State private var showCountryPicker = false
    @State private var comparisonCountry: String?
    @State private var searchText = ""
    
    enum GraphTab: String, CaseIterable {
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
                if vm.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Cargando datos de \(country)...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else if vm.hasError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Error al cargar datos")
                            .font(.headline)
                        Text(vm.errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Button("Reintentar") {
                            Task { await vm.loadCountryData(country: country) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    // Filtro de Fechas - estilo similar a lista de países
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rango de Fechas")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            // Fecha inicio
                            DatePicker("", selection: $startDate, in: ...endDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .onChange(of: startDate) { _ in
                                    vm.filterStats(start: startDate, end: endDate)
                                    if comparisonCountry != nil {
                                        compareVM.filterStats(start: startDate, end: endDate)
                                    }
                                }
                            
                            Text("-")
                                .foregroundColor(.secondary)
                            
                            // Fecha fin
                            DatePicker("", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .onChange(of: endDate) { _ in
                                    vm.filterStats(start: startDate, end: endDate)
                                    if comparisonCountry != nil {
                                        compareVM.filterStats(start: startDate, end: endDate)
                                    }
                                }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGroupedBackground))
                    
                    // Totales del periodo - alineados a la izquierda
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(country)
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 6) {
                                Text("Casos:")
                                    .font(.body)
                                    .foregroundColor(.black)
                                Text(formatNumber(totalCasesInPeriod()))
                                    .font(.body.bold())
                                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.7))
                            }
                            
                            HStack(spacing: 6) {
                                Text("Muertes:")
                                    .font(.body)
                                    .foregroundColor(.black)
                                Text(formatNumber(totalDeathsInPeriod()))
                                    .font(.body.bold())
                                    .foregroundColor(Color(red: 0.7, green: 0.1, blue: 0.1))
                            }
                        }
                        
                        // Comparación (si está activa)
                        if let compareCountry = comparisonCountry {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(compareCountry)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 6) {
                                    Text("Casos:")
                                        .font(.body)
                                        .foregroundColor(.black)
                                    Text(formatNumber(compareVM.country2TotalCases))
                                        .font(.body.bold())
                                        .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.7).opacity(0.6))
                                }
                                
                                HStack(spacing: 6) {
                                    Text("Muertes:")
                                        .font(.body)
                                        .foregroundColor(.black)
                                    Text(formatNumber(compareVM.country2TotalDeaths))
                                        .font(.body.bold())
                                        .foregroundColor(Color(red: 0.7, green: 0.1, blue: 0.1).opacity(0.6))
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    Divider().padding(.horizontal)
                    
                    // Gráficas con Tabs
                    if !vm.filteredCaseStats.isEmpty || !vm.filteredDeathStats.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Evolución Temporal")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            // Tab Picker
                            Picker("Tipo de Gráfica", selection: $selectedTab) {
                                ForEach(GraphTab.allCases, id: \.self) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            // Gráfica según tab seleccionado
                            if #available(iOS 16.0, *) {
                                Chart {
                                    if selectedTab == .cases {
                                        // Gráfica de casos país principal
                                        ForEach(vm.filteredCaseStats, id: \.name) { stat in
                                            if let date = dateFormatter.date(from: stat.name) {
                                                LineMark(
                                                    x: .value("Fecha", date),
                                                    y: .value("Casos", stat.value),
                                                    series: .value("País", country)
                                                )
                                                .foregroundStyle(Color(red: 0.0, green: 0.4, blue: 0.7))
                                                .interpolationMethod(.catmullRom)
                                            }
                                        }
                                        
                                        // Gráfica de casos país comparación
                                        if let compareCountry = comparisonCountry {
                                            ForEach(compareVM.filteredCountry2Cases, id: \.name) { stat in
                                                if let date = dateFormatter.date(from: stat.name) {
                                                    LineMark(
                                                        x: .value("Fecha", date),
                                                        y: .value("Casos", stat.value),
                                                        series: .value("País", compareCountry)
                                                    )
                                                    .foregroundStyle(Color(red: 0.0, green: 0.4, blue: 0.7).opacity(0.5))
                                                    .interpolationMethod(.catmullRom)
                                                }
                                            }
                                        }
                                    } else {
                                        // Gráfica de muertes país principal
                                        ForEach(vm.filteredDeathStats, id: \.name) { stat in
                                            if let date = dateFormatter.date(from: stat.name) {
                                                LineMark(
                                                    x: .value("Fecha", date),
                                                    y: .value("Muertes", stat.value),
                                                    series: .value("País", country)
                                                )
                                                .foregroundStyle(Color(red: 0.7, green: 0.1, blue: 0.1))
                                                .interpolationMethod(.catmullRom)
                                            }
                                        }
                                        
                                        // Gráfica de muertes país comparación
                                        if let compareCountry = comparisonCountry {
                                            ForEach(compareVM.filteredCountry2Deaths, id: \.name) { stat in
                                                if let date = dateFormatter.date(from: stat.name) {
                                                    LineMark(
                                                        x: .value("Fecha", date),
                                                        y: .value("Muertes", stat.value),
                                                        series: .value("País", compareCountry)
                                                    )
                                                    .foregroundStyle(Color(red: 0.7, green: 0.1, blue: 0.1).opacity(0.5))
                                                    .interpolationMethod(.catmullRom)
                                                }
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
                                
                                // Leyenda si hay comparación
                                if comparisonCountry != nil {
                                    HStack(spacing: 24) {
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(selectedTab == .cases ? Color(red: 0.0, green: 0.4, blue: 0.7) : Color(red: 0.7, green: 0.1, blue: 0.1))
                                                .frame(width: 12, height: 12)
                                            Text(country)
                                                .font(.caption)
                                        }
                                        
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(selectedTab == .cases ? Color(red: 0.0, green: 0.4, blue: 0.7).opacity(0.5) : Color(red: 0.7, green: 0.1, blue: 0.1).opacity(0.5))
                                                .frame(width: 12, height: 12)
                                            Text(comparisonCountry!)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                // Fallback para iOS < 16
                                VStack(spacing: 12) {
                                    Text("Gráficas no disponibles en esta versión de iOS")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No hay datos para el rango seleccionado")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Ajusta las fechas e intenta nuevamente")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                    
                    // Botón de comparar/quitar comparación al final
                    if comparisonCountry == nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                showCountryPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "chart.bar.xaxis")
                                    Text("Comparar con otro país")
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .font(.body.bold())
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        Button {
                            comparisonCountry = nil
                            compareVM.country2Data = nil
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Quitar comparación")
                                Spacer()
                            }
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom)
        }
        .navigationTitle(country)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheetView(selectedCountry: $comparisonCountry, currentCountry: country)
                .onDisappear {
                    if let compareCountry = comparisonCountry {
                        Task {
                            await compareVM.loadComparisonData(country1: country, country2: compareCountry)
                            compareVM.filterStats(start: startDate, end: endDate)
                        }
                    }
                }
        }
        .onAppear {
            Task {
                await vm.loadCountryData(country: country)
                initializeDates()
                vm.filterStats(start: startDate, end: endDate)
            }
        }
    }
    
    func totalCasesInPeriod() -> Int {
        // Sumar todos los casos nuevos en el periodo
        return vm.filteredCaseStats.reduce(0) { total, stat in
            // Calcular casos nuevos (diferencia con el día anterior)
            if let index = vm.filteredCaseStats.firstIndex(where: { $0.name == stat.name }),
               index > 0 {
                let previous = vm.filteredCaseStats[index - 1].value
                return total + (stat.value - previous)
            }
            return total
        }
    }
    
    func totalDeathsInPeriod() -> Int {
        // Sumar todas las muertes nuevas en el periodo
        return vm.filteredDeathStats.reduce(0) { total, stat in
            // Calcular muertes nuevas (diferencia con el día anterior)
            if let index = vm.filteredDeathStats.firstIndex(where: { $0.name == stat.name }),
               index > 0 {
                let previous = vm.filteredDeathStats[index - 1].value
                return total + (stat.value - previous)
            }
            return total
        }
    }
    
    func initializeDates() {
        if let stats = vm.allCaseStats, !stats.isEmpty {
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
    
    func formatDate(_ dateString: String) -> String {
        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd MMM yy"
        return displayFormatter.string(from: date)
    }
    
    func formatDateShort(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd"
        return displayFormatter.string(from: date)
    }
}

// Vista para seleccionar país a comparar
struct CountryPickerSheetView: View {
    @Binding var selectedCountry: String?
    let currentCountry: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = ItemListViewModel()
    @State private var searchText = ""
    
    var filteredCountries: [ItemBase] {
        let countries = vm.items.filter { $0.ref.name != currentCountry }
        if searchText.isEmpty {
            return countries
        }
        return countries.filter {
            $0.ref.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                            HStack {
                                Text(country.ref.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Seleccionar país")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancelar") { dismiss() })
        }
        .onAppear {
            if vm.items.isEmpty {
                Task { await vm.loadItems() }
            }
        }
    }
}

