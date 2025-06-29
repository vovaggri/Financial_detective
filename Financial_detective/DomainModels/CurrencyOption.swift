import Foundation

struct CurrencyOption: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let symbol: String
}
