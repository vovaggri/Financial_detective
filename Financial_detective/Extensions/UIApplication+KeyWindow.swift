import SwiftUI

extension UIApplication {
  /// Находит текущее key window, даже в SwiftUI App lifecycle
  var keyWindowInConnectedScenes: UIWindow? {
    return self.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}
