//
//  PuzzleViewDelegate.swift
//  PuzzleKit-Example
//
//  Created by Adahan on 13/01/25.
//


import UIKit

public protocol PuzzleViewDelegate: AnyObject {
    /// Called when the puzzle is fully completed (all tiles in correct positions).
    func puzzleViewDidComplete(_ puzzleView: PuzzleView)
    
    /// Called when a puzzle image (URL or local) is successfully set up.
    func puzzleViewDidLoadImage(_ puzzleView: PuzzleView, image: UIImage)
}

public extension PuzzleViewDelegate {
    func puzzleViewDidLoadImage(_ puzzleView: PuzzleView, image: UIImage) {
        // Optional to implement
    }
}
