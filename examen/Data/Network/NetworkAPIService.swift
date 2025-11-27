import Foundation
import Alamofire

class NetworkAPIService {
    static let shared = NetworkAPIService()
    
    // API Key hardcoded for this exam as requested
    private let headers: HTTPHeaders = [
        "X-Api-Key": "tcFfqUyNe3kJYVyVcqk0Dw==BwrNX6k8ZMYJjUSQ"
    ]

    func getCatalog(url: URL, limit: Int?) async -> ItemCatalog? {
        // La API devuelve un Array de objetos, no un objeto con "results".
        // Hacemos el request y parseamos manualmente para adaptar a ItemCatalog.
        
        let response = await AF.request(url, method: .get, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch response.result {
        case .success(let data):
            do {
                let regions = try JSONDecoder().decode([CovidRegionResponse].self, from: data)
                
                // Mapeamos a ItemRef
                let refs = regions.map { regionData in
                    // Construimos una URL para el detalle que incluya la región
                    // Ojo: La URL original ya traía el país.
                    // Para el detalle, si la API soporta filtrar por región, ideal.
                    // Si no, el repositorio mandará la misma URL y filtraremos aquí o en el repo.
                    // Asumiremos que el Repo construye la URL correcta para el detalle.
                    // Aquí solo creamos el Ref.
                    
                    // Hack: Guardamos el nombre de la región en la URL como query param simulado o real
                    // para que al pedir detalle sepamos cuál es.
                    // Pero el enunciado dice "url: String // apunta al endpoint de detalle del ítem"
                    
                    ItemRef(name: regionData.region.isEmpty ? regionData.country : regionData.region,
                            url: url.absoluteString + "&region=" + (regionData.region.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""))
                }
                
                return ItemCatalog(count: refs.count, results: refs)
            } catch {
                debugPrint("Error decoding catalog: \(error)")
                return nil
            }
            
        case .failure(let err):
            debugPrint(err.localizedDescription)
            return nil
        }
    }

    func getItemDetail(url: URL) async -> ItemDetail? {
        // Aquí esperamos una URL que ya tenga el filtro de región si es posible,
        // o si es la misma URL, traerá todo y tendremos que filtrar.
        // API Ninjas soporta `&region=Alberta`.
        
        let response = await AF.request(url, method: .get, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch response.result {
        case .success(let data):
            do {
                let regions = try JSONDecoder().decode([CovidRegionResponse].self, from: data)
                
                // Si la URL tenía filtro de región, debería venir 1 solo elemento (o pocos).
                // Tomamos el primero.
                guard let regionData = regions.first else { return nil }
                
                // Mapeamos cases a stats
                var stats: [StatPair] = []
                if let cases = regionData.cases {
                    let sortedKeys = cases.keys.sorted()
                    stats = sortedKeys.map { dateKey in
                        StatPair(name: dateKey, value: cases[dateKey]?.total ?? 0)
                    }
                }
                
                // Mapeamos deaths a deathStats
                var deathStats: [StatPair] = []
                if let deaths = regionData.deaths {
                    let sortedKeys = deaths.keys.sorted()
                    deathStats = sortedKeys.map { dateKey in
                        StatPair(name: dateKey, value: deaths[dateKey]?.total ?? 0)
                    }
                }
                
                return ItemDetail(
                    id: regionData.region,
                    title: regionData.country,
                    description: regionData.region,
                    media: nil, // No hay imágenes en esta API
                    attributes: [
                        NamedValue(name: "País", value: regionData.country),
                        NamedValue(name: "Región", value: regionData.region)
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
