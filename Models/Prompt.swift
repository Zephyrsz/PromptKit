import Foundation

enum PromptKind: String, CaseIterable, Identifiable {
    case note, template
    var id: Self { self }
    var title: String { self == .note ? "提示词笔记" : "模板" }
    var icon: String { self == .note ? "note.text" : "text.badge.plus" }
}

enum TemplateText {
    // Both the original web syntax and the first iOS syntax remain usable.
    private static let pattern = #"\$\{([^{}\r\n]+)\}|\{\{([^{}\r\n]+)\}\}"#
    private static let regex = try! NSRegularExpression(pattern: pattern)

    static func variables(in text: String) -> [String] {
        let source = text as NSString
        var names: [String] = []
        for match in regex.matches(in: text, range: NSRange(location: 0, length: source.length)) {
            let name = name(for: match, in: source)
            if !name.isEmpty, !names.contains(name) { names.append(name) }
        }
        return names
    }

    static func render(_ text: String, values: [String: String]) -> String {
        let source = text as NSString
        let result = NSMutableString(string: text)
        for match in regex.matches(in: text, range: NSRange(location: 0, length: source.length)).reversed() {
            let name = name(for: match, in: source)
            if !name.isEmpty, let value = values[name], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result.replaceCharacters(in: match.range, with: value)
            }
        }
        return result as String
    }

    private static func name(for match: NSTextCheckingResult, in source: NSString) -> String {
        let range = match.range(at: match.range(at: 1).location == NSNotFound ? 2 : 1)
        return source.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

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

    var kind: PromptKind { isTemplate ? .template : .note }
    var variableNames: [String] { isTemplate ? TemplateText.variables(in: promptText) : [] }

    func rendered(with values: [String: String]) -> String {
        isTemplate ? TemplateText.render(promptText, values: values) : promptText
    }

    func missingVariables(in values: [String: String]) -> [String] {
        variableNames.filter { (values[$0] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

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

        createdAt = try container.decodePromptDate(forKey: .createdAt)
        updatedAt = try container.decodePromptDate(forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(promptText, forKey: .promptText)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(usageNotes, forKey: .usageNotes)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(isTemplate, forKey: .isTemplate)
        try container.encodeIfPresent(templateVars, forKey: .templateVars)
        try container.encode(createdAt.timeIntervalSince1970 * 1000, forKey: .createdAt)
        try container.encode(updatedAt.timeIntervalSince1970 * 1000, forKey: .updatedAt)
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

extension CreatePromptInput {
    init(editing prompt: Prompt?, title: String, promptText: String, tags: [String], kind: PromptKind) {
        self.init(title: title.trimmingCharacters(in: .whitespacesAndNewlines), description: prompt?.description,
                  promptText: promptText, tags: tags, usageNotes: prompt?.usageNotes,
                  isFavorite: prompt?.isFavorite ?? false, isTemplate: kind == .template,
                  templateVars: kind == .template ? TemplateText.variables(in: promptText) : nil)
    }
}

extension KeyedDecodingContainer {
    func decodePromptDate(forKey key: Key) throws -> Date {
        if let milliseconds = try? decode(Double.self, forKey: key) {
            return Date(timeIntervalSince1970: milliseconds / 1000)
        }
        let value = try decode(String.self, forKey: key)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) { return date }
        throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "无法解析日期：\(value)")
    }
}
