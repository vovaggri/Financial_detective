import SwiftUI

final class ShakeDetectorConroller: UIViewController {
    var onShake: () -> Void = {}
    
    override var canBecomeFirstResponder: Bool { true }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        becomeFirstResponderWithDelay()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        print("Motion detected: \(motion == .motionShake ? "SHAKE" : "other")")
        guard motion == .motionShake else { return }
        onShake()
    }
    
    func becomeFirstResponderWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = self.becomeFirstResponder()
            print("Become first responder: \(success ? "SUCCESS" : "FAILED")")
        }
    }
}
