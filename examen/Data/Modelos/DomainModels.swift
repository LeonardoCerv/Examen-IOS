import Foundation

// Respuesta de "listado" (snapshot global de países)
struct ItemCatalog: Codable {
    var count: Int
    var results: [ItemRef]
}

// Ítem "ligero" de la lista (país con datos agregados)
struct ItemRef: Codable {
    var name: String // Nombre del país
    var url: String // URL para obtener el detalle del país
}

// Modelo que usa la UI
struct ItemBase: Identifiable {
    var id: String // Nombre del país
    var ref: ItemRef
    var detail: ItemDetail?
    var cases: Int // Casos totales para la fecha seleccionada
    var deaths: Int // Muertes totales para la fecha seleccionada
    var newCases: Int // Casos nuevos
    var newDeaths: Int // Muertes nuevas
}

// Detalle del ítem (datos completos de un país)
struct ItemDetail: Codable {
    var id: String? // Nombre del país
    var title: String? // Nombre del país
    var description: String? // Descripción adicional
    var media: Media?
    var attributes: [NamedValue]?
    var stats: [StatPair]? // Series temporal de casos
    var deathStats: [StatPair]? // Series temporal de muertes
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
// Modelo para consultas con series temporales (sin parámetro date)
struct CovidCountryResponse: Codable {
    let country: String
    let region: String
    let cases: [String: CaseData]?
    let deaths: [String: CaseData]?
}

// Modelo para snapshot por fecha específica (con parámetro date)
struct CovidSnapshotResponse: Codable {
    let country: String
    let region: String
    let cases: SnapshotData?
    let deaths: SnapshotData?
}

struct CaseData: Codable {
    let total: Int
    let new: Int
}

struct SnapshotData: Codable {
    let total: Int
    let new: Int
}
