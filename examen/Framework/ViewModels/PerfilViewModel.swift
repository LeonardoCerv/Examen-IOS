import Foundation
import Combine

class PerfilViewModel: ObservableObject {
    @Published var email = ""
    var userReq: UserRequirementProtocol
    
    init(userReq: UserRequirementProtocol = UserRequirement.shared) {
        self.userReq = userReq
    }
    
    @MainActor
    func getCurrentUser() {
        email = userReq.getCurrentUser() ?? ""
    }
    
    @MainActor
    func logOut() {
        email = ""
        userReq.removeCurrentUser()
    }
}
