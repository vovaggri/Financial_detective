import SwiftUI

struct SpoilerOverlay: View {
    let isActive: Bool
    
    var body: some View {
        GeometryReader { geometry in
            if isActive {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [.black, .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    SpoilerView(isActive: true)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
}
