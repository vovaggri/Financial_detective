import Foundation

struct UpdateAccountRequest: Encodable {
    let name: String
    let balance: String
    let currency: String
}

