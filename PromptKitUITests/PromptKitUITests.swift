import XCTest

final class PromptKitUITests: XCTestCase {
    func testMainTabsCanBeOpened() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let tabs = app.tabBars
        XCTAssertTrue(tabs.buttons["模板"].waitForExistence(timeout: 10))
        tabs.buttons["快捷贴贴"].tap()
        XCTAssertTrue(tabs.buttons["快捷贴贴"].isSelected)
        tabs.buttons["设置"].tap()
        XCTAssertTrue(tabs.buttons["设置"].isSelected)
        tabs.buttons["模板"].tap()
        XCTAssertTrue(tabs.buttons["模板"].isSelected)
    }
}
