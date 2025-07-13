import UIKit

final class ViewController: UIViewController {
    
    
    
    
    
    
    
    
    
    
    
    
    
    

    // MARK: - Outlets
    @IBOutlet private weak var animateLabel: UILabel!   // Connect to the label you want animated
    @IBOutlet private weak var actionButton: UIButton!  // Connect to the single button you keep

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Disable every way of going “back”
        navigationItem.hidesBackButton = true                   // nav‑bar button
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false // swipe‑back

        // 2. Kick‑off label typewriter effect
        animateLabel.text = ""          // start empty
        animateLabel.alpha = 0.1        // faint
        typewriter(text: "SwasthyaSanket", on: animateLabel) { // fade to full when done
            UIView.animate(withDuration: 1.5) { self.animateLabel.alpha = 1 }
        }

        // 3. Give the chosen button a looping pulse
        pulse(button: actionButton)
    }

    // MARK: - Animations
    /// Adds one character every 0.1 s to mimic a typewriter
    private func typewriter(text: String, on label: UILabel, completion: (() -> Void)? = nil) {
        let chars = Array(text)
        for i in chars.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                label.text? += String(chars[i])
                if i == chars.count - 1 { completion?() }
            }
        }
    }

    /// Endless, gentle breathing effect
    private func pulse(button: UIButton) {
        button.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animateKeyframes(
            withDuration: 1.2,
            delay: 0,
            options: [.repeat, .autoreverse, .allowUserInteraction]
        ) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                button.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            }
        }
    }
}
