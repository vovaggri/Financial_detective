import UIKit

final class EmitterView: UIView {
    override class var layerClass: AnyClass { CAEmitterLayer.self }
    
    override var layer: CAEmitterLayer { super.layer as! CAEmitterLayer }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        layer.emitterSize = bounds.size
        layer.emitterShape = .rectangle
    }
}
