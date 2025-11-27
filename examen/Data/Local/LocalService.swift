import Foundation

class LocalService {
    static let shared = LocalService()
    
    func getCurrentUser() -> String? {
        UserDefaults.standard.string(forKey: "currentUser")
    }
    
    func setCurrentUser(email: String) {
        UserDefaults.standard.set(email, forKey: "currentUser")
    }
    
    func removeCurrentUser() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    func getLastCountry() -> String? {
        UserDefaults.standard.string(forKey: "lastCountry")
    }
    
    func setLastCountry(_ country: String) {
        UserDefaults.standard.set(country, forKey: "lastCountry")
    }
}
