import Foundation
import SwiftUI

struct Tag: Identifiable, Codable, Hashable {
    let id: Int
    var name: String
    var color: String
    let createdAt: Date
    let updatedAt: Date

    var swiftUIColor: Color {
        Color(hex: color)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, color, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(String.self, forKey: .color)

        createdAt = try container.decodePromptDate(forKey: .createdAt)
        updatedAt = try container.decodePromptDate(forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(createdAt.timeIntervalSince1970 * 1000, forKey: .createdAt)
        try container.encode(updatedAt.timeIntervalSince1970 * 1000, forKey: .updatedAt)
    }

    init(id: Int, name: String, color: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct CreateTagInput: Codable {
    var name: String
    var color: String
}
