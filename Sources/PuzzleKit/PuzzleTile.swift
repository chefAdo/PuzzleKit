import UIKit

@MainActor
public class PuzzleTile: UIImageView {
    public let correctIndex: Int
    public var currentIndex: Int
    
    private let lockedAlpha: CGFloat
    private let unlockedAlpha: CGFloat
    
    /// A tile is "locked" if it's in the correct position.
    public var isLocked: Bool {
        return correctIndex == currentIndex
    }
    
    public init(
        image: UIImage,
        correctIndex: Int,
        currentIndex: Int,
        lockedAlpha: CGFloat,
        unlockedAlpha: CGFloat
    ) {
        self.correctIndex = correctIndex
        self.currentIndex = currentIndex
        self.lockedAlpha = lockedAlpha
        self.unlockedAlpha = unlockedAlpha
        super.init(frame: .zero)
        
        self.image = image
        self.isUserInteractionEnabled = true
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        
        updateAlpha()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Update alpha based on whether the tile is locked.
    public func updateAlpha() {
        alpha = isLocked ? lockedAlpha : unlockedAlpha
    }
}
