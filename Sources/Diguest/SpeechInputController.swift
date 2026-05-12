import AVFoundation
import Foundation
@preconcurrency import Speech

@MainActor
final class SpeechInputController: NSObject, ObservableObject {
    @Published private(set) var isAvailable = false
    @Published private(set) var isListening = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var onTranscript: ((String, Bool) -> Void)?

    func probe(localeIdentifier: String = "ja-JP") {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
        isAvailable = recognizer?.supportsOnDeviceRecognition == true
        errorMessage = isAvailable ? nil : "この環境ではオンデバイス音声入力を使えません"
    }

    func toggle(onTranscript: @escaping (String, Bool) -> Void) {
        if isListening {
            stop()
            return
        }

        self.onTranscript = onTranscript
        start(localeIdentifier: "ja-JP")
    }

    func stop() {
        guard isListening else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        errorMessage = nil
    }

    private func start(localeIdentifier: String) {
        let nextRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
        guard let nextRecognizer, nextRecognizer.supportsOnDeviceRecognition else {
            isAvailable = false
            errorMessage = "この環境ではオンデバイス音声入力を使えません"
            return
        }

        recognizer = nextRecognizer
        isAvailable = true

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                guard status == .authorized else {
                    self.errorMessage = "音声認識が許可されていません"
                    return
                }

                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    Task { @MainActor in
                        guard granted else {
                            self.errorMessage = "マイクが許可されていません"
                            return
                        }

                        self.beginRecognition(with: nextRecognizer)
                    }
                }
            }
        }
    }

    private func beginRecognition(with recognizer: SFSpeechRecognizer) {
        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        request.addsPunctuation = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            errorMessage = "マイクを開始できません"
            return
        }

        isListening = true
        errorMessage = nil

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.onTranscript?(result.bestTranscription.formattedString, result.isFinal)
                }

                if error != nil || result?.isFinal == true {
                    self.cleanup()
                    if let error {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func cleanup() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
}
