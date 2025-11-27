import Foundation

// Respuesta de “listado” (adaptada para devolver un catálogo a partir del array de regiones)
struct ItemCatalog: Codable {
    var count: Int
    var results: [ItemRef]
}

// Ítem “ligero” de la lista
struct ItemRef: Codable {
    var name: String
    var url: String // Construiremos una URL que apunte al detalle de esta región
}

// Modelo que usa la UI
struct ItemBase: Identifiable {
    var id: String // Usaremos el nombre de la región como ID
    var ref: ItemRef
    var detail: ItemDetail?
}

// Detalle del ítem (adaptado para Covid)
struct ItemDetail: Codable {
    var id: String? // Region name
    var title: String? // Country name
    var description: String? // Region name
    var media: Media?
    var attributes: [NamedValue]?
    var stats: [StatPair]? // Aquí mapearemos los casos por fecha
    var deathStats: [StatPair]? // Stats de muertes
}

struct Media: Codable {
    var primary: String?
    var secondary: String?
}

struct NamedValue: Codable {
    var name: String
    var value: String?
}

struct StatPair: Codable {
    var name: String // Fecha
    var value: Int // Total cases
}

// Modelos intermedios para parsear la respuesta de API Ninjas
struct CovidRegionResponse: Codable {
    let country: String
    let region: String
    let cases: [String: CaseData]?
    let deaths: [String: CaseData]?
}

struct CaseData: Codable {
    let total: Int
    let new: Int
}

// Para el snapshot global (por fecha específica)
struct GlobalSnapshotItem: Codable {
    let country: String
    let region: String
    let date: String
    let confirmed: Int
    let deaths: Int
}
