import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var messageAlert = ""
    @Published var showAlert = false
    
    var userReq: UserRequirementProtocol
    
    init(userReq: UserRequirementProtocol = UserRequirement.shared) {
        self.userReq = userReq
    }
    
    @MainActor
    func setCurrentUser() {
        if email.isEmpty {
            messageAlert = "Correo inválido"
            showAlert = true
        } else {
            userReq.setCurrentUser(email: email)
        }
    }
    
    @MainActor
    func getCurrentUser() {
        email = userReq.getCurrentUser() ?? ""
    }
}
