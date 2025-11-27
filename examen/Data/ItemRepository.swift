import Foundation

struct Api {
    static let base = "https://api.api-ninjas.com/v1"
    struct routes {
        static let covid = "/covid19"
    }
}

protocol ItemAPIProtocol {
    func getItemCatalog(date: String) async -> ItemCatalog?
    func getItemDetail(country: String) async -> ItemDetail?
}

class ItemRepository: ItemAPIProtocol {
    static let shared = ItemRepository()
    let nservice: NetworkAPIService
    
    init(nservice: NetworkAPIService = NetworkAPIService.shared) {
        self.nservice = nservice
    }
    
    func getItemCatalog(date: String) async -> ItemCatalog? {
        // Obtener snapshot de casos y muertes para la fecha especificada
        guard let casesData = await nservice.getSnapshot(date: date, type: "cases"),
              let deathsData = await nservice.getSnapshot(date: date, type: "deaths") else {
            return nil
        }
        
        // Agrupar por país (sumar todas las regiones)
        var countryMap: [String: (cases: Int, deaths: Int, newCases: Int, newDeaths: Int)] = [:]
        
        for item in casesData {
            let country = item.country
            // Para snapshot, los datos están directamente en item.cases, no en un diccionario
            if let casesData = item.cases {
                countryMap[country, default: (0, 0, 0, 0)].cases += casesData.total
                countryMap[country, default: (0, 0, 0, 0)].newCases += casesData.new
            }
        }
        
        for item in deathsData {
            let country = item.country
            // Para snapshot, los datos están directamente en item.deaths
            if let deathsData = item.deaths {
                countryMap[country, default: (0, 0, 0, 0)].deaths += deathsData.total
                countryMap[country, default: (0, 0, 0, 0)].newDeaths += deathsData.new
            }
        }
        
        // Convertir a ItemRef
        let refs = countryMap.map { (country, data) in
            ItemRef(
                name: country,
                url: "\(Api.base)\(Api.routes.covid)?country=\(country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country)"
            )
        }.sorted { $0.name < $1.name }
        
        return ItemCatalog(count: refs.count, results: refs)
    }
    
    func getItemDetail(country: String) async -> ItemDetail? {
        // Hacer dos llamadas: una para cases y otra para deaths
        let casesUrlStr = "\(Api.base)\(Api.routes.covid)?country=\(country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country)&type=cases"
        let deathsUrlStr = "\(Api.base)\(Api.routes.covid)?country=\(country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country)&type=deaths"
        
        guard let casesUrl = URL(string: casesUrlStr),
              let deathsUrl = URL(string: deathsUrlStr) else { return nil }
        
        async let casesData = nservice.getHistoricalData(url: casesUrl, type: "cases")
        async let deathsData = nservice.getHistoricalData(url: deathsUrl, type: "deaths")
        
        guard let cases = await casesData,
              let deaths = await deathsData else { return nil }
        
        // Combinar ambos en un ItemDetail
        return ItemDetail(
            id: country,
            title: country,
            description: "Datos de COVID-19",
            media: nil,
            attributes: [
                NamedValue(name: "País", value: country),
                NamedValue(name: "Total de datos", value: "\(cases.count) días")
            ],
            stats: cases,
            deathStats: deaths
        )
    }
}
