import UIKit

@MainActor
public class PuzzleView: UIView {
    public weak var puzzleDelegate: PuzzleViewDelegate?

    // MARK: - Configuration Properties

    /// Grid size (3 → 3x3, 4 → 4x4, etc.)
    public var gridSize: Int = 3

    /// Alpha for tiles in the correct position
    public var lockedTileAlpha: CGFloat = 1.0

    /// Whether haptic feedback is enabled (default: true)
    public var isHapticFeedbackEnabled: Bool = true

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

    // MARK: - UI Elements for Rotation Notice

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "🔄" // Emoji for rotation
        label.font = UIFont.systemFont(ofSize: 60)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Please rotate your phone to portrait mode"
        label.font = UIFont.boldSystemFont(ofSize: 19)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceRotation), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceRotation), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    deinit {
        // Remove the observer to avoid memory leaks
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
 

    // MARK: - Setup UI for Rotation Notice
    @objc private func handleDeviceRotation() {
        if UIDevice.current.orientation.isLandscape {
            showRotationMessage()  // Show rotation message
            fadeOutPuzzleTiles()   // Hide puzzle tiles
        } else if UIDevice.current.orientation.isPortrait {
            hideRotationMessage()  // Hide the message
            fadeInPuzzleTiles()    // Show puzzle tiles
        }
    }
    private func fadeOutPuzzleTiles() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.subviews.forEach { subview in
                if subview is PuzzleTile {
                    subview.alpha = 0.0  // Fade out all tiles
                }
            }
        }
    }

    private func fadeInPuzzleTiles() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.subviews.forEach { subview in
                if subview is PuzzleTile {
                    subview.alpha = 1.0  // Fade in all tiles
                }
            }
        }
    }

    
    public func showRotationMessage() {
        guard let superview = self.superview ?? UIApplication.shared.windows.first else { return }

        // Add labels if not already added
        if emojiLabel.superview == nil {
            superview.addSubview(emojiLabel)
            superview.addSubview(messageLabel)

            NSLayoutConstraint.activate([
                emojiLabel.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                emojiLabel.centerYAnchor.constraint(equalTo: superview.centerYAnchor, constant: -40),
                messageLabel.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                messageLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 16),
                messageLabel.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 16),
                messageLabel.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -16)
            ])
        }

        // Force layout pass
        superview.layoutIfNeeded()

        emojiLabel.isHidden = false
        messageLabel.isHidden = false
        emojiLabel.alpha = 0.0
        messageLabel.alpha = 0.0

        UIView.animate(withDuration: 0.5) {
            self.emojiLabel.alpha = 1.0
            self.messageLabel.alpha = 1.0
        }
    }

    public func hideRotationMessage() {
        UIView.animate(withDuration: 0.5, animations: {
            self.emojiLabel.alpha = 0.0
            self.messageLabel.alpha = 0.0
        }) { _ in
            self.emojiLabel.removeFromSuperview()
            self.messageLabel.removeFromSuperview()
        }
    }




    // MARK: - Public API

    public func setPuzzleImage(_ image: UIImage) {
        puzzleImage = image
        isPuzzleCompleted = false
        hasLaidOutPuzzle = false
        subviews.forEach { $0.removeFromSuperview() }
        addSubview(emojiLabel)
        addSubview(messageLabel)
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

    public func loadPuzzle(from url: URL?, fallback: UIImage? = nil) {
        guard let url = url else {
            if let fallbackImage = fallback {
                setPuzzleImage(fallbackImage)
            }
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil, let downloadedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    if let fallbackImage = fallback {
                        self?.setPuzzleImage(fallbackImage)
                    }
                }
                return
            }

            DispatchQueue.main.async {
                self.setPuzzleImage(downloadedImage)
            }
        }.resume()
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        guard let image = puzzleImage, bounds.size != .zero else { return }

        if !hasLaidOutPuzzle {
            setupPuzzleTiles(with: image)
            hasLaidOutPuzzle = true
            puzzleDelegate?.puzzleViewDidLoadImage(self, image: image)
        }

        layoutPuzzleTiles()
        // Ensure labels are re-centered
         if UIDevice.current.orientation.isLandscape {
             showRotationMessage() // Ensures they are centered in landscape mode
         } else if UIDevice.current.orientation.isPortrait {
             hideRotationMessage()
         }
    }

    private func setupPuzzleTiles(with image: UIImage) {
        viewModel = PuzzleViewModel(gridSize: gridSize)

        let aspectFilledImage = image.aspectFillCropped(to: bounds.size)
        guard let cgImage = aspectFilledImage.cgImage else { return }

        let tileWidth = CGFloat(cgImage.width) / CGFloat(gridSize)
        let tileHeight = CGFloat(cgImage.height) / CGFloat(gridSize)

        var tiles: [PuzzleTile] = []
        var correctIndex = 0

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let x = CGFloat(col) * tileWidth
                let y = CGFloat(row) * tileHeight
                let cropRect = CGRect(x: x, y: y, width: tileWidth, height: tileHeight)

                if let croppedCGImage = cgImage.cropping(to: cropRect) {
                    let piece = UIImage(cgImage: croppedCGImage)

                    let tile = PuzzleTile(
                        image: piece,
                        correctIndex: correctIndex,
                        currentIndex: correctIndex,
                        lockedAlpha: lockedTileAlpha,
                        unlockedAlpha: unlockedTileAlpha
                    )

                    tile.layer.borderWidth = tileBorderWidth
                    tile.layer.borderColor = tileBorderColor.cgColor
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
        guard let movedTile = gr.view as? PuzzleTile, !isPuzzleCompleted else { return }
        if movedTile.isLocked && !canMoveLockedTiles { return }

        switch gr.state {
        case .began:
            if isHapticFeedbackEnabled {
                let selectionGenerator = UISelectionFeedbackGenerator()
                selectionGenerator.selectionChanged()
            }

        case .changed:
            let translation = gr.translation(in: self)
            movedTile.center = CGPoint(x: movedTile.center.x + translation.x, y: movedTile.center.y + translation.y)
            gr.setTranslation(.zero, in: self)

        case .ended, .cancelled:
            if let targetTile = findBestOverlapCandidate(for: movedTile), targetTile != movedTile {
                swapTiles(movedTile, with: targetTile)
                if isHapticFeedbackEnabled && !movedTile.isLocked {
                    let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
                    impactGenerator.impactOccurred()
                }
            }
            layoutPuzzleTiles()
            if viewModel.isPuzzleComplete() {
                isPuzzleCompleted = true
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
