import XCTest

final class PromptKitUITests: XCTestCase {
    func testTagFiltersRemainUsableWithLargestText() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["navigation.1"].staticTexts["个人收藏"].exists)
        XCTAssertGreaterThanOrEqual(app.buttons["navigation.1"].frame.height, 44)
        let longTag = app.buttons["library.tag.communication"]
        XCTAssertTrue(longTag.waitForExistence(timeout: 10))
        longTag.tap()
        XCTAssertTrue(longTag.isSelected)
        XCTAssertGreaterThanOrEqual(longTag.frame.height, 44)
        XCTAssertGreaterThanOrEqual(longTag.frame.width, 44)
        XCTAssertGreaterThanOrEqual(longTag.frame.minX, 0)
        XCTAssertLessThanOrEqual(longTag.frame.maxX, app.frame.width)
        capture(app, name: "Largest text wrapping tag selection")
        app.buttons["library.tags.clear"].tap()
        XCTAssertFalse(longTag.isSelected)
        collapseLibraryTags(in: app)
        XCTAssertEqual(app.buttons["library.tags.toggle"].value as? String, "已收起")
    }

    func testImportedLibrarySupportsAnyTagAndSeparateKindLists() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let search = app.textFields["搜索笔记、模板或标签"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("sql generator\n")
        XCTAssertTrue(app.buttons["library.tag.AI"].exists)
        app.buttons["library.tag.SEO"].tap()
        XCTAssertTrue(app.staticTexts["没有匹配的内容"].waitForExistence(timeout: 5))
        app.buttons["library.tag.AI"].tap()
        XCTAssertTrue(app.buttons["library.tag.SEO"].isSelected)
        XCTAssertTrue(app.buttons["library.tag.AI"].isSelected)
        XCTAssertEqual(app.staticTexts["library.results.count"].label, "1 条内容")
        collapseLibraryTags(in: app)
        XCTAssertTrue(app.staticTexts["sql generator"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["library.notes.count"].label, "0 条")
        XCTAssertEqual(app.staticTexts["library.templates.count"].label, "1 条")
        app.segmentedControls["prompt.filter"].buttons["笔记"].tap()
        XCTAssertTrue(app.staticTexts["没有匹配的内容"].exists)
        app.segmentedControls["prompt.filter"].buttons["模板"].tap()
        app.staticTexts["sql generator"].tap()
        XCTAssertTrue(app.textFields["variable.sql_requirement"].waitForExistence(timeout: 5))
        app.textFields["variable.sql_requirement"].tap()
        app.textFields["variable.sql_requirement"].typeText("统计用户数")
        app.textFields["variable.data_type"].tap()
        app.textFields["variable.data_type"].typeText("PostgreSQL")
        XCTAssertTrue(app.buttons["prompt.copy"].isEnabled)
        XCTAssertTrue(app.staticTexts["prompt.result"].label.contains("统计用户数"))
        XCTAssertTrue(app.staticTexts["prompt.result"].label.contains("PostgreSQL"))
        capture(app, name: "Imported SQL template variables")
        app.buttons["prompt.close"].tap()
        app.buttons["navigation.1"].tap()
        XCTAssertTrue(app.buttons["library.tags.toggle"].exists)
        XCTAssertTrue(app.segmentedControls["prompt.filter"].exists)
        app.buttons["navigation.0"].tap()
        XCTAssertEqual(search.value as? String, "sql generator")
        capture(app, name: "Imported library with tags and type filter")
    }

    private func collapseLibraryTags(in app: XCUIApplication) {
        let button = app.buttons["library.tags.toggle"]
        if button.exists, button.value as? String == "已展开" { button.tap() }
    }

    func testReadableLayoutsWithLargeTextAndLandscape() {
        continueAfterFailure = false
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        let title = "专业写作与需求分析工具箱-\(UUID().uuidString.prefix(6))"
        createPrompt(in: app, title: title, body: "请整理以下需求，保留关键事实，并用清晰的结构输出。\nExplain the requirements with a clear, professional structure.", template: false)
        capture(app, name: "01 Home")
        app.staticTexts[title].tap()
        XCTAssertTrue(app.buttons["prompt.copy"].waitForExistence(timeout: 5))
        capture(app, name: "02 Detail")
        app.buttons["prompt.edit"].tap()
        XCTAssertTrue(app.textFields["prompt.title"].waitForExistence(timeout: 5))
        capture(app, name: "03 Editor")
        app.buttons["取消"].tap()
        app.buttons["prompt.close"].tap()
        app.buttons["navigation.2"].tap()
        capture(app, name: "04 Settings")

        app.terminate()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let search = app.textFields["搜索笔记、模板或标签"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        collapseLibraryTags(in: app)
        search.tap()
        search.typeText(title)
        app.keyboards.buttons["Search"].tap()
        XCTAssertTrue(app.staticTexts[title].isHittable)
        capture(app, name: "05 Largest text")
        app.staticTexts[title].tap()
        XCTAssertTrue(app.buttons["prompt.close"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.buttons["prompt.copy"].isHittable)
        XCUIDevice.shared.orientation = .landscapeLeft
        app.swipeUp()
        XCTAssertTrue(app.buttons["prompt.copy"].exists)
        capture(app, name: "06 Landscape largest text")
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testMainTabsCanBeOpened() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let home = app.buttons["navigation.0"]
        let favorites = app.buttons["navigation.1"]
        let settings = app.buttons["navigation.2"]
        let add = app.buttons["prompt.add"]
        XCTAssertTrue(home.waitForExistence(timeout: 10))
        XCTAssertEqual(home.label, "home")
        XCTAssertEqual(favorites.label, "个人收藏")
        XCTAssertTrue(home.isSelected)
        let navigationButtons = [home, favorites, settings, add]
        for button in navigationButtons {
            XCTAssertTrue(button.isHittable)
            XCTAssertEqual(button.frame.midY, home.frame.midY, accuracy: 2)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        }
        for (left, right) in zip(navigationButtons, navigationButtons.dropFirst()) {
            XCTAssertLessThan(left.frame.midX, right.frame.midX)
        }
        let wordmark = app.staticTexts["app.wordmark"]
        XCTAssertTrue(wordmark.exists)
        XCTAssertEqual(wordmark.label, "PromptMaster")
        XCTAssertEqual(wordmark.frame.midX, app.frame.midX, accuracy: 3)
        capture(app, name: "PromptMaster Home and bottom navigation")
        favorites.tap()
        XCTAssertTrue(favorites.isSelected)
        XCTAssertTrue(app.textFields["搜索收藏的笔记或模板"].exists)
        add.tap()
        XCTAssertTrue(app.buttons.matching(identifier: "prompt.create.template").firstMatch.waitForExistence(timeout: 5))
        app.buttons.matching(identifier: "prompt.create.template").firstMatch.tap()
        XCTAssertTrue(app.textFields["prompt.title"].waitForExistence(timeout: 5))
        app.buttons["取消"].tap()
        settings.tap()
        XCTAssertTrue(settings.isSelected)
        home.tap()
        XCTAssertTrue(home.isSelected)
        let search = app.textFields["搜索笔记、模板或标签"]
        search.tap()
        search.typeText("NoMatchingPrompt-\(UUID().uuidString)")
        app.keyboards.buttons["Search"].tap()
        let query = search.value as? String
        favorites.tap()
        home.tap()
        XCTAssertEqual(search.value as? String, query)
        XCTAssertTrue(app.staticTexts["没有匹配的内容"].exists)
        capture(app, name: "PromptMaster empty search and final navigation order")
    }

    func testTagCreationPersistsAfterRelaunch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        app.buttons["navigation.2"].tap()
        app.buttons["标签管理"].tap()
        app.buttons["tag.add"].tap()
        let name = "测试标签-\(UUID().uuidString.prefix(8))"
        let field = app.textFields["tag.name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name)
        app.buttons["tag.save"].tap()
        XCTAssertTrue(tagNamed(name, in: app).waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.buttons["navigation.2"].tap()
        app.buttons["标签管理"].tap()
        XCTAssertTrue(tagNamed(name, in: app).waitForExistence(timeout: 5))
    }

    private func tagNamed(_ name: String, in app: XCUIApplication) -> XCUIElement {
        let tag = app.staticTexts[name]
        for _ in 0..<12 where !tag.isHittable {
            app.swipeUp()
        }
        return tag
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
        app.buttons["navigation.1"].tap()
        collapseLibraryTags(in: app)
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
        collapseLibraryTags(in: app)
        app.segmentedControls["prompt.filter"].buttons[template ? "模板" : "笔记"].tap()
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
