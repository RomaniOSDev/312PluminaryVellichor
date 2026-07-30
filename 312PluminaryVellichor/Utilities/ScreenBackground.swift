import SwiftUI
import UIKit

struct ScreenBackground: ViewModifier {
    var imageName: String = "img_background"
    var opacity: Double = 0.22

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .opacity(opacity)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func screenBackground(_ imageName: String = "img_background", opacity: Double = 0.22) -> some View {
        modifier(ScreenBackground(imageName: imageName, opacity: opacity))
    }

    /// Dismisses keyboard on taps outside text inputs without blocking controls.
    func dismissKeyboardOnTap() -> some View {
        background(KeyboardDismissInstaller())
    }
}

private struct KeyboardDismissInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = PassthroughView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            context.coordinator.install(on: window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let window = uiView.window else { return }
            context.coordinator.install(on: window)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var window: UIWindow?
        private var recognizer: UITapGestureRecognizer?

        func install(on window: UIWindow) {
            if self.window === window, recognizer != nil { return }
            remove()
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.cancelsTouchesInView = false
            tap.requiresExclusiveTouchType = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            self.window = window
            self.recognizer = tap
        }

        func remove() {
            if let recognizer, let window {
                window.removeGestureRecognizer(recognizer)
            }
            recognizer = nil
            window = nil
        }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended, let window else { return }
            let point = gesture.location(in: window)
            if let hit = window.hitTest(point, with: nil), hit.isTextInput {
                return
            }
            window.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            !(touch.view?.isTextInput ?? false)
        }

        deinit { remove() }
    }
}

private final class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        nil
    }
}

private extension UIView {
    var isTextInput: Bool {
        if self is UITextField || self is UITextView { return true }
        var current: UIView? = self
        while let view = current {
            if view is UITextField || view is UITextView { return true }
            current = view.superview
        }
        return false
    }
}
