import XCTest

final class PromptKitUITests: XCTestCase {
    func testMainTabsCanBeOpened() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let tabs = app.tabBars
        XCTAssertTrue(tabs.buttons["提示词"].waitForExistence(timeout: 10))
        tabs.buttons["快捷贴贴"].tap()
        XCTAssertTrue(tabs.buttons["快捷贴贴"].isSelected)
        tabs.buttons["设置"].tap()
        XCTAssertTrue(tabs.buttons["设置"].isSelected)
        tabs.buttons["提示词"].tap()
        XCTAssertTrue(tabs.buttons["提示词"].isSelected)
    }

    func testTagCreationPersistsAfterRelaunch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["设置"].tap()
        app.buttons["标签管理"].tap()
        app.buttons["tag.add"].tap()
        let name = "测试标签-\(UUID().uuidString.prefix(8))"
        let field = app.textFields["tag.name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name)
        app.buttons["tag.save"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.tabBars.buttons["设置"].tap()
        app.buttons["标签管理"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    func testNoteCanBeCopiedWithoutVariablesAndEditedInPlace() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let title = "Note-\(UUID().uuidString.prefix(8))"
        createPrompt(in: app, title: title, body: "Keep literal ${name} unchanged", template: false)
        app.staticTexts[title].tap()
        XCTAssertTrue(app.buttons["prompt.copy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["prompt.copy"].isEnabled)
        XCTAssertFalse(app.textFields["variable.name"].exists)
        app.buttons["prompt.copy"].tap()
        XCTAssertTrue(app.alerts["已复制"].waitForExistence(timeout: 5))
        app.alerts["已复制"].buttons["好的"].tap()
        app.buttons["prompt.favorite"].tap()
        app.buttons["prompt.edit"].tap()
        let field = app.textFields["prompt.title"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        field.typeText(" Updated")
        app.buttons["prompt.save"].tap()
        XCTAssertTrue(app.staticTexts[title + " Updated"].waitForExistence(timeout: 5))
        app.buttons["prompt.close"].tap()
        app.terminate()
        app.launch()
        app.tabBars.buttons["快捷贴贴"].tap()
        XCTAssertTrue(app.staticTexts[title + " Updated"].waitForExistence(timeout: 5))
        app.staticTexts[title + " Updated"].tap()
        XCTAssertTrue(app.buttons["prompt.copy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["prompt.copy"].isEnabled)
    }

    func testTemplateSupportsBothVariableSyntaxesAndLivePreview() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let title = "Template-\(UUID().uuidString.prefix(8))"
        createPrompt(in: app, title: title, body: "Write about ${product} in {{language}}", template: true)
        app.staticTexts[title].tap()
        let product = app.textFields["variable.product"]
        XCTAssertTrue(product.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["prompt.copy"].isEnabled)
        product.tap()
        product.typeText("camera")
        let language = app.textFields["variable.language"]
        language.tap()
        language.typeText("English")
        XCTAssertTrue(app.staticTexts["Write about camera in English"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["prompt.copy"].isEnabled)
        product.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        product.typeText("s")
        XCTAssertTrue(app.staticTexts["Write about cameras in English"].waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Template live preview"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func createPrompt(in app: XCUIApplication, title: String, body: String, template: Bool) {
        app.buttons["prompt.add"].tap()
        // iOS 27 exposes the confirmation action as both a wrapper and a child button.
        app.buttons.matching(identifier: template ? "prompt.create.template" : "prompt.create.note").firstMatch.tap()
        let field = app.textFields["prompt.title"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(title)
        let editor = app.textViews["prompt.body"]
        editor.tap()
        editor.typeText(body)
        app.buttons["prompt.save"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
    }

    func testCreatingTagInsideEditorKeepsDraftAndSavesAssociation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        app.buttons["prompt.add"].tap()
        app.buttons.matching(identifier: "prompt.create.note").firstMatch.tap()
        let title = "Tagged-\(UUID().uuidString.prefix(8))"
        let tag = "Tag-\(UUID().uuidString.prefix(8))"
        let titleField = app.textFields["prompt.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText(title)
        let editor = app.textViews["prompt.body"]
        editor.tap()
        editor.typeText("Keep this draft")
        app.swipeUp()
        app.buttons["prompt.tags"].tap()
        app.buttons["tag.add"].tap()
        let tagField = app.textFields["tag.name"]
        tagField.tap()
        tagField.typeText(tag)
        app.buttons["tag.save"].tap()
        XCTAssertTrue(app.staticTexts[tag].waitForExistence(timeout: 5))
        app.buttons["完成"].tap()
        app.buttons["prompt.save"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.staticTexts[title].tap()
        XCTAssertTrue(app.staticTexts[tag].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Keep this draft"].exists)
    }
}
