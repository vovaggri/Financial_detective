import SwiftUI

struct SpoilerModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 0 : 1) // Скрываем основной текст при активном спойлере
            .overlay(
                SpoilerOverlay(isActive: isActive)
                    .allowsHitTesting(false)
            )
    }
}
