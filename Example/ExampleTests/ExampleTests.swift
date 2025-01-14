import XCTest
@testable import PuzzleKit

final class PuzzleViewModelTests: XCTestCase {
    
    @MainActor func testShuffleEnsuresNoTilesInitiallyLocked() {
        let gridSize = 3
        let viewModel = PuzzleViewModel(gridSize: gridSize)
        var tiles: [PuzzleTile] = []
        
        for i in 0..<(gridSize * gridSize) {
            let image = UIImage()  // Dummy image for tests
            let tile = PuzzleTile(
                image: image,
                correctIndex: i,
                currentIndex: i,
                lockedAlpha: 1.0,
                unlockedAlpha: 0.8
            )
            tiles.append(tile)
        }
        
        viewModel.setTiles(tiles)
        viewModel.shuffleTilesEnsuringNoInitialLock()
        
        XCTAssertFalse(viewModel.isPuzzleComplete(), "The puzzle should not be complete after shuffling.")
        XCTAssertTrue(viewModel.tiles.contains(where: { !$0.isLocked }), "There should be at least one tile that is not in the correct position after shuffling.")
    }
    
    @MainActor func testIsPuzzleComplete() {
        let gridSize = 3
        let viewModel = PuzzleViewModel(gridSize: gridSize)
        var tiles: [PuzzleTile] = []
        
        for i in 0..<(gridSize * gridSize) {
            let image = UIImage()
            let tile = PuzzleTile(
                image: image,
                correctIndex: i,
                currentIndex: i,
                lockedAlpha: 1.0,
                unlockedAlpha: 0.8
            )
            tiles.append(tile)
        }
        
        viewModel.setTiles(tiles)
        
        XCTAssertTrue(viewModel.isPuzzleComplete(), "The puzzle should be complete if all tiles are in the correct position.")
    }
    
    @MainActor func testSwapTilesDoesNotMoveLockedTiles() {
        let gridSize = 3
        let viewModel = PuzzleViewModel(gridSize: gridSize)
        var tiles: [PuzzleTile] = []
        
        for i in 0..<(gridSize * gridSize) {
            let image = UIImage()
            let tile = PuzzleTile(
                image: image,
                correctIndex: i,
                currentIndex: i,
                lockedAlpha: 1.0,
                unlockedAlpha: 0.8
            )
            tiles.append(tile)
        }
        
        viewModel.setTiles(tiles)
        viewModel.swapTiles(at: 0, with: 1, allowLocked: false)
        
        XCTAssertEqual(viewModel.tiles[0].currentIndex, 0, "Locked tiles should not move if movement is disabled.")
    }
}
