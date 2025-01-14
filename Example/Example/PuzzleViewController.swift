//
//  PuzzleViewController.swift
//  Example
//
//  Created by Adahan on 14/01/25.
//


import UIKit
import PuzzleKit

class PuzzleViewController: UIViewController {

   
    private let puzzleView: PuzzleView = {
        let view = PuzzleView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var startTime: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.addSubview(puzzleView)
        
 
        NSLayoutConstraint.activate([
            puzzleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            puzzleView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -0),
            puzzleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            puzzleView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70)
        ])
        
      
        puzzleView.puzzleDelegate = self
          puzzleView.gridSize = 3
        puzzleView.lockedTileAlpha = 1.0
        puzzleView.unlockedTileAlpha = 1.0
        puzzleView.canMoveLockedTiles = true
        puzzleView.tileBorderWidth = 2.0
        puzzleView.tileBorderColor = .white
        
        //  set local image
        //  let image = UIImage(named: "localImgage")!
        //  puzzleView.setPuzzleImage(image)
        
        let url = URL(string: "https://picsum.photos/1024")
      
        puzzleView.loadPuzzle(from: url, fallback: UIImage(named: "sadimage"))
    }
}

 
extension PuzzleViewController: PuzzleViewDelegate {
    func puzzleViewDidComplete(_ puzzleView: PuzzleView) {
        print("Puzzle completed!")
        
      
        let elapsedTime = Date().timeIntervalSince(startTime ?? Date())
        let formattedTime = String(format: "%.2f", elapsedTime)

        
        let alert = UIAlertController(
            title: "Congratulations!",
            message: "You completed the puzzle in \(formattedTime) seconds!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        UIView.animate(withDuration: 0.5) {
                for subview in puzzleView.subviews {
                    if let tile = subview as? PuzzleTile {
                        tile.layer.borderWidth = 0
                        tile.layer.borderColor = UIColor.clear.cgColor
                    }
                }
            }

   
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
           
            self.present(alert, animated: true)
        }
    }



    
    func puzzleViewDidLoadImage(_ puzzleView: PuzzleView, image: UIImage) {
        print("Puzzle image loaded: \(image.size)")
        startTime = Date()
    }

}
