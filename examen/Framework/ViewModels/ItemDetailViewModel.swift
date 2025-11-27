import Foundation
import Combine

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
