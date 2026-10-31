import Foundation
import SQLite3

final class SQLiteStore {
    static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PromptKit", isDirectory: true)
            .appendingPathComponent("PromptKit.sqlite")
    }

    private var database: OpaquePointer?
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard sqlite3_open_v2(url.path, &database, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            let error = databaseError()
            sqlite3_close(database)
            database = nil
            throw error
        }
        do {
            sqlite3_busy_timeout(database, 3000)
            try execute("PRAGMA journal_mode = WAL")
            let version = try query("PRAGMA user_version") { Int(sqlite3_column_int($0, 0)) }.first ?? 0
            guard version <= 2 else { throw StorageError.message("数据库版本较新，请升级 App 后重试。") }
            if version == 0 {
                try execute("BEGIN IMMEDIATE")
                do {
                    try execute("""
                        CREATE TABLE prompts (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            title TEXT NOT NULL,
                            description TEXT,
                            prompt_text TEXT NOT NULL,
                            tags TEXT NOT NULL,
                            usage_notes TEXT,
                            is_favorite INTEGER NOT NULL DEFAULT 0,
                            is_template INTEGER NOT NULL DEFAULT 0,
                            template_vars TEXT,
                            created_at REAL NOT NULL,
                            updated_at REAL NOT NULL
                        )
                        """)
                    try execute("""
                        CREATE TABLE tags (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            name TEXT NOT NULL UNIQUE,
                            color TEXT NOT NULL,
                            created_at REAL NOT NULL,
                            updated_at REAL NOT NULL
                        )
                        """)
                    try execute("PRAGMA user_version = 1")
                    try execute("COMMIT")
                } catch {
                    try? execute("ROLLBACK")
                    throw error
                }
            }
            if version < 2 {
                try execute("BEGIN IMMEDIATE")
                do {
                    try execute("""
                        CREATE TABLE import_receipts (
                            source TEXT NOT NULL,
                            entity TEXT NOT NULL,
                            source_id INTEGER NOT NULL,
                            local_id INTEGER NOT NULL,
                            PRIMARY KEY (source, entity, source_id)
                        )
                        """)
                    try execute("PRAGMA user_version = 2")
                    try execute("COMMIT")
                } catch {
                    try? execute("ROLLBACK")
                    throw error
                }
            }
        } catch {
            sqlite3_close(database)
            database = nil
            throw error
        }
    }

    deinit { sqlite3_close(database) }

    func importWebSnapshot(from url: URL) throws {
        let snapshot = try WebImportSnapshot.read(from: url)
        try execute("BEGIN IMMEDIATE")
        do {
            var knownTags = Dictionary(try loadTags().map { ($0.name, $0.id) }, uniquingKeysWith: { first, _ in first })
            func ensureTag(name: String, color: String, createdAt: Date, updatedAt: Date) throws -> Int {
                if let id = knownTags[name] { return id }
                try execute("INSERT INTO tags (name, color, created_at, updated_at) VALUES (?, ?, ?, ?)",
                            [.text(name), .text(color), .number(createdAt.timeIntervalSince1970), .number(updatedAt.timeIntervalSince1970)])
                let id = Int(sqlite3_last_insert_rowid(database))
                knownTags[name] = id
                return id
            }
            for tag in snapshot.tags where try !hasImported(entity: "tag", id: tag.id) {
                let localID = try ensureTag(name: tag.name, color: tag.color, createdAt: tag.createdAt, updatedAt: tag.updatedAt)
                try recordImport(entity: "tag", sourceID: tag.id, localID: localID)
            }
            for prompt in snapshot.prompts where try !hasImported(entity: "prompt", id: prompt.id) {
                for name in prompt.tags {
                    _ = try ensureTag(name: name, color: "#78C4ED", createdAt: prompt.createdAt, updatedAt: prompt.updatedAt)
                }
                try execute("""
                    INSERT INTO prompts (title, description, prompt_text, tags, usage_notes, is_favorite,
                        is_template, template_vars, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, [.text(prompt.title), optional(prompt.description), .text(prompt.promptText), .text(try encodeArray(prompt.tags)),
                          optional(prompt.usageNotes), .integer(prompt.isFavorite ? 1 : 0), .integer(prompt.isTemplate ? 1 : 0),
                          try prompt.templateVars.map { .text(try encodeArray($0)) } ?? .null,
                          .number(prompt.createdAt.timeIntervalSince1970), .number(prompt.updatedAt.timeIntervalSince1970)])
                try recordImport(entity: "prompt", sourceID: prompt.id, localID: Int(sqlite3_last_insert_rowid(database)))
            }
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func hasImported(entity: String, id: Int) throws -> Bool {
        try !query("SELECT 1 FROM import_receipts WHERE source=? AND entity=? AND source_id=?",
                   [.text(WebImportSnapshot.sourceID), .text(entity), .integer(id)]) { _ in true }.isEmpty
    }

    private func recordImport(entity: String, sourceID: Int, localID: Int) throws {
        // Receipts survive local edits/deletions so a later launch cannot resurrect records.
        try execute("INSERT INTO import_receipts (source, entity, source_id, local_id) VALUES (?, ?, ?, ?)",
                    [.text(WebImportSnapshot.sourceID), .text(entity), .integer(sourceID), .integer(localID)])
    }

    func loadPrompts() throws -> [Prompt] {
        try query("SELECT id, title, description, prompt_text, tags, usage_notes, is_favorite, is_template, template_vars, created_at, updated_at FROM prompts ORDER BY updated_at DESC, id DESC") { statement in
            Prompt(
                id: Int(sqlite3_column_int64(statement, 0)),
                title: string(statement, 1)!,
                description: string(statement, 2),
                promptText: string(statement, 3)!,
                tags: try decodeArray(string(statement, 4)),
                usageNotes: string(statement, 5),
                isFavorite: sqlite3_column_int(statement, 6) != 0,
                isTemplate: sqlite3_column_int(statement, 7) != 0,
                templateVars: try string(statement, 8).map { try decodeArray($0) },
                createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 9)),
                updatedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 10))
            )
        }
    }

    func loadTags() throws -> [Tag] {
        try query("SELECT id, name, color, created_at, updated_at FROM tags ORDER BY id") { statement in
            Tag(id: Int(sqlite3_column_int64(statement, 0)), name: string(statement, 1)!, color: string(statement, 2)!,
                createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 3)),
                updatedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 4)))
        }
    }

    func savePrompt(_ input: CreatePromptInput, id: Int? = nil) throws {
        let title = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !input.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StorageError.message("请填写标题和正文。")
        }
        let variables = input.isTemplate ? TemplateText.variables(in: input.promptText) : []
        guard !input.isTemplate || !variables.isEmpty else {
            throw StorageError.message("模板至少需要一个填空项；无需填空的内容请保存为提示词笔记。")
        }
        let now = Date().timeIntervalSince1970
        var values: [Value] = [
            .text(title), optional(input.description), .text(input.promptText), .text(try encodeArray(input.tags)),
            optional(input.usageNotes), .integer(input.isFavorite ? 1 : 0), .integer(input.isTemplate ? 1 : 0),
            input.isTemplate ? .text(try encodeArray(variables)) : .null
        ]
        if let id = id {
            values += [.number(now), .integer(id)]
            try execute("UPDATE prompts SET title=?, description=?, prompt_text=?, tags=?, usage_notes=?, is_favorite=?, is_template=?, template_vars=?, updated_at=? WHERE id=?", values)
            guard sqlite3_changes(database) > 0 else { throw StorageError.message("这条内容已不存在，请返回列表重试。") }
        } else {
            values += [.number(now), .number(now)]
            try execute("INSERT INTO prompts (title, description, prompt_text, tags, usage_notes, is_favorite, is_template, template_vars, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", values)
        }
    }

    func deletePrompt(id: Int) throws {
        try execute("DELETE FROM prompts WHERE id=?", [.integer(id)])
    }

    func setFavorite(id: Int, isFavorite: Bool) throws {
        try execute("UPDATE prompts SET is_favorite=?, updated_at=? WHERE id=?", [.integer(isFavorite ? 1 : 0), .number(Date().timeIntervalSince1970), .integer(id)])
        guard sqlite3_changes(database) > 0 else { throw StorageError.message("这条内容已不存在，请返回列表重试。") }
    }

    func createTag(_ input: CreateTagInput) throws {
        let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw StorageError.message("请输入标签名称。") }
        guard try !loadTags().contains(where: { $0.name == name }) else {
            throw StorageError.message("标签「\(name)」已存在，请使用已有标签。")
        }
        let now = Date().timeIntervalSince1970
        try execute("INSERT INTO tags (name, color, created_at, updated_at) VALUES (?, ?, ?, ?)", [.text(name), .text(input.color), .number(now), .number(now)])
    }

    func deleteTag(id: Int) throws {
        if let tag = try loadTags().first(where: { $0.id == id }),
           try loadPrompts().contains(where: { $0.tags.contains(tag.name) }) {
            throw StorageError.message("标签「\(tag.name)」仍被使用，请先从相关笔记或模板中移除。")
        }
        try execute("DELETE FROM tags WHERE id=?", [.integer(id)])
    }

    private enum Value { case text(String), integer(Int), number(Double), null }

    private func optional(_ value: String?) -> Value { value.map(Value.text) ?? .null }

    private func prepare(_ sql: String, _ values: [Value]) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement = statement else {
            throw databaseError()
        }
        for (index, value) in values.enumerated() {
            let position = Int32(index + 1)
            let result: Int32
            switch value {
            case .text(let text):
                result = text.withCString {
                    sqlite3_bind_text(statement, position, $0, Int32(text.utf8.count), transient)
                }
            case .integer(let integer): result = sqlite3_bind_int64(statement, position, Int64(integer))
            case .number(let number): result = sqlite3_bind_double(statement, position, number)
            case .null: result = sqlite3_bind_null(statement, position)
            }
            guard result == SQLITE_OK else {
                sqlite3_finalize(statement)
                throw databaseError()
            }
        }
        return statement
    }

    private func execute(_ sql: String, _ values: [Value] = []) throws {
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }
        var result = sqlite3_step(statement)
        while result == SQLITE_ROW { result = sqlite3_step(statement) }
        guard result == SQLITE_DONE else { throw databaseError() }
    }

    private func query<T>(_ sql: String, _ values: [Value] = [], row: (OpaquePointer) throws -> T) throws -> [T] {
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }
        var rows: [T] = []
        var result = sqlite3_step(statement)
        while result == SQLITE_ROW {
            rows.append(try row(statement))
            result = sqlite3_step(statement)
        }
        guard result == SQLITE_DONE else { throw databaseError() }
        return rows
    }

    private func string(_ statement: OpaquePointer, _ index: Int32) -> String? {
        guard let value = sqlite3_column_text(statement, index) else { return nil }
        return String(decoding: UnsafeBufferPointer(start: value, count: Int(sqlite3_column_bytes(statement, index))), as: UTF8.self)
    }

    private func encodeArray(_ values: [String]) throws -> String {
        String(decoding: try JSONEncoder().encode(values), as: UTF8.self)
    }

    private func decodeArray(_ value: String?) throws -> [String] {
        try JSONDecoder().decode([String].self, from: Data((value ?? "[]").utf8))
    }

    private func databaseError() -> StorageError {
        .message("本地数据库操作失败：\(String(cString: sqlite3_errmsg(database)))")
    }
}

enum StorageError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let message): return message }
    }
}
