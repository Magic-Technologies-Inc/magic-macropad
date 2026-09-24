import AVFoundation

/// The hidden reward for mashing all three keys at once: a fart. The sound is a
/// short bundled WAV (`fart.wav`), played via AVAudioPlayer. Retained here so it
/// outlives the call and actually plays.
@MainActor
final class EasterEgg {
    private let player: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "fart", withExtension: "wav") else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }()

    func fire() {
        guard let player else { return }
        player.currentTime = 0   // restart if it's mashed again mid-play
        player.play()
    }
}
