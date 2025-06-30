import SwiftUI

struct ShakeDetectorView: UIViewControllerRepresentable {
    var onShake: () -> Void
    
    func makeUIViewController(context: Context) -> ShakeDetectorConroller {
        let controller = ShakeDetectorConroller()
        controller.onShake = onShake
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ShakeDetectorConroller, context: Context) {}
}
