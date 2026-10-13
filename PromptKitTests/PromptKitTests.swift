import Foundation
import XCTest
@testable import PromptKit

final class PromptKitTests: XCTestCase {
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
