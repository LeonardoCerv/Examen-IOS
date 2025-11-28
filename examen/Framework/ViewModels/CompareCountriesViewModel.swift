import Foundation
import Combine

@MainActor
class CompareCountriesViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    // Datos completos
    @Published var country1Data: ItemDetail?
    @Published var country2Data: ItemDetail?
    
    // Datos filtrados
    @Published var filteredCountry1Cases: [StatPair] = []
    @Published var filteredCountry1Deaths: [StatPair] = []
    @Published var filteredCountry2Cases: [StatPair] = []
    @Published var filteredCountry2Deaths: [StatPair] = []
    
    // Totales
    @Published var country1TotalCases = 0
    @Published var country1TotalDeaths = 0
    @Published var country2TotalCases = 0
    @Published var country2TotalDeaths = 0
    
    private let requirement: ItemDetailRequirement
    
    init(requirement: ItemDetailRequirement = ItemDetailRequirement()) {
        self.requirement = requirement
    }
    
    func loadComparisonData(country1: String, country2: String) async {
        isLoading = true
        hasError = false
        errorMessage = ""
        
        do {
            // Cargar datos de ambos países en paralelo
            async let data1 = requirement.getItemDetail(country: country1)
            async let data2 = requirement.getItemDetail(country: country2)
            
            let detail1 = await data1
            let detail2 = await data2
            
            guard let detail1 = detail1, let detail2 = detail2 else {
                hasError = true
                errorMessage = "No se pudieron cargar los datos de uno o ambos países"
                isLoading = false
                return
            }
            
            country1Data = detail1
            country2Data = detail2
            
            isLoading = false
        } catch {
            isLoading = false
            hasError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func filterStats(start: Date, end: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let startString = formatter.string(from: start)
        let endString = formatter.string(from: end)
        
        guard let data1 = country1Data, let data2 = country2Data else { return }
        
        // Filtrar datos del país 1
        filteredCountry1Cases = (data1.stats ?? []).filter { stat in
            stat.name >= startString && stat.name <= endString
        }.sorted { $0.name < $1.name }
        
        filteredCountry1Deaths = (data1.deathStats ?? []).filter { stat in
            stat.name >= startString && stat.name <= endString
        }.sorted { $0.name < $1.name }
        
        // Filtrar datos del país 2
        filteredCountry2Cases = (data2.stats ?? []).filter { stat in
            stat.name >= startString && stat.name <= endString
        }.sorted { $0.name < $1.name }
        
        filteredCountry2Deaths = (data2.deathStats ?? []).filter { stat in
            stat.name >= startString && stat.name <= endString
        }.sorted { $0.name < $1.name }
        
        // Calcular totales
        country1TotalCases = calculatePeriodTotal(filteredCountry1Cases)
        country1TotalDeaths = calculatePeriodTotal(filteredCountry1Deaths)
        country2TotalCases = calculatePeriodTotal(filteredCountry2Cases)
        country2TotalDeaths = calculatePeriodTotal(filteredCountry2Deaths)
    }
    
    private func calculatePeriodTotal(_ stats: [StatPair]) -> Int {
        return stats.reduce(0) { total, stat in
            if let index = stats.firstIndex(where: { $0.name == stat.name }), index > 0 {
                let previous = stats[index - 1].value
                return total + (stat.value - previous)
            }
            return total
        }
    }
}
