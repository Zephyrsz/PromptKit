import Foundation

struct Prompt: Identifiable, Codable, Hashable {
    let id: Int
    var title: String
    var description: String?
    var promptText: String
    var tags: [String]
    var usageNotes: String?
    var isFavorite: Bool
    var isTemplate: Bool
    var templateVars: [String]?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, description, promptText, tags, usageNotes, isFavorite, isTemplate, templateVars, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        promptText = try container.decode(String.self, forKey: .promptText)
        tags = try container.decode([String].self, forKey: .tags)
        usageNotes = try container.decodeIfPresent(String.self, forKey: .usageNotes)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        isTemplate = try container.decode(Bool.self, forKey: .isTemplate)
        templateVars = try container.decodeIfPresent([String].self, forKey: .templateVars)

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

    init(id: Int, title: String, description: String? = nil, promptText: String, tags: [String] = [], usageNotes: String? = nil, isFavorite: Bool = false, isTemplate: Bool = false, templateVars: [String]? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.promptText = promptText
        self.tags = tags
        self.usageNotes = usageNotes
        self.isFavorite = isFavorite
        self.isTemplate = isTemplate
        self.templateVars = templateVars
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct CreatePromptInput: Codable {
    var title: String
    var description: String?
    var promptText: String
    var tags: [String]
    var usageNotes: String?
    var isFavorite: Bool
    var isTemplate: Bool
    var templateVars: [String]?
}
