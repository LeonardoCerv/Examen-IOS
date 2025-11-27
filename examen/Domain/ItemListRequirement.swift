import Foundation

protocol ItemListRequirementProtocol {
    func getItemCatalog(limit: Int?) async -> ItemCatalog?
    func setCountry(_ country: String) // Added to support country selection
}

class ItemListRequirement: ItemListRequirementProtocol {
    static let shared = ItemListRequirement()
    let repo: ItemRepository
    
    init(repo: ItemRepository = ItemRepository.shared) {
        self.repo = repo
    }
    
    func getItemCatalog(limit: Int?) async -> ItemCatalog? {
        await repo.getItemCatalog(limit: limit)
    }
    
    func setCountry(_ country: String) {
        repo.setCountry(country)
    }
}
