import UIKit

@MainActor
public class PuzzleView: UIView {
    public weak var puzzleDelegate: PuzzleViewDelegate?

    /// Grid size (3 → 3x3, 4 → 4x4, etc.)
    public var gridSize: Int = 3

    /// Alpha for tiles in the correct position
    public var lockedTileAlpha: CGFloat = 1.0

    /// Alpha for tiles not in the correct position
    public var unlockedTileAlpha: CGFloat = 0.8

    /// Whether locked tiles can still be moved
    public var canMoveLockedTiles: Bool = false

    /// Border width for tiles (default 0 - no border)
    public var tileBorderWidth: CGFloat = 0.0

    /// Border color for tiles (default clear)
    public var tileBorderColor: UIColor = .clear

    /// The puzzle logic
    public private(set) var viewModel: PuzzleViewModel!

    private var puzzleImage: UIImage?
    private var hasLaidOutPuzzle = false
    private var isPuzzleCompleted: Bool = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Public API

    /// Load puzzle from a direct UIImage
    public func setPuzzleImage(_ image: UIImage) {
        puzzleImage = image
        isPuzzleCompleted = false
        hasLaidOutPuzzle = false
        subviews.forEach { $0.removeFromSuperview() }
        setNeedsLayout()
    }

    public func shufflePuzzle() {
 
        viewModel?.shuffleTilesEnsuringNoInitialLock()
        layoutPuzzleTiles()
        isPuzzleCompleted = false

    }

    public func shuffleUnlockedPuzzle() {
        viewModel?.shuffleUnlockedTiles()
        layoutPuzzleTiles()
    }

    // MARK: - Public API

    /// Load puzzle from a URL; if it fails, fallback image is used (if non-nil)
    public func loadPuzzle(from url: URL?, fallback: UIImage? = nil) {
        guard let url = url else {
            // No URL, use fallback if available
            if let fallbackImage = fallback {
                setPuzzleImage(fallbackImage)
            }
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil, let downloadedImage = UIImage(data: data) else {
                // If download failed, use fallback image if available
                DispatchQueue.main.async {
                    if let fallbackImage = fallback {
                        self?.setPuzzleImage(fallbackImage)
                    }
                }
                return
            }

            // Set the downloaded image as the puzzle image
            DispatchQueue.main.async {
                self.setPuzzleImage(downloadedImage)
            }
        }.resume()
    }

    
    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        guard let image = puzzleImage, bounds.size != .zero else { return }

        // Setup tiles from the cropped and scaled image
        if !hasLaidOutPuzzle {
            setupPuzzleTiles(with: image)
            hasLaidOutPuzzle = true
            puzzleDelegate?.puzzleViewDidLoadImage(self, image: image)
        }

