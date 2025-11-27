import Foundation

protocol ItemListRequirementProtocol {
    func getItemCatalog(date: String) async -> ItemCatalog?
}

class ItemListRequirement: ItemListRequirementProtocol {
    static let shared = ItemListRequirement()
    let repo: ItemRepository
    
    init(repo: ItemRepository = ItemRepository.shared) {
        self.repo = repo
    }
    
    func getItemCatalog(date: String) async -> ItemCatalog? {
        await repo.getItemCatalog(date: date)
    }
}
