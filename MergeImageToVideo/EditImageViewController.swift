//
//  EditImageViewController.swift
//  MergeImageToVideo
//
//  Created by dungvh on 3/28/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit

struct Vect2D {
    var x: Float
    var y: Float
    
    var xCG: CGFloat {
        return CGFloat(x)
    }
    var yCG: CGFloat {
        return CGFloat(y)
    }
}


class EditImageViewController: UIViewController {
    
    var currentImage:UIImage?
    var currentRotation:CGFloat = 0
    var currentScale:CGFloat = 1
    var currentTranslate = Vect2D(x: 0, y: 0)
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = currentImage
        setupGesture()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ExitEdit" {
            guard let controller = segue.destinationViewController as? ViewController else{
                return
            }
            
            controller.imageFinal = currentImage
        }
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK:--- Memory Management
    deinit{
        print("\(#function) \(self.dynamicType)")
    }
}

// MARK:--- Handle Gesture
extension EditImageViewController{
    func handlePinchGesture(pinchGesture:UIPinchGestureRecognizer) {
        if pinchGesture.state == .Changed
        {
            currentScale = pinchGesture.scale
            let transform = constructTransform()
            imageView.transform = transform
        }
        
    }
    
    func handlePanGesture(panGesture:UIPanGestureRecognizer) {
       
        switch panGesture.state {
        case .Began:
            fallthrough
        case .Changed:
            let translate = panGesture.translationInView(view)
            let velocity = panGesture.velocityInView(view)
            
            print("velocity : \(velocity)")
            
            currentTranslate = Vect2D(x: Float(translate.x), y: Float(translate.y))
            let transform = constructTransform()
            imageView.transform = transform
        default:
            break
        }
    }
    
    func handleRotateGesture(rotateGesture:UIRotationGestureRecognizer) {
        if rotateGesture.state == .Changed {
            currentRotation = rotateGesture.rotation
            let transform = constructTransform()
            imageView.transform = transform
        }
    }
    
}

// MARK:--- Setup Gesture
extension EditImageViewController:UIGestureRecognizerDelegate{
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

private extension EditImageViewController{
    
    func constructTransform() -> CGAffineTransform{
        let rotationTransform = CGAffineTransformMakeRotation(currentRotation)
        let scaleTransform = CGAffineTransformScale(rotationTransform, currentScale, currentScale)
        let translationTransform = CGAffineTransformTranslate(scaleTransform, currentTranslate.xCG, currentTranslate.yCG)
        return translationTransform
    }
    
    func setupGesture() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotateGesture(_:)))
        
        pinchGesture.delegate = self
        panGesture.delegate = self
        rotateGesture.delegate = self
        
        self.view.addGestureRecognizer(pinchGesture)
        self.view.addGestureRecognizer(panGesture)
        self.view.addGestureRecognizer(rotateGesture)
    }
}