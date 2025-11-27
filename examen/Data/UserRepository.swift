import Foundation

protocol UserServiceProtocol {
    func getLastCountry() -> String?
    func setLastCountry(_ country: String)
}

class UserRepository: UserServiceProtocol {
    static let shared = UserRepository()
    var localService: LocalService
    
    init(localService: LocalService = LocalService.shared) {
        self.localService = localService
    }
    
    func getLastCountry() -> String? {
        localService.getLastCountry()
    }
    
    func setLastCountry(_ country: String) {
        localService.setLastCountry(country)
    }
}
