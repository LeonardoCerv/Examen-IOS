import Foundation

struct Api {
    static let base = "https://api.api-ninjas.com/v1"
    struct routes {
        static let covid = "/covid19"
    }
}

protocol ItemAPIProtocol {
    func getItemCatalog(limit: Int?) async -> ItemCatalog?
    func getItemDetail(id: String) async -> ItemDetail? // ID es String (Region Name)
    func getItemDetailWithType(id: String, type: String) async -> ItemDetail? // Permite especificar "cases" o "deaths"
}

class ItemRepository: ItemAPIProtocol {
    static let shared = ItemRepository()
    let nservice: NetworkAPIService
    
    // Mantener el país seleccionado en memoria o pasarlo como argumento.
    // El enunciado dice "el usuario debe poder escoger un pais".
    // Para cumplir con la firma `getItemCatalog(limit: Int?)`,
    // voy a asumir un país por defecto o usar una variable estática/inyectada.
    // O mejor, voy a permitir que el ViewModel configure esto, pero la firma del protocolo es fija en el enunciado?
    // "func getItemCatalog(limit: Int?) async -> ItemCatalog?" -> Sí, es fija.
    // Voy a agregar una variable de configuración en el Repo para el país actual.
    
    var currentCountry: String = "Canada" // Default
    
    init(nservice: NetworkAPIService = NetworkAPIService.shared) {
        self.nservice = nservice
    }
    
    func setCountry(_ country: String) {
        self.currentCountry = country
    }
    
    func getItemCatalog(limit: Int?) async -> ItemCatalog? {
        // Construimos la URL con el país actual
        let urlStr = "\(Api.base)\(Api.routes.covid)?country=\(currentCountry)"
        guard let url = URL(string: urlStr) else { return nil }
        return await nservice.getCatalog(url: url, limit: limit)
    }
    
    func getItemDetail(id: String) async -> ItemDetail? {
        // ID es el nombre de la región.
        // Construimos URL con country y region.
        // Ojo: Si el ID viene vacío o es igual al país, pedimos solo por país (caso de países sin regiones claras o total).
        
        var urlStr = "\(Api.base)\(Api.routes.covid)?country=\(currentCountry)"
        if !id.isEmpty && id != currentCountry {
            // Asumimos que el ID es la región
             if let encodedRegion = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                 urlStr += "&region=\(encodedRegion)"
             }
        }
        
        guard let url = URL(string: urlStr) else { return nil }
        return await nservice.getItemDetail(url: url)
    }
    
    func getItemDetailWithType(id: String, type: String) async -> ItemDetail? {
        // Similar a getItemDetail pero agrega el parámetro type
        var urlStr = "\(Api.base)\(Api.routes.covid)?country=\(currentCountry)"
        if !id.isEmpty && id != currentCountry {
            if let encodedRegion = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                urlStr += "&region=\(encodedRegion)"
            }
        }
        urlStr += "&type=\(type)"
        
        guard let url = URL(string: urlStr) else { return nil }
        return await nservice.getItemDetail(url: url)
    }
}
