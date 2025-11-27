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

    // Obtener datos históricos (series temporales) para un país específico
    func getHistoricalData(url: URL, type: String) async -> [StatPair]? {
        let response = await AF.request(url, method: .get, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch response.result {
        case .success(let data):
            do {
                let countries = try JSONDecoder().decode([CovidCountryResponse].self, from: data)
                
                // Agregar todos los datos de todas las regiones del país
                var allData: [String: Int] = [:]
                
                for countryData in countries {
                    if type == "cases", let cases = countryData.cases {
                        // Sumar casos de todas las regiones por fecha
                        for (date, caseData) in cases {
                            allData[date, default: 0] += caseData.total
                        }
                    } else if type == "deaths", let deaths = countryData.deaths {
                        // Sumar muertes de todas las regiones por fecha
                        for (date, deathData) in deaths {
                            allData[date, default: 0] += deathData.total
                        }
                    }
                }
                
                // Convertir a StatPair ordenados por fecha
                let stats = allData.keys.sorted().map { date in
                    StatPair(name: date, value: allData[date] ?? 0)
                }
                
                return stats
                
            } catch {
                debugPrint("Error decoding historical data: \(error)")
                if let str = String(data: data, encoding: .utf8) {
                    debugPrint("Response: \(str.prefix(500))")
                }
                return nil
            }
            
        case .failure(let err):
            debugPrint("Error fetching historical data: \(err.localizedDescription)")
            return nil
        }
    }
}
