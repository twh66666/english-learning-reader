import AVFoundation
import SwiftUI

struct DictionarySheet: View {
    let entry: DictionaryEntry

    @StateObject private var pronunciationPlayer = OnlinePronunciationPlayer()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.word)
                    .font(.title2.bold())
                if let phonetic = entry.phonetic, !phonetic.isEmpty {
                    Text(phonetic)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Button {
                Task {
                    await pronunciationPlayer.play(word: entry.word)
                }
            } label: {
                Label(pronunciationPlayer.isLoading ? "加载中" : "联网发音", systemImage: "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)
            .disabled(pronunciationPlayer.isLoading)

            if let message = pronunciationPlayer.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(entry.translation)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if let definition = entry.definition, !definition.isEmpty {
                Divider()
                Text(definition)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(22)
    }
}

@MainActor
private final class OnlinePronunciationPlayer: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var player: AVPlayer?

    func play(word: String) async {
        let normalized = WordTokenizer.normalize(word)
        guard !normalized.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let audioURL = try await resolveAudioURL(for: normalized) else {
                errorMessage = "暂时没有找到在线发音。"
                return
            }

            let player = AVPlayer(url: audioURL)
            self.player = player
            player.play()
        } catch {
            errorMessage = "在线发音加载失败。"
        }
    }

    private func resolveAudioURL(for word: String) async throws -> URL? {
        if let dictionaryURL = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word)") {
            let (data, _) = try await URLSession.shared.data(from: dictionaryURL)
            if let entries = try? JSONDecoder().decode([FreeDictionaryEntry].self, from: data) {
                for entry in entries {
                    for phonetic in entry.phonetics ?? [] {
                        guard var audio = phonetic.audio, !audio.isEmpty else { continue }
                        if audio.hasPrefix("//") {
                            audio = "https:" + audio
                        }
                        if let url = URL(string: audio), url.scheme == "https" {
                            return url
                        }
                    }
                }
            }
        }

        let query = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
        return URL(string: "https://translate.google.com/translate_tts?ie=UTF-8&tl=en&client=tw-ob&q=\(query)")
    }
}

private struct FreeDictionaryEntry: Decodable {
    let phonetics: [FreeDictionaryPhonetic]?
}

private struct FreeDictionaryPhonetic: Decodable {
    let audio: String?
}
