import AVFoundation
import MediaPlayer
import UIKit

final class VolumeButtonPageController: ObservableObject {
    var onNextPage: (() -> Void)?
    var onPreviousPage: (() -> Void)?

    private var observation: NSKeyValueObservation?
    private var baselineVolume: Float = 0.5
    private let volumeView = MPVolumeView(frame: .zero)
    private var isResetting = false

    func start() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }

        installHiddenVolumeView()
        baselineVolume = 0.5
        resetSystemVolume(to: baselineVolume)

        observation = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let self, let value = change.newValue else { return }
            DispatchQueue.main.async {
                self.handleVolumeChange(value)
            }
        }
    }

    func stop() {
        observation?.invalidate()
        observation = nil
        volumeView.removeFromSuperview()
    }

    private func handleVolumeChange(_ value: Float) {
        guard !isResetting else { return }

        if value > baselineVolume {
            onNextPage?()
        } else if value < baselineVolume {
            onPreviousPage?()
        }

        resetSystemVolume(to: baselineVolume)
    }

    private func installHiddenVolumeView() {
        guard volumeView.superview == nil, let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return
        }

        volumeView.alpha = 0.01
        volumeView.frame = CGRect(x: -100, y: -100, width: 10, height: 10)
        window.addSubview(volumeView)
    }

    private func resetSystemVolume(to value: Float) {
        guard let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first else { return }
        isResetting = true
        slider.value = value
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.isResetting = false
        }
    }
}
