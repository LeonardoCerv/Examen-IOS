import Foundation

protocol UserServiceProtocol {
    func getCurrentUser() -> String?
    func setCurrentUser(email: String)
    func removeCurrentUser()
}

class UserRepository: UserServiceProtocol {
    static let shared = UserRepository()
    var localService: LocalService
    
    init(localService: LocalService = LocalService.shared) {
        self.localService = localService
    }
    
    func getCurrentUser() -> String? {
        localService.getCurrentUser()
    }
    
    func setCurrentUser(email: String) {
        localService.setCurrentUser(email: email)
    }
    
    func removeCurrentUser() {
        localService.removeCurrentUser()
    }
}
