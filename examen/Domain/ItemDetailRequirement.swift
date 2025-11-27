import Foundation

protocol ItemDetailRequirementProtocol {
    func getItemDetail(id: String) async -> ItemDetail? // ID adaptado a String
}

class ItemDetailRequirement: ItemDetailRequirementProtocol {
    static let shared = ItemDetailRequirement()
    let repo: ItemRepository
    
    init(repo: ItemRepository = ItemRepository.shared) {
        self.repo = repo
    }
    
    func getItemDetail(id: String) async -> ItemDetail? {
        await repo.getItemDetail(id: id)
    }
}
