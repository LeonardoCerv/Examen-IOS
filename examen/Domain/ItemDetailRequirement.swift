import Foundation

protocol ItemDetailRequirementProtocol {
    func getItemDetail(country: String) async -> ItemDetail?
}

class ItemDetailRequirement: ItemDetailRequirementProtocol {
    static let shared = ItemDetailRequirement()
    let repo: ItemRepository
    
    init(repo: ItemRepository = ItemRepository.shared) {
        self.repo = repo
    }
    
    func getItemDetail(country: String) async -> ItemDetail? {
        await repo.getItemDetail(country: country)
    }
}
