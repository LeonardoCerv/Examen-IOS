import Foundation
import Combine

class ItemListViewModel: ObservableObject {
    @Published var items = [ItemBase]()
    @Published var isLoading = false
    @Published var searchText: String = ""
    @Published var hasError = false
    @Published var errorMessage = ""
    
    var listReq: ItemListRequirementProtocol
    var detailReq: ItemDetailRequirementProtocol
    var userReq: UserRequirementProtocol
    
    init(listReq: ItemListRequirementProtocol = ItemListRequirement.shared,
         detailReq: ItemDetailRequirementProtocol = ItemDetailRequirement.shared,
         userReq: UserRequirementProtocol = UserRequirement.shared) {
        self.listReq = listReq
        self.detailReq = detailReq
        self.userReq = userReq
        
        // Cargar último país buscado
        if let last = userReq.getLastCountry(), !last.isEmpty {
            self.searchText = last
        } else {
            self.searchText = "Canada" // Default
        }
    }
    
    @MainActor
    func loadItems(limit: Int? = nil) async {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        hasError = false
        errorMessage = ""
        items.removeAll()
        
        // Guardar preferencia
        userReq.setLastCountry(searchText)
        
        // Actualizar el país en el repositorio
        listReq.setCountry(searchText)
        
        let result = await listReq.getItemCatalog(limit: limit)
        
        // Validar si hay resultados
        guard let refs = result?.results, !refs.isEmpty else {
            isLoading = false
            hasError = true
            errorMessage = "No se encontraron datos para '\(searchText)'. Verifica el nombre e intenta de nuevo."
            return
        }
        
        for ref in refs {
            let regionName = ref.name
            let detail = await detailReq.getItemDetail(id: regionName)
            
            if let detail = detail {
                self.items.append(ItemBase(id: regionName, ref: ref, detail: detail))
            }
        }
        
        // Si después de todo no hay items (falló detalle o algo)
        if items.isEmpty {
            hasError = true
            errorMessage = "No se pudo cargar el detalle de las regiones."
        }
        
        isLoading = false
    }
    
    @MainActor
    func search() async {
        await loadItems()
    }
}
