import Foundation
import SQLite3

struct WebImportSnapshot {
    static let sourceID = "prompt_shortcut_tools"
    let prompts: [Prompt]
    let tags: [Tag]

    static func read(from url: URL) throws -> WebImportSnapshot {
        var database: OpaquePointer?
        guard sqlite3_open_v2(url.path, &database, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            sqlite3_close(database)
            throw StorageError.message("无法读取 Web 导入资料库。")
        }
        defer { sqlite3_close(database) }

        func rows<T>(_ sql: String, transform: (OpaquePointer) throws -> T) throws -> [T] {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
                throw StorageError.message("Web 导入资料库结构不完整。")
            }
            defer { sqlite3_finalize(statement) }
            var result: [T] = []
            var status = sqlite3_step(statement)
            while status == SQLITE_ROW {
                result.append(try transform(statement))
                status = sqlite3_step(statement)
            }
            guard status == SQLITE_DONE else { throw StorageError.message("读取 Web 数据失败，未导入任何内容。") }
            return result
        }

        func text(_ statement: OpaquePointer, _ index: Int32) -> String? {
            guard let bytes = sqlite3_column_text(statement, index) else { return nil }
            return String(decoding: UnsafeBufferPointer(start: bytes, count: Int(sqlite3_column_bytes(statement, index))), as: UTF8.self)
        }

        func requiredText(_ statement: OpaquePointer, _ index: Int32) throws -> String {
            guard let value = text(statement, index) else { throw StorageError.message("Web 数据缺少必要字段。") }
            return value
        }

        func strings(_ value: String) throws -> [String] {
            try JSONDecoder().decode([String].self, from: Data(value.utf8))
        }

        func date(_ statement: OpaquePointer, _ index: Int32) throws -> Date {
            let type = sqlite3_column_type(statement, index)
            if type == SQLITE_INTEGER || type == SQLITE_FLOAT {
                return Date(timeIntervalSince1970: sqlite3_column_double(statement, index) / 1000)
            }
            let value = try requiredText(statement, index)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsed = iso.date(from: value) { return parsed }
            iso.formatOptions = [.withInternetDateTime]
            if let parsed = iso.date(from: value) { return parsed }
            let sqliteDate = DateFormatter()
            sqliteDate.locale = Locale(identifier: "en_US_POSIX")
            sqliteDate.timeZone = TimeZone(secondsFromGMT: 0)
            sqliteDate.dateFormat = "yyyy-MM-dd HH:mm:ss"
            guard let parsed = sqliteDate.date(from: value) else { throw StorageError.message("Web 数据包含无法识别的日期。") }
            return parsed
        }

        let tags: [Tag] = try rows("SELECT id, name, color, createdAt, updatedAt FROM Tag ORDER BY id") { row in
            Tag(id: Int(sqlite3_column_int64(row, 0)), name: try requiredText(row, 1),
                color: nativeColor(try requiredText(row, 2)), createdAt: try date(row, 3), updatedAt: try date(row, 4))
        }
        let prompts: [Prompt] = try rows("SELECT id, title, description, promptText, tags, usageNotes, isFavorite, isTemplate, templateVars, createdAt, updatedAt FROM Prompt ORDER BY id") { row in
            Prompt(id: Int(sqlite3_column_int64(row, 0)), title: try requiredText(row, 1), description: text(row, 2),
                   promptText: try requiredText(row, 3), tags: try strings(requiredText(row, 4)), usageNotes: text(row, 5),
                   isFavorite: sqlite3_column_int(row, 6) != 0, isTemplate: sqlite3_column_int(row, 7) != 0,
                   templateVars: try text(row, 8).map(strings), createdAt: try date(row, 9), updatedAt: try date(row, 10))
        }
        guard Set(tags.map(\.id)).count == tags.count, Set(prompts.map(\.id)).count == prompts.count else {
            throw StorageError.message("Web 数据存在重复来源编号。")
        }
        return WebImportSnapshot(prompts: prompts, tags: tags)
    }

    private static func nativeColor(_ source: String) -> String {
        let tailwind = ["bg-orange-500": "#F97316", "bg-yellow-500": "#EAB308", "bg-purple-500": "#A855F7",
                        "bg-teal-500": "#14B8A6", "bg-blue-500": "#3B82F6", "bg-green-500": "#22C55E",
                        "bg-red-500": "#EF4444", "bg-pink-500": "#EC4899", "bg-indigo-500": "#6366F1"]
        if let mapped = tailwind[source] { return mapped }
        let hex = source.hasPrefix("#") ? String(source.dropFirst()) : source
        if hex.count == 6, hex.allSatisfy({ $0.isHexDigit }) { return "#" + hex.uppercased() }
        return "#78C4ED"
    }
}
