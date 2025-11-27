import Foundation
import Alamofire

class NetworkAPIService {
    static let shared = NetworkAPIService()
    
    private let headers: HTTPHeaders = [
        "X-Api-Key": "tcFfqUyNe3kJYVyVcqk0Dw==BwrNX6k8ZMYJjUSQ"
    ]
    
    // Obtener snapshot global de países para una fecha específica y tipo (cases o deaths)
    func getSnapshot(date: String, type: String) async -> [CovidSnapshotResponse]? {
        var params: Parameters = ["date": date, "type": type]
        
        guard let url = URL(string: "https://api.api-ninjas.com/v1/covid19") else { return nil }
        
        let response = await AF.request(url, method: .get, parameters: params, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch response.result {
        case .success(let data):
            return try? JSONDecoder().decode([CovidSnapshotResponse].self, from: data)
        case .failure(let err):
            debugPrint("Error snapshot: \(err.localizedDescription)")
            if let data = response.data, let str = String(data: data, encoding: .utf8) {
                debugPrint("Response: \(str)")
            }
            return nil
        }
    }

    func getCatalog(url: URL, limit: Int?) async -> ItemCatalog? {
        // No se usa en el nuevo flujo, pero mantenemos por compatibilidad
        return nil
    }

    func getItemDetail(url: URL) async -> ItemDetail? {
        let response = await AF.request(url, method: .get, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch response.result {
        case .success(let data):
            do {
                let countries = try JSONDecoder().decode([CovidCountryResponse].self, from: data)
                
                // Agregar todos los datos de todas las regiones del país
                var allCases: [String: Int] = [:]
                var allDeaths: [String: Int] = [:]
                let countryName = countries.first?.country ?? ""
                
                for countryData in countries {
                    // Sumar casos de todas las regiones por fecha
                    if let cases = countryData.cases {
                        for (date, caseData) in cases {
                            allCases[date, default: 0] += caseData.total
                        }
                    }
                    
                    // Sumar muertes de todas las regiones por fecha
                    if let deaths = countryData.deaths {
                        for (date, deathData) in deaths {
                            allDeaths[date, default: 0] += deathData.total
                        }
                    }
                }
                
                // Convertir a StatPair ordenados por fecha
                let stats = allCases.keys.sorted().map { date in
                    StatPair(name: date, value: allCases[date] ?? 0)
                }
                
                let deathStats = allDeaths.keys.sorted().map { date in
                    StatPair(name: date, value: allDeaths[date] ?? 0)
                }
                
                return ItemDetail(
                    id: countryName,
                    title: countryName,
                    description: "Datos de COVID-19",
                    media: nil,
                    attributes: [
                        NamedValue(name: "País", value: countryName),
                        NamedValue(name: "Total de datos", value: "\(stats.count) días")
                    ],
                    stats: stats,
                    deathStats: deathStats
                )
                
            } catch {
                debugPrint("Error decoding detail: \(error)")
                return nil
            }
            
        case .failure(let err):
            debugPrint(err.localizedDescription)
            return nil
        }
    }
}
