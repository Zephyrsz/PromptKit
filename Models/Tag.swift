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

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let createdAtString = try? container.decode(String.self, forKey: .createdAt),
           let date = dateFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            createdAt = Date()
        }

        if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt),
           let date = dateFormatter.date(from: updatedAtString) {
            updatedAt = date
        } else {
            updatedAt = Date()
        }
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
