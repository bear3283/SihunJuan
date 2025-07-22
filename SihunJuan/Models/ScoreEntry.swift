import Foundation

struct ScoreEntry: Codable, Identifiable {
    let id = UUID()
    let name: String
    let score: Int
} 