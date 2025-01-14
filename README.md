# **🧩 PuzzleKit**

Welcome to **PuzzleKit** – a **powerful and customizable puzzle game framework** for iOS, built with **Swift** and supporting **Swift Package Manager**! Create amazing puzzle-based games effortlessly!

---

## **🚀 Features**

- **Customizable grid size:** Choose from `3x3`, `4x4`, or any `NxN` grid.
- **Tile customization:**
  - **Border width and color**
  - Alpha settings for locked/unlocked tiles.
- **Multiple image sources:**
  - Direct `UIImage` input.
  - Load from **URL** with **fallback images**.
- **Dynamic gestures:** Drag and swap tiles with haptic feedback.
- **Completion detection:** Notify when the puzzle is completed and optionally track the **completion time**.

---

## **📸 Demo**

Check out a snapshot of PuzzleKit in action:

```
🖼️ [Image Placeholder]
```

---

## **🛠️ Installation**

You can add PuzzleKit using **Swift Package Manager (SPM)**:

1. Open Xcode and go to `File > Add Packages...`.
2. Enter the URL of the PuzzleKit GitHub repository:
   ```
   https://github.com/chefAdo/PuzzleKit
   ```
3. Select the **PuzzleKit** library and add it to your project.

---

## **📦 Usage**

### **1. Import PuzzleKit**
```swift
import PuzzleKit
```

### **2. Create a PuzzleView**
```swift
let puzzleView = PuzzleView()
puzzleView.gridSize = 3  // 3x3 puzzle
puzzleView.tileBorderWidth = 2.0
puzzleView.tileBorderColor = .white
puzzleView.unlockedTileAlpha = 0.8
puzzleView.lockedTileAlpha = 1.0
```

### **3. Load Puzzle Image**
- **From URL:**
```swift
let url = URL(string: "https://picsum.photos/1024")
puzzleView.loadPuzzle(from: url, fallback: UIImage(named: "localFallback"))
```

- **Direct UIImage:**
```swift
let image = UIImage(named: "puzzleImage")!
puzzleView.setPuzzleImage(image)
```

### **4. Handle Puzzle Completion**
Conform to `PuzzleViewDelegate` to handle puzzle completion:

```swift
extension MyViewController: PuzzleViewDelegate {
    func puzzleViewDidComplete(_ puzzleView: PuzzleView) {
        print("Puzzle completed!")
    }

    func puzzleViewDidLoadImage(_ puzzleView: PuzzleView, image: UIImage) {
        print("Puzzle image loaded: \(image.size)")
    }
}
```

---

## **🧬 Example Code**
Here’s a full example:
```swift
import PuzzleKit

class PuzzleViewController: UIViewController {
    private let puzzleView: PuzzleView = {
        let view = PuzzleView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(puzzleView)
        
        NSLayoutConstraint.activate([
            puzzleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            puzzleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            puzzleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            puzzleView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
        
        puzzleView.puzzleDelegate = self
        puzzleView.gridSize = 4  // 4x4 puzzle
        puzzleView.loadPuzzle(from: URL(string: "https://picsum.photos/1024"))
    }
}

extension PuzzleViewController: PuzzleViewDelegate {
    func puzzleViewDidComplete(_ puzzleView: PuzzleView) {
        print("Congrats! Puzzle completed!")
    }
}
```

---

## **⚙️ Configuration Options**

| **Option**         | **Type**   | **Description**                                      | **Default** |
|--------------------|------------|----------------------------------------------------|-------------|
| `gridSize`         | `Int`      | Grid size for the puzzle (`3` for `3x3`, etc.).    | `3`         |
| `lockedTileAlpha`  | `CGFloat`  | Alpha for tiles in the correct position.           | `1.0`       |
| `unlockedTileAlpha`| `CGFloat`  | Alpha for tiles not in the correct position.       | `0.8`       |
| `tileBorderWidth`  | `CGFloat`  | Border width for tiles.                            | `0.0`       |
| `tileBorderColor`  | `UIColor`  | Border color for tiles.                            | `.clear`    |
| `canMoveLockedTiles` | `Bool`   | Whether locked tiles can be moved.                 | `false`     |

---

## **📃 License**

PuzzleKit is available under the **MIT license**. See [LICENSE](./LICENSE) for more information.

---

## **✨ Contributions Welcome!**

Contributions are welcome! If you’d like to:
- Report a bug 🐞
- Suggest a feature 🚀
- Submit a pull request 🛠️

Feel free to create an issue or PR on GitHub!

