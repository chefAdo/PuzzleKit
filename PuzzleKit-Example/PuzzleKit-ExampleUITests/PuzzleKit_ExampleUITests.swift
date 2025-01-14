/*import XCTest

final class PuzzleUITests: XCTestCase {
    
    func testPuzzleCompletionAlert() {
        let app = XCUIApplication()
        app.launch()
        
        // Interact with a tile
        let tile = app.otherElements["tile_0"]
        XCTAssertTrue(tile.exists, "Tile 0 should exist in the UI.")
        
        tile.swipeRight()  // Simulate movement

        // Wait for the alert after completion
        let exists = app.alerts["Congratulations!"].waitForExistence(timeout: 10)
        XCTAssertTrue(exists, "The congratulations alert should be displayed when the puzzle is completed.")
    }
}
*/
