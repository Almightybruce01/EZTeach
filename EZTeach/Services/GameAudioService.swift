//
//  GameAudioService.swift
//  EZTeach
//
//  TTS (read aloud), instructions, sound effects, and background music for games.
//

import AVFoundation
import AudioToolbox
import Combine
import SwiftUI

/// Shared service for game audio: read aloud, instructions, sounds, music.
final class GameAudioService: NSObject, ObservableObject {
    static let shared = GameAudioService()
    
    @Published var isMuted = false
    @Published var readAloudEnabled = true
    @Published var backgroundMusicEnabled = true
    
    private let synthesizer = AVSpeechSynthesizer()
    private var bgMusicPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        synthesizer.delegate = nil
        isMuted = UserDefaults.standard.bool(forKey: "gameAudioMuted")
        readAloudEnabled = UserDefaults.standard.object(forKey: "gameReadAloudEnabled") as? Bool ?? true
        backgroundMusicEnabled = UserDefaults.standard.object(forKey: "gameBgMusicEnabled") as? Bool ?? true
        configureAudioSession()
    }
    
    /// Configure audio session for speech playback — required on iOS for TTS to produce sound
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("GameAudioService: Failed to configure audio session — \(error.localizedDescription)")
        }
    }
    
    func persistSettings() {
        UserDefaults.standard.set(isMuted, forKey: "gameAudioMuted")
        UserDefaults.standard.set(readAloudEnabled, forKey: "gameReadAloudEnabled")
        UserDefaults.standard.set(backgroundMusicEnabled, forKey: "gameBgMusicEnabled")
    }
    
    // MARK: - Read Aloud / TTS
    
    /// Standard speak (single utterance)
    func speak(_ text: String, rate: Float = 0.5) {
        guard readAloudEnabled, !isMuted, !text.isEmpty else { return }
        ensureAudioSession()
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        synthesizer.speak(utterance)
    }
    
    /// Fluent, person-like read-aloud with natural pauses between sentences.
    /// Splits on . ! ? and adds postUtteranceDelay for breathing/pacing.
    func speakFluently(_ text: String, rate: Float = 0.45) {
        guard readAloudEnabled, !isMuted, !text.isEmpty else { return }
        ensureAudioSession()
        synthesizer.stopSpeaking(at: .immediate)
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if sentences.isEmpty {
            speak(text, rate: rate)
            return
        }
        for (i, s) in sentences.enumerated() {
            let trimmed = s.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let restored = hasEndPunctuation(trimmed) ? trimmed : trimmed + "."
            let utterance = AVSpeechUtterance(string: restored)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = rate
            utterance.preUtteranceDelay = i == 0 ? 0.15 : 0
            utterance.postUtteranceDelay = i < sentences.count - 1 ? 0.4 : 0.2
            synthesizer.speak(utterance)
        }
    }
    
    private func hasEndPunctuation(_ s: String) -> Bool {
        s.hasSuffix(".") || s.hasSuffix("!") || s.hasSuffix("?")
    }
    
    func speakInstructions(_ text: String) {
        speakFluently(text, rate: 0.45)
    }
    
    /// Re-activate the audio session if needed (e.g. after phone call or interruption)
    private func ensureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("GameAudioService: Could not activate audio session — \(error)")
        }
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Sound Effects (system sounds)
    
    func playSuccess() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1025) // Tink
    }
    
    func playTap() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1104) // Tap
    }
    
    func playCorrect() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1057) // Success
    }
    
    func playWrong() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1053) // Error
    }
    
    func playStart() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(1306) // Begin record
    }
    
    // MARK: - Background Music (placeholder - uses system; add MP3 later)
    
    func playBackgroundMusic() {
        guard backgroundMusicEnabled, !isMuted else { return }
        // To add classical music: bundle an MP3 and use AVAudioPlayer
        // For now we rely on in-game ambience
    }
    
    func stopBackgroundMusic() {
        bgMusicPlayer?.stop()
    }
}
