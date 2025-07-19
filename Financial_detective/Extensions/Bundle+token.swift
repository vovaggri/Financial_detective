import Foundation

extension Bundle {
  var apiToken: String {
    guard
      let url = self.url(forResource: "Secrets", withExtension: "plist"),
      let data = try? Data(contentsOf: url),
      let dict = try? PropertyListSerialization
                  .propertyList(from: data, options: [], format: nil) as? [String: Any],
      let token = dict["API_TOKEN"] as? String,
      !token.isEmpty
    else {
      fatalError("❌ Не могу прочитать API_TOKEN из Secrets.plist")
    }
    return token
  }
}