        layoutPuzzleTiles()
    }

    // MARK: - Puzzle Tiles Setup

    private func setupPuzzleTiles(with image: UIImage) {
        viewModel = PuzzleViewModel(gridSize: gridSize)

        let aspectFilledImage = image.aspectFillCropped(to: bounds.size)

        guard let cgImage = aspectFilledImage.cgImage else { return }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        let tileWidth = imageWidth / CGFloat(gridSize)
        let tileHeight = imageHeight / CGFloat(gridSize)

        var tiles: [PuzzleTile] = []
        var correctIndex = 0

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let x = CGFloat(col) * tileWidth
                let y = CGFloat(row) * tileHeight
                let cropRect = CGRect(x: x, y: y, width: tileWidth, height: tileHeight)

                if let croppedCGImage = cgImage.cropping(to: cropRect) {
                    let piece = UIImage(cgImage: croppedCGImage, scale: aspectFilledImage.scale, orientation: aspectFilledImage.imageOrientation)

                    let tile = PuzzleTile(
                        image: piece,
                        correctIndex: correctIndex,
                        currentIndex: correctIndex,
                        lockedAlpha: lockedTileAlpha,
                        unlockedAlpha: unlockedTileAlpha
                    )

                    // Apply border properties
                    tile.layer.borderWidth = tileBorderWidth
                    tile.layer.borderColor = tileBorderColor.cgColor
                    // Assign accessibility identifier
                    tile.accessibilityIdentifier = "tile_\(correctIndex)"
                    
                    let panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
                    tile.addGestureRecognizer(panGR)

                    tiles.append(tile)
                }
                correctIndex += 1
            }
        }

        viewModel.setTiles(tiles)
        viewModel.shuffleTilesEnsuringNoInitialLock()

        for tile in viewModel.tiles {
            addSubview(tile)
        }
    }

    private func layoutPuzzleTiles() {
        guard let vm = viewModel else { return }

        let tileWidth = bounds.width / CGFloat(gridSize)
        let tileHeight = bounds.height / CGFloat(gridSize)

        for tile in vm.tiles {
            let idx = tile.currentIndex
            let row = idx / gridSize
            let col = idx % gridSize

            UIView.animate(withDuration: 0.2) {
                tile.frame = CGRect(
                    x: CGFloat(col) * tileWidth,
                    y: CGFloat(row) * tileHeight,
                    width: tileWidth,
                    height: tileHeight
                )
            }
        }
    }

    // MARK: - Gesture Handling

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        guard let movedTile = gr.view as? PuzzleTile else { return }

        // Prevent movement if the puzzle is completed
        if isPuzzleCompleted { return }

        if movedTile.isLocked && !canMoveLockedTiles { return }

        switch gr.state {
        case .began, .changed:
            let translation = gr.translation(in: self)
            movedTile.center = CGPoint(
                x: movedTile.center.x + translation.x,
                y: movedTile.center.y + translation.y
            )
            gr.setTranslation(.zero, in: self)

        case .ended, .cancelled:
            if let targetTile = findBestOverlapCandidate(for: movedTile), targetTile != movedTile {
                swapTiles(movedTile, with: targetTile)
            }
            layoutPuzzleTiles()

            if viewModel.isPuzzleComplete() {
                isPuzzleCompleted = true  // Disable tile movements
                puzzleDelegate?.puzzleViewDidComplete(self)
            }

        default:
            break
        }
    }


    private func findBestOverlapCandidate(for movedTile: PuzzleTile) -> PuzzleTile? {
        guard let vm = viewModel else { return nil }

        let candidates = vm.tiles.filter { $0 != movedTile }

        var bestOverlap: CGFloat = 0
        var bestTile: PuzzleTile?

        let movedFrame = movedTile.frame
        let tileArea = movedFrame.width * movedFrame.height

        for tile in candidates {
            if tile.isLocked && !canMoveLockedTiles { continue }

            let overlapRect = movedFrame.intersection(tile.frame)
            let overlapArea = overlapRect.isNull ? 0 : overlapRect.width * overlapRect.height

            if overlapArea > bestOverlap {
                bestOverlap = overlapArea
                bestTile = tile
            }
        }

        if bestOverlap < tileArea * 0.2 {
            return nil
        }
        return bestTile
    }

    private func swapTiles(_ t1: PuzzleTile, with t2: PuzzleTile) {
        guard
            let i1 = viewModel.tiles.firstIndex(of: t1),
            let i2 = viewModel.tiles.firstIndex(of: t2)
        else { return }

        viewModel.swapTiles(at: i1, with: i2, allowLocked: canMoveLockedTiles)

        if t1.isLocked || t2.isLocked {
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.impactOccurred()
        }
    }
}

// MARK: - Extension for Aspect-Fill Cropping
extension UIImage {
    /// Scales the image to fill the target size while preserving aspect ratio, cropping excess.
    func aspectFillCropped(to targetSize: CGSize) -> UIImage {
        guard targetSize.width > 0, targetSize.height > 0 else { return self }

        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scale = max(widthRatio, heightRatio)

        let scaledWidth = size.width * scale
        let scaledHeight = size.height * scale

        let xOffset = (targetSize.width - scaledWidth) / 2
        let yOffset = (targetSize.height - scaledHeight) / 2

        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        draw(in: CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight))

        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return croppedImage ?? self
    }
}
