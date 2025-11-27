import SwiftUI
import SDWebImageSwiftUI

struct ItemDetailView: View {
    let item: ItemBase
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var filteredStats: [StatPair] = []
    @State private var filteredDeathStats: [StatPair] = []
    @State private var selectedDataType: DataType = .cases
    
    enum DataType: String, CaseIterable, Identifiable {
        case cases = "Casos"
        case deaths = "Muertes"
        
        var id: String { self.rawValue }
    }
    
    // Formateador para parsear las fechas del API (YYYY-MM-DD)
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Image
                if let urlStr = item.detail?.media?.primary, let url = URL(string: urlStr) {
                    WebImage(url: url).resizable().scaledToFit().frame(maxWidth: .infinity)
                }
                
                // Title & Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.detail?.title ?? item.ref.name)
                        .font(.largeTitle.bold())
                    if let desc = item.detail?.description {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Selector de tipo de datos
                Picker("Tipo de Datos", selection: $selectedDataType) {
                    Text("Casos").tag(DataType.cases)
                    Text("Muertes").tag(DataType.deaths)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedDataType) { _ in
                    filterStats()
                }
                
                // Summary Cards
                HStack(spacing: 12) {
                    // Casos
                    if let stats = item.detail?.stats, let lastStat = stats.sorted(by: { $0.name < $1.name }).last {
                        VStack(alignment: .leading) {
                            Text("Total Casos")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(formatNumber(lastStat.value))")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text(lastStat.name)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                    
                    // Muertes
                    if let deathStats = item.detail?.deathStats, let lastStat = deathStats.sorted(by: { $0.name < $1.name }).last {
                        VStack(alignment: .leading) {
                            Text("Total Muertes")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(formatNumber(lastStat.value))")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text(lastStat.name)
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
                
                // Filtro de Fechas
                VStack(alignment: .leading, spacing: 12) {
                    Text("Historial de \(selectedDataType.rawValue)")
                        .font(.title3.bold())
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Desde")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hasta")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        
                        Spacer()
                        
                        Button("Filtrar") {
                            filterStats()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)
                
                // Chart
                let currentStats = selectedDataType == .cases ? filteredStats : filteredDeathStats
                
                if !currentStats.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Estadísticas del rango
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Promedio")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(formatNumber(averageValue(currentStats)))")
                                    .font(.headline)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Máximo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(formatNumber(currentStats.map{$0.value}.max() ?? 0))")
                                    .font(.headline)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Registros")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(currentStats.count)")
                                    .font(.headline)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        // Gráfico de barras mejorado
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(currentStats, id: \.name) { s in
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
                                                    .fill(LinearGradient(
                                                        colors: selectedDataType == .cases ? 
                                                            [.blue.opacity(0.7), .blue] : 
                                                            [.red.opacity(0.7), .red],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ))
                                                    .frame(width: max(2, width), height: 20)
                                            }
                                        }
                                        .frame(height: 20)
                                        
                                        Text("\(formatNumber(s.value))")
                                            .font(.caption.bold())
                                            .frame(width: 60, alignment: .trailing)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 400)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 8)
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No hay datos para el rango seleccionado")
                            .foregroundColor(.secondary)
                        Text("Ajusta las fechas e intenta nuevamente")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .padding(.bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeDates()
            filterStats()
        }
    }
    
    func initializeDates() {
        if let stats = item.detail?.stats, !stats.isEmpty {
            let sorted = stats.sorted { $0.name < $1.name }
            
            if let first = sorted.first, let date = dateFormatter.date(from: first.name) {
                startDate = date
            }
            if let last = sorted.last, let date = dateFormatter.date(from: last.name) {
                endDate = date
            }
        }
    }
    
    func filterStats() {
        // Filtrar casos
        if let stats = item.detail?.stats {
            filteredStats = stats.filter { stat in
                guard let date = dateFormatter.date(from: stat.name) else { return false }
                return date >= startDate && date <= endDate
            }.sorted { $0.name < $1.name }
        }
        
        // Filtrar muertes
        if let deathStats = item.detail?.deathStats {
            filteredDeathStats = deathStats.filter { stat in
                guard let date = dateFormatter.date(from: stat.name) else { return false }
                return date >= startDate && date <= endDate
            }.sorted { $0.name < $1.name }
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
        displayFormatter.dateFormat = "dd MMM"
        return displayFormatter.string(from: date)
    }
    
    func averageValue(_ stats: [StatPair]) -> Int {
        guard !stats.isEmpty else { return 0 }
        let sum = stats.reduce(0) { $0 + $1.value }
        return sum / stats.count
    }
}

