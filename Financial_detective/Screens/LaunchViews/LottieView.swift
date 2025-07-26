import SwiftUI
import Lottie

/// Простая SwiftUI‑обёртка над Lottie AnimationView
struct LottieView: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let onComplete: (() -> Void)?

    init(
        _ name: String,
        loopMode: LottieLoopMode = .playOnce,
        onComplete: (() -> Void)? = nil
    ) {
        self.animationName = name
        self.loopMode = loopMode
        self.onComplete = onComplete
    }

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: animationName)
        view.contentMode = .scaleAspectFit
        view.loopMode = loopMode
        view.backgroundBehavior = .pauseAndRestore
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if !uiView.isAnimationPlaying {
            uiView.play { finished in
                if finished { onComplete?() }
            }
        }
    }
}

