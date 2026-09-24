import AVFoundation

/// The hidden reward for mashing all three keys at once: a spoken one-liner.
/// Uses the system speech synthesizer, so there's no audio asset to ship and
/// nothing to license. Retained here because AVSpeechSynthesizer must outlive
/// the utterance to actually speak.
@MainActor
final class EasterEgg {
    private let synthesizer = AVSpeechSynthesizer()

    private let lines = [
        "Whoa! All three at once. Show off.",
        "You unlocked absolutely nothing. Congratulations.",
        "Easter egg activated. Please deposit one coffee.",
        "Achievement unlocked: aggressive mashing.",
        "Three keys, zero chill.",
        "Beep boop. That tickles.",
        "Magic Keys senses great power in you. And greasy fingers.",
        "That's a chord! Somebody call a band.",
    ]

    func fire() {
        // Don't stack utterances if the key is mashed repeatedly.
        if synthesizer.isSpeaking { return }
        guard let line = lines.randomElement() else { return }
        let utterance = AVSpeechUtterance(string: line)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.1
        synthesizer.speak(utterance)
    }
}
