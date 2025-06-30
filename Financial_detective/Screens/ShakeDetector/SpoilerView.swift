import SwiftUI

struct SpoilerView: UIViewRepresentable {
    var isActive: Bool
    
    func makeUIView(context: Context) -> EmitterView {
        let view = EmitterView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        
        let emitterCell = CAEmitterCell()
        emitterCell.contents = createSpeckleImage()?.cgImage
        emitterCell.color = UIColor.black.cgColor
        emitterCell.contentsScale = UIScreen.main.scale
        emitterCell.scale = 0.1
        emitterCell.scaleRange = 0.05
        emitterCell.birthRate = 400
        emitterCell.lifetime = 1.0
        emitterCell.velocity = 20
        emitterCell.velocityRange = 10
        emitterCell.emissionRange = .pi * 2
        emitterCell.alphaSpeed = -1.0
        
        view.layer.emitterCells = [emitterCell]
        view.layer.birthRate = 0
        
        return view
    }
    
    func updateUIView(_ uiView: EmitterView, context: Context) {
        uiView.layer.birthRate = isActive ? 1 : 0
        if isActive {
            uiView.layer.beginTime = CACurrentMediaTime()
        }
    }
    
    private func createSpeckleImage() -> UIImage? {
        let size = CGSize(width: 3, height: 3)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
