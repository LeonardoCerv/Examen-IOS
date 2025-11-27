import SwiftUI
import SDWebImageSwiftUI
import Combine
import Charts

struct ItemDetailView: View {
    let country: String
    
    @StateObject private var vm = ItemDetailViewModel()
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedDataType: DataType = .cases
    
    enum DataType: String, CaseIterable, Identifiable {
        case cases = "Casos"
        case deaths = "Muertes"
        var id: String { self.rawValue }
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
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(country)
                            .font(.largeTitle.bold())
                        Text("Datos de COVID-19")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Summary Cards
                    HStack(spacing: 12) {
                        if let lastCaseStat = vm.lastCaseStat {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Casos")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text(formatNumber(lastCaseStat.value))
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text(lastCaseStat.name)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        }
                        
                        if let lastDeathStat = vm.lastDeathStat {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Muertes")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text(formatNumber(lastDeathStat.value))
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text(lastDeathStat.name)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider().padding(.horizontal)
                    
                    // Selector de tipo de datos
                    Picker("Tipo de Datos", selection: $selectedDataType) {
                        Text("Casos").tag(DataType.cases)
                        Text("Muertes").tag(DataType.deaths)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedDataType) { _ in
                        vm.filterStats(start: startDate, end: endDate)
                    }
                    
                    // Filtro de Fechas
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rango de Fechas para Gráfica")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Desde")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $startDate, in: ...endDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hasta")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                                    .labelsHidden()
                            }
                            
                            Spacer()
                            
                            Button("Actualizar") {
                                vm.filterStats(start: startDate, end: endDate)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Gráfica
                    let currentStats = selectedDataType == .cases ? vm.filteredCaseStats : vm.filteredDeathStats
                    
                    if !currentStats.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Evolución de \(selectedDataType.rawValue)")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            // Estadísticas del rango
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Mínimo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatNumber(currentStats.map{$0.value}.min() ?? 0))
                                        .font(.headline)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Máximo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatNumber(currentStats.map{$0.value}.max() ?? 0))
                                        .font(.headline)
                                }
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Promedio")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatNumber(vm.averageValue(currentStats)))
                                        .font(.headline)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.05), radius: 4)
                            .padding(.horizontal)
                            
                            // Gráfica de línea
                            if #available(iOS 16.0, *) {
                                Chart {
                                    ForEach(currentStats, id: \.name) { stat in
                                        if let date = dateFormatter.date(from: stat.name) {
                                            LineMark(
                                                x: .value("Fecha", date),
                                                y: .value(selectedDataType.rawValue, stat.value)
                                            )
                                            .foregroundStyle(selectedDataType == .cases ? Color.blue : Color.red)
                                            .interpolationMethod(.catmullRom)
                                            
                                            AreaMark(
                                                x: .value("Fecha", date),
                                                y: .value(selectedDataType.rawValue, stat.value)
                                            )
                                            .foregroundStyle(
                                                selectedDataType == .cases ?
                                                    Color.blue.opacity(0.1) :
                                                    Color.red.opacity(0.1)
                                            )
                                            .interpolationMethod(.catmullRom)
                                        }
                                    }
                                }
                                .frame(height: 300)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 8)
                                .padding(.horizontal)
                            } else {
                                // Fallback para iOS < 16
                                VStack(spacing: 8) {
                                    ForEach(currentStats.prefix(20), id: \.name) { s in
                                        HStack(spacing: 8) {
                                            Text(formatDate(s.name))
                                                .font(.caption2)
                                                .frame(width: 70, alignment: .leading)
                                                .foregroundColor(.secondary)
                                            
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.gray.opacity(0.1))
                                                        .frame(height: 20)
                                                    
                                                    let maxVal = Double(currentStats.map{$0.value}.max() ?? 1)
                                                    let width = maxVal > 0 ? CGFloat(s.value) / CGFloat(maxVal) * geo.size.width : 0
                                                    
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(selectedDataType == .cases ? Color.blue : Color.red)
                                                        .frame(width: max(2, width), height: 20)
                                                }
                                            }
                                            .frame(height: 20)
                                            
                                            Text(formatNumber(s.value))
                                                .font(.caption.bold())
                                                .frame(width: 70, alignment: .trailing)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 8)
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
                }
            }
            .padding(.bottom)
        }
        .navigationTitle(country)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await vm.loadCountryData(country: country)
                initializeDates()
                vm.filterStats(start: startDate, end: endDate)
            }
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
}

// ViewModel para ItemDetailView
class ItemDetailViewModel: ObservableObject {
    @Published var allCaseStats: [StatPair]?
    @Published var allDeathStats: [StatPair]?
    @Published var filteredCaseStats: [StatPair] = []
    @Published var filteredDeathStats: [StatPair] = []
    @Published var lastCaseStat: StatPair?
    @Published var lastDeathStat: StatPair?
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    var detailReq: ItemDetailRequirementProtocol
    
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    init(detailReq: ItemDetailRequirementProtocol = ItemDetailRequirement.shared) {
        self.detailReq = detailReq
    }
    
    @MainActor
    func loadCountryData(country: String) async {
        isLoading = true
        hasError = false
        errorMessage = ""
        
        let detail = await detailReq.getItemDetail(country: country)
        
        guard let detail = detail else {
            isLoading = false
            hasError = true
            errorMessage = "No se pudieron cargar los datos de \(country). Verifica el nombre e intenta nuevamente."
            return
        }
        
        allCaseStats = detail.stats?.sorted { $0.name < $1.name }
        allDeathStats = detail.deathStats?.sorted { $0.name < $1.name }
        
        lastCaseStat = allCaseStats?.last
        lastDeathStat = allDeathStats?.last
        
        isLoading = false
    }
    
    @MainActor
    func filterStats(start: Date, end: Date) {
        if let stats = allCaseStats {
            filteredCaseStats = stats.filter { stat in
                guard let date = dateFormatter.date(from: stat.name) else { return false }
                return date >= start && date <= end
            }
        }
        
        if let stats = allDeathStats {
            filteredDeathStats = stats.filter { stat in
                guard let date = dateFormatter.date(from: stat.name) else { return false }
                return date >= start && date <= end
            }
        }
    }
    
    func averageValue(_ stats: [StatPair]) -> Int {
        guard !stats.isEmpty else { return 0 }
        let sum = stats.reduce(0) { $0 + $1.value }
        return sum / stats.count
    }
}

