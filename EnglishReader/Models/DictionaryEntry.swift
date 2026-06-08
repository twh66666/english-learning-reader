import Foundation

struct DictionaryEntry: Codable, Identifiable, Equatable {
    var id: String { word }
    let word: String
    let phonetic: String?
    let translation: String
    let definition: String?
}
