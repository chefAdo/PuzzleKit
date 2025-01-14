import UIKit

@MainActor
public class PuzzleViewModel {
    public let gridSize: Int
    private(set) public var tiles: [PuzzleTile] = []
    
    public init(gridSize: Int) {
        self.gridSize = gridSize
    }
    
    public func setTiles(_ newTiles: [PuzzleTile]) {
        self.tiles = newTiles
    }
    
    /// Swap tiles at indices if neither is locked (or if user chooses to allow locked tiles to move—but see below).
    public func swapTiles(at firstIndex: Int, with secondIndex: Int, allowLocked: Bool) {
        // If not allowing locked tiles to move, check if either tile is locked
        if !allowLocked {
            if tiles[firstIndex].isLocked || tiles[secondIndex].isLocked {
                return
            }
        }
        
        let temp = tiles[firstIndex]
        tiles[firstIndex] = tiles[secondIndex]
        tiles[secondIndex] = temp
        
        // Update their currentIndex
        let oldIndex = tiles[firstIndex].currentIndex
        tiles[firstIndex].currentIndex = tiles[secondIndex].currentIndex
        tiles[secondIndex].currentIndex = oldIndex
        
        // Update alpha
        tiles[firstIndex].updateAlpha()
        tiles[secondIndex].updateAlpha()
    }
    
    /// Check if puzzle is fully solved
    public func isPuzzleComplete() -> Bool {
        return tiles.allSatisfy { $0.isLocked }
    }
    
    /// Shuffle all tiles in a way that none starts in correct position.
    /// For small grids, a simple repeat-until-no-lock is sufficient.
    public func shuffleTilesEnsuringNoInitialLock() {
        guard !tiles.isEmpty else { return }
        
        repeat {
            tiles.shuffle()
            for i in 0..<tiles.count {
                tiles[i].currentIndex = i
                tiles[i].updateAlpha()
            }
        } while tiles.contains(where: { $0.isLocked })
    }
    
    /// Shuffle unlocked tiles only (if you want that behavior).
    public func shuffleUnlockedTiles() {
        var unlocked = tiles.filter { !$0.isLocked }
        unlocked.shuffle()
        
        var idx = 0
        for i in 0..<tiles.count {
            if !tiles[i].isLocked {
                tiles[i] = unlocked[idx]
                tiles[i].currentIndex = i
                tiles[i].updateAlpha()
                idx += 1
            }
        }
    }
}
