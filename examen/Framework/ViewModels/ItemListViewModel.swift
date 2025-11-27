import Foundation
import Combine

class ItemListViewModel: ObservableObject {
    @Published var items = [ItemBase]()
    @Published var filteredItems = [ItemBase]()
    @Published var isLoading = false
    @Published var searchText: String = ""
    @Published var selectedDate: String = "2023-03-09" // Última actualización conocida de la API
    @Published var hasError = false
    @Published var errorMessage = ""
    @Published var totalGlobalCases = 0
    @Published var totalGlobalDeaths = 0
    
    var listReq: ItemListRequirementProtocol
    var detailReq: ItemDetailRequirementProtocol
    var userReq: UserRequirementProtocol
    
    init(listReq: ItemListRequirementProtocol = ItemListRequirement.shared,
         detailReq: ItemDetailRequirementProtocol = ItemDetailRequirement.shared,
         userReq: UserRequirementProtocol = UserRequirement.shared) {
        self.listReq = listReq
        self.detailReq = detailReq
        self.userReq = userReq
    }
    
    @MainActor
    func loadItems() async {
        isLoading = true
        hasError = false
        errorMessage = ""
        items.removeAll()
        filteredItems.removeAll()
        
        let result = await listReq.getItemCatalog(date: selectedDate)
        
        guard let catalog = result, !catalog.results.isEmpty else {
            isLoading = false
            hasError = true
            errorMessage = "No se encontraron datos para la fecha '\(selectedDate)'. Intenta con otra fecha."
            return
        }
        
        // Obtener también los datos de casos y muertes del snapshot
        guard let casesData = await NetworkAPIService.shared.getSnapshot(date: selectedDate, type: "cases"),
              let deathsData = await NetworkAPIService.shared.getSnapshot(date: selectedDate, type: "deaths") else {
            isLoading = false
            hasError = true
            errorMessage = "Error al cargar los datos."
            return
        }
        
        // Agrupar por país
        var countryData: [String: (cases: Int, deaths: Int, newCases: Int, newDeaths: Int)] = [:]
        
        for item in casesData {
            let country = item.country
            if let casesSnapshot = item.cases {
                countryData[country, default: (0, 0, 0, 0)].cases += casesSnapshot.total
                countryData[country, default: (0, 0, 0, 0)].newCases += casesSnapshot.new
            }
        }
        
        for item in deathsData {
            let country = item.country
            if let deathsSnapshot = item.deaths {
                countryData[country, default: (0, 0, 0, 0)].deaths += deathsSnapshot.total
                countryData[country, default: (0, 0, 0, 0)].newDeaths += deathsSnapshot.new
            }
        }
        
        // Crear ItemBase con los datos
        for ref in catalog.results {
            let data = countryData[ref.name] ?? (0, 0, 0, 0)
            let item = ItemBase(
                id: ref.name,
                ref: ref,
                detail: nil,
                cases: data.cases,
                deaths: data.deaths,
                newCases: data.newCases,
                newDeaths: data.newDeaths
            )
            self.items.append(item)
        }
        
        // Calcular totales globales
        self.totalGlobalCases = self.items.reduce(0) { $0 + $1.cases }
        self.totalGlobalDeaths = self.items.reduce(0) { $0 + $1.deaths }
        
        self.filteredItems = self.items
        isLoading = false
    }
    
    @MainActor
    func filterItems() {
        if searchText.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { $0.ref.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    @MainActor
    func changeDate(_ newDate: String) async {
        selectedDate = newDate
        await loadItems()
    }
    
    // Guardar último país visitado
    func saveLastCountry(_ countryName: String) {
        userReq.setLastCountry(countryName)
    }
    
    // Obtener último país visitado
    func getLastCountry() -> String? {
        return userReq.getLastCountry()
    }
}
