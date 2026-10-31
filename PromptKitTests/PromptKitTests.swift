import Foundation
import XCTest
import SQLite3
@testable import PromptKit

final class PromptKitTests: XCTestCase {
    @MainActor
    func testV1MigrationAndImportFailureKeepLocalDataAndAllowRetry() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/PromptKit.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let source = try XCTUnwrap(Bundle.main.url(forResource: "WebPrompts", withExtension: "sqlite"))
        let originalSource = try Data(contentsOf: source)
        do {
            let local = DataStore(databaseURL: url)
            let saved = await local.createPrompt(CreatePromptInput(title: "升级前内容", description: nil, promptText: "原文", tags: [], usageNotes: nil, isFavorite: false, isTemplate: false, templateVars: nil))
            XCTAssertTrue(saved)
        }
        try executeSQL("DROP TABLE import_receipts; PRAGMA user_version=1; CREATE TRIGGER fail_import BEFORE INSERT ON prompts BEGIN SELECT RAISE(ABORT, 'test failed write'); END;", at: url)
        let failed = DataStore(databaseURL: url, importURL: source)
        XCTAssertNotNil(failed.importErrorMessage)
        XCTAssertEqual(failed.prompts.map(\.title), ["升级前内容"])
        XCTAssertTrue(failed.tags.isEmpty)
        try executeSQL("DROP TRIGGER fail_import", at: url)
        let retried = DataStore(databaseURL: url, importURL: source)
        XCTAssertNil(retried.errorMessage)
        XCTAssertNil(retried.importErrorMessage)
        XCTAssertEqual(retried.prompts.count, 20)
        XCTAssertEqual(retried.tags.count, 20)
        XCTAssertEqual(retried.prompts.first { $0.title == "升级前内容" }?.promptText, "原文")
        XCTAssertEqual(try Data(contentsOf: source), originalSource)
    }

    private func executeSQL(_ sql: String, at url: URL) throws {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else { throw StorageError.message("Test database could not open") }
        defer { sqlite3_close(db) }
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw StorageError.message(String(cString: sqlite3_errmsg(db)))
        }
    }

    func testBundledWebSnapshotHasAllOriginalDataAndRecoverableTags() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "WebPrompts", withExtension: "sqlite"))
        let snapshot = try WebImportSnapshot.read(from: url)
        XCTAssertEqual(snapshot.prompts.count, 19)
        XCTAssertEqual(snapshot.prompts.filter(\.isTemplate).count, 7)
        XCTAssertEqual(snapshot.tags.count, 13)
        XCTAssertEqual(Set(snapshot.prompts.flatMap(\.tags)).subtracting(snapshot.tags.map(\.name)),
                       Set(["IT", "健康", "工具", "生活", "知识", "编程", "趣味"]))
        let note = try XCTUnwrap(snapshot.prompts.first { $0.id == 3 })
        XCTAssertEqual(note.title, "提示词修改器")
        XCTAssertEqual(note.createdAt.timeIntervalSince1970, 1762219964.697, accuracy: 0.001)
        XCTAssertEqual(snapshot.tags.first { $0.name == "AI" }?.color, "#F97316")
    }

    @MainActor
    func testWebImportMergesWithoutOverwritingAndDoesNotDuplicateOnReopen() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/PromptKit.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let source = try XCTUnwrap(Bundle.main.url(forResource: "WebPrompts", withExtension: "sqlite"))
        let original = try WebImportSnapshot.read(from: source)
        let local = DataStore(databaseURL: url)
        let saved = await local.createPrompt(CreatePromptInput(title: "本地内容", description: nil, promptText: "保留本地数据", tags: [], usageNotes: nil, isFavorite: true, isTemplate: false, templateVars: nil))
        XCTAssertTrue(saved)
        let tagSaved = await local.createTag(CreateTagInput(name: "AI", color: "#123456"))
        XCTAssertTrue(tagSaved)
        let store = DataStore(databaseURL: url, importURL: source)
        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.prompts.count, 20)
        XCTAssertEqual(store.tags.count, 20)
        XCTAssertEqual(store.tags.first { $0.name == "AI" }?.color, "#123456")
        XCTAssertEqual(store.prompts.first { $0.title == "本地内容" }?.promptText, "保留本地数据")
        for incoming in original.prompts {
            let imported = try XCTUnwrap(store.prompts.first { $0.title == incoming.title })
            XCTAssertEqual(imported.promptText, incoming.promptText)
            XCTAssertEqual(imported.description, incoming.description)
            XCTAssertEqual(imported.usageNotes, incoming.usageNotes)
            XCTAssertEqual(imported.tags, incoming.tags)
            XCTAssertEqual(imported.isTemplate, incoming.isTemplate)
            XCTAssertEqual(imported.isFavorite, incoming.isFavorite)
            XCTAssertEqual(imported.templateVars, incoming.templateVars)
            XCTAssertEqual(imported.createdAt, incoming.createdAt)
            XCTAssertEqual(imported.updatedAt, incoming.updatedAt)
        }
        let prompt = try XCTUnwrap(store.prompts.first { $0.title == "sql generator" })
        let updated = await store.updatePrompt(id: prompt.id, input: CreatePromptInput(editing: prompt, title: "本地修改后的模板", promptText: prompt.promptText, tags: prompt.tags, kind: .template))
        XCTAssertTrue(updated)
        let deleted = await store.deletePrompt(id: try XCTUnwrap(store.prompts.first { $0.title == "提示词修改器" }).id)
        XCTAssertTrue(deleted)
        let reopened = DataStore(databaseURL: url, importURL: source)
        XCTAssertNil(reopened.errorMessage)
        XCTAssertEqual(reopened.prompts.count, 19)
        XCTAssertEqual(reopened.tags.count, 20)
        XCTAssertTrue(reopened.prompts.contains { $0.title == "本地修改后的模板" })
        XCTAssertFalse(reopened.prompts.contains { $0.title == "sql generator" || $0.title == "提示词修改器" })
    }

    func testLibraryFilterCombinesAnySelectedTagWithKindQueryAndFavorites() {
        let prompts = [
            Prompt(id: 1, title: "AI 笔记", promptText: "中文正文", tags: ["AI", "工具"], isFavorite: true),
            Prompt(id: 2, title: "SQL 模板", description: "数据库检索", promptText: "${需求}", tags: ["编程"], isTemplate: true),
            Prompt(id: 3, title: "无标签", promptText: "正文"),
        ]
        XCTAssertEqual(PromptLibraryFilter(selectedTags: ["AI", "编程"]).apply(to: prompts).map(\.id), [1, 2])
        XCTAssertEqual(PromptLibraryFilter(kind: .template, selectedTags: ["AI", "编程"], query: "数据库").apply(to: prompts).map(\.id), [2])
        XCTAssertEqual(PromptLibraryFilter(selectedTags: ["AI", "编程"], favoritesOnly: true).apply(to: prompts).map(\.id), [1])
        XCTAssertEqual(PromptLibraryFilter(query: "  sql \n").apply(to: prompts).map(\.id), [2])
        XCTAssertEqual(PromptLibraryFilter(query: "工具").apply(to: prompts).map(\.id), [1])
        XCTAssertEqual(PromptLibraryFilter().apply(to: prompts).count, 3)
        XCTAssertTrue(PromptLibraryFilter(selectedTags: ["不存在"]).apply(to: prompts).isEmpty)
    }

    @MainActor
    func testTagCanBeCreatedWithoutBackend() async {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/PromptKit.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = DataStore(databaseURL: url)
        let name = "离线标签-\(UUID().uuidString)"
        let saved = await store.createTag(CreateTagInput(name: name, color: "#38BDF8"))
        XCTAssertTrue(saved, store.errorMessage ?? "标签未保存")
        XCTAssertTrue(store.tags.contains { $0.name == name })
    }

    func testPromptDatesSurvivePersistenceRoundTrip() throws {
        let date = Date(timeIntervalSince1970: 1791849600)
        let original = Prompt(id: 1, title: "笔记", promptText: "直接使用", createdAt: date, updatedAt: date)
        let decoded = try JSONDecoder().decode(Prompt.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded.createdAt, date)
        XCTAssertEqual(decoded.updatedAt, date)
    }

    @MainActor
    func testSQLitePersistsTagsNotesAndTemplatesAfterReopening() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/PromptKit.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var store: DataStore? = DataStore(databaseURL: url)
        let tagSaved = await store!.createTag(CreateTagInput(name: " 工作 ", color: "#38BDF8"))
        XCTAssertTrue(tagSaved)
        let noteSaved = await store!.createPrompt(CreatePromptInput(title: "笔记", description: "描述", promptText: "原样复制 ${示例}", tags: ["工作"], usageNotes: "说明", isFavorite: true, isTemplate: false, templateVars: nil))
        XCTAssertTrue(noteSaved)
        let templateSaved = await store!.createPrompt(CreatePromptInput(title: "模板", description: nil, promptText: "为 ${产品} 写 {{语言}} 文案，再介绍 ${产品}", tags: [], usageNotes: nil, isFavorite: false, isTemplate: true, templateVars: ["过期变量"]))
        XCTAssertTrue(templateSaved)
        let original = try XCTUnwrap(store!.prompts.first { !$0.isTemplate })
        store = nil

        let reopened = DataStore(databaseURL: url)
        XCTAssertEqual(reopened.tags.map(\.name), ["工作"])
        XCTAssertEqual(reopened.prompts.count, 2)
        let note = try XCTUnwrap(reopened.prompts.first { !$0.isTemplate })
        XCTAssertEqual(note, original)
        XCTAssertTrue(note.variableNames.isEmpty)
        XCTAssertEqual(note.rendered(with: ["示例": "不要替换"]), note.promptText)
        let template = try XCTUnwrap(reopened.prompts.first { $0.isTemplate })
        XCTAssertEqual(template.variableNames, ["产品", "语言"])
        XCTAssertEqual(template.templateVars, ["产品", "语言"])
        XCTAssertEqual(template.rendered(with: ["产品": "相机", "语言": "中文"]), "为 相机 写 中文 文案，再介绍 相机")
    }

    @MainActor
    func testDuplicateAndUsedTagsAreRejectedWithoutChangingSavedData() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/PromptKit.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = DataStore(databaseURL: url)
        let created = await store.createTag(CreateTagInput(name: "工作", color: "#38BDF8"))
        XCTAssertTrue(created)
        let duplicate = await store.createTag(CreateTagInput(name: " 工作 ", color: "#EF4444"))
        XCTAssertFalse(duplicate)
        XCTAssertEqual(store.tags.count, 1)
        let saved = await store.createPrompt(CreatePromptInput(title: "笔记", description: nil, promptText: "正文", tags: ["工作"], usageNotes: nil, isFavorite: false, isTemplate: false, templateVars: nil))
        XCTAssertTrue(saved)
        let tagID = try XCTUnwrap(store.tags.first?.id)
        let deleted = await store.deleteTag(id: tagID)
        XCTAssertFalse(deleted)
        XCTAssertEqual(DataStore(databaseURL: url).tags.count, 1)
        XCTAssertNotNil(store.errorMessage)
    }

    @MainActor
    func testEditingPreservesMetadataAndFavoritePersists() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/PromptKit.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = DataStore(databaseURL: url)
        let saved = await store.createPrompt(CreatePromptInput(title: "笔记", description: "原描述", promptText: "原文", tags: [], usageNotes: "原说明", isFavorite: true, isTemplate: false, templateVars: nil))
        XCTAssertTrue(saved)
        let original = try XCTUnwrap(store.prompts.first)
        let input = CreatePromptInput(editing: original, title: "新标题", promptText: "新正文", tags: [], kind: .note)
        let updated = await store.updatePrompt(id: original.id, input: input)
        XCTAssertTrue(updated)
        let prompt = try XCTUnwrap(store.prompts.first)
        XCTAssertTrue(prompt.isFavorite)
        XCTAssertFalse(prompt.isTemplate)
        XCTAssertEqual(prompt.description, "原描述")
        XCTAssertEqual(prompt.usageNotes, "原说明")
        XCTAssertEqual(prompt.createdAt, original.createdAt)
        await store.toggleFavorite(prompt: prompt)
        XCTAssertFalse(try XCTUnwrap(DataStore(databaseURL: url).prompts.first).isFavorite)
    }

    func testRenderingDoesNotReplacePlaceholdersInsideEnteredValues() {
        let prompt = Prompt(id: 1, title: "模板", promptText: "${产品} {{语言}}", isTemplate: true)
        XCTAssertEqual(prompt.rendered(with: ["产品": "${语言}", "语言": "中文"]), "${语言} 中文")
        XCTAssertEqual(prompt.missingVariables(in: ["产品": " "]), ["产品", "语言"])
    }

    @MainActor
    func testSQLiteFileAndDeletedIDsAreNotReused() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/PromptKit.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = DataStore(databaseURL: url)
        let input = CreatePromptInput(title: "引号 ' 与中文🙂", description: nil, promptText: "保留原文\nSELECT * FROM prompts;", tags: [], usageNotes: nil, isFavorite: false, isTemplate: false, templateVars: nil)
        let created = await store.createPrompt(input)
        XCTAssertTrue(created)
        let id = try XCTUnwrap(store.prompts.first?.id)
        let deleted = await store.deletePrompt(id: id)
        XCTAssertTrue(deleted)
        XCTAssertTrue(DataStore(databaseURL: url).prompts.isEmpty)
        let recreated = await store.createPrompt(input)
        XCTAssertTrue(recreated)
        XCTAssertGreaterThan(try XCTUnwrap(store.prompts.first?.id), id)
        XCTAssertEqual(store.prompts.first?.title, input.title)
        XCTAssertEqual(store.prompts.first?.promptText, input.promptText)
        XCTAssertEqual(String(decoding: try Data(contentsOf: url).prefix(15), as: UTF8.self), "SQLite format 3")
    }

    @MainActor
    func testInvalidTemplateEditKeepsPreviouslySavedContent() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/PromptKit.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = DataStore(databaseURL: url)
        let input = CreatePromptInput(title: "模板", description: nil, promptText: "${主题}", tags: [], usageNotes: nil, isFavorite: false, isTemplate: true, templateVars: nil)
        let created = await store.createPrompt(input)
        XCTAssertTrue(created)
        let original = try XCTUnwrap(store.prompts.first)
        var invalid = input
        invalid.promptText = "没有填空项"
        let updated = await store.updatePrompt(id: original.id, input: invalid)
        XCTAssertFalse(updated)
        XCTAssertEqual(store.prompts.first, original)
        XCTAssertEqual(DataStore(databaseURL: url).prompts.first, original)
        let emptyTag = await store.createTag(CreateTagInput(name: " \n ", color: "#38BDF8"))
        XCTAssertFalse(emptyTag)
    }

    @MainActor
    func testUnreadableDatabaseIsNotReplacedOrReportedAsSaved() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("PromptKit.sqlite")
        let original = Data("unreadable existing database".utf8)
        try original.write(to: url)
        let store = DataStore(databaseURL: url)
        XCTAssertNotNil(store.errorMessage)
        let saved = await store.createTag(CreateTagInput(name: "不能误报保存成功", color: "#38BDF8"))
        XCTAssertFalse(saved)
        XCTAssertTrue(store.tags.isEmpty)
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testTagDatesRoundTripAndBackendMillisecondsDecode() throws {
        let date = Date(timeIntervalSince1970: 1791849600)
        let original = Tag(id: 1, name: "工作", color: "#38BDF8", createdAt: date, updatedAt: date)
        XCTAssertEqual(try JSONDecoder().decode(Tag.self, from: JSONEncoder().encode(original)), original)
        let payload = ##"{"id":1,"name":"工作","color":"#38BDF8","createdAt":1791849600000,"updatedAt":"2026-10-13T00:00:00Z"}"##
        let tag = try JSONDecoder().decode(Tag.self, from: Data(payload.utf8))
        XCTAssertEqual(tag.createdAt, date)
        XCTAssertEqual(tag.updatedAt, date)
    }

    @MainActor
    func testPastedTextContainingNULIsPreservedExactly() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)/PromptKit.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = DataStore(databaseURL: url)
        let text = "before\u{0000}after 中文🙂"
        let created = await store.createPrompt(CreatePromptInput(title: "笔记", description: text, promptText: text, tags: [], usageNotes: text, isFavorite: false, isTemplate: false, templateVars: nil))
        XCTAssertTrue(created)
        let prompt = try XCTUnwrap(DataStore(databaseURL: url).prompts.first)
        XCTAssertEqual(prompt.promptText, text)
        XCTAssertEqual(prompt.description, text)
        XCTAssertEqual(prompt.usageNotes, text)
    }

    func testPromptDecodesBackendPayload() throws {
        let payload = #"{"id":42,"title":"测试模板","promptText":"Hello {{name}}","tags":["work"],"isFavorite":true,"isTemplate":true,"templateVars":["name"],"createdAt":"2026-10-13T00:00:00.000Z","updatedAt":"2026-10-13T01:00:00.000Z"}"#
        let prompt = try JSONDecoder().decode(Prompt.self, from: Data(payload.utf8))

        XCTAssertEqual(prompt.id, 42)
        XCTAssertEqual(prompt.promptText, "Hello {{name}}")
        XCTAssertEqual(prompt.tags, ["work"])
        XCTAssertEqual(prompt.templateVars, ["name"])
        XCTAssertNil(prompt.description)
        XCTAssertTrue(prompt.isFavorite)
        XCTAssertEqual(prompt.updatedAt.timeIntervalSince(prompt.createdAt), 3600)
        XCTAssertEqual(prompt.createdAt.timeIntervalSince1970, 1791849600)
    }
}
