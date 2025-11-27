import Foundation

protocol UserRequirementProtocol {
    func getLastCountry() -> String?
    func setLastCountry(_ country: String)
}

class UserRequirement: UserRequirementProtocol {
    static let shared = UserRequirement()
    let repo: UserRepository
    
    init(repo: UserRepository = UserRepository.shared) {
        self.repo = repo
    }
    
    func getLastCountry() -> String? {
        repo.localService.getLastCountry()
    }
    
    func setLastCountry(_ country: String) {
        repo.localService.setLastCountry(country)
    }
}
