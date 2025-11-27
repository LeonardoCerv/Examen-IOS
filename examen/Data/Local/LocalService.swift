import Foundation

class LocalService {
    static let shared = LocalService()
    
    func getLastCountry() -> String? {
        return UserDefaults.standard.string(forKey: "lastCountry")
    }
    
    func setLastCountry(_ country: String) {
        UserDefaults.standard.set(country, forKey: "lastCountry")
        UserDefaults.standard.synchronize()
    }
}
