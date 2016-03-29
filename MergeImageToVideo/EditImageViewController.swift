//
//  EditImageViewController.swift
//  MergeImageToVideo
//
//  Created by dungvh on 3/28/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit

let kMinScale:CGFloat = 0.5
let kMaxScale:CGFloat = 2

class EditImageViewController: UIViewController {
    
    var currentImage:UIImage?
    var lastScale:CGFloat = 1
    
    @IBOutlet weak var imageViewMask: UIImageView!
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
            
            let croppedImage = sender as? UIImage
            controller.imageFinal = croppedImage
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

// MARK:--- Helper Image
func takeImageFromView(view:UIView) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, UIScreen.mainScreen().scale)
    view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

func resizeImageWithNewSize(currentImage:UIImage?,newSize:CGSize) -> UIImage? {
    guard let currentImage = currentImage else{
        return nil
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    currentImage.drawInRect(CGRect(origin: CGPointZero, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
}

func cropImageWithTargetFrame(image:UIImage?,target:CGRect) -> UIImage? {
    guard let contextImage = CGImageCreateWithImageInRect(image?.CGImage, target) else {
        return nil
    }
    
    let imageFinal = UIImage(CGImage: contextImage,scale: 0,orientation: .Up)
    
    return imageFinal
}

func createImageWithMask(currentImage:UIImage?,maskImage:UIImage) -> UIImage? {
    
    let maskRef = maskImage.CGImage
    
    
    let mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                 CGImageGetHeight(maskRef),
                                 CGImageGetBitsPerComponent(maskRef),
                                 CGImageGetBitsPerPixel(maskRef),
                                 CGImageGetBytesPerRow(maskRef),
                                 CGImageGetDataProvider(maskRef),
                                 nil,
                                 true)
    
    guard let masked = CGImageCreateWithMask(currentImage?.CGImage, mask) else {
        return nil
    }
    
    let maskedImage = UIImage(CGImage: masked)
    
    return maskedImage
}

// MARK:--- Action
extension EditImageViewController{
    
    @IBAction func tapByDone(sender: AnyObject) {
        let scale = UIScreen.mainScreen().scale
        let maskImage = UIImage(named: "msk_01_crop")!
        let imageFromView = takeImageFromView(view)
        var targetFrame = CGRectZero
        targetFrame.origin = CGPointMake(40 * scale, 100 * scale)
        targetFrame.size = CGSizeMake(maskImage.size.width * scale, maskImage.size.height * scale)
        
        let imageCrop = cropImageWithTargetFrame(imageFromView, target: targetFrame)
        
        let imageFinal = createImageWithMask(imageCrop, maskImage: maskImage)
        
        self.performSegueWithIdentifier("ExitEdit", sender: imageFinal)
        
    }
}

// MARK:--- Handle Gesture
extension EditImageViewController{
    func handlePinchGesture(pinchGesture:UIPinchGestureRecognizer) {
        let state = pinchGesture.state
        let scale = pinchGesture.scale
        
        switch state {
        case .Began:
            lastScale = scale
            fallthrough
        case .Changed:
            let currentScale = imageView.layer.valueForKeyPath("transform.scale") as? Float ?? 1
            print("***** Current Scale : \(currentScale) *****" )
            var newScale = 1 - (lastScale - scale)
            newScale = min(newScale, kMaxScale / CGFloat(currentScale))
            newScale = max(newScale, kMinScale / CGFloat(currentScale))
            
            let transform = CGAffineTransformScale(imageView.transform, newScale, newScale)
            self.imageView.transform = transform
            lastScale = scale
            
        default:
            break
        }
        
    }
    
    func handlePanGesture(panGesture:UIPanGestureRecognizer) {
        
        let translation = panGesture.translationInView(view)
        var centerImagePoint = imageView.center
        centerImagePoint.x += translation.x
        centerImagePoint.y += translation.y
        
        imageView.center = centerImagePoint
        panGesture.setTranslation(CGPointZero, inView: view)
        
    }
    
    func handleRotateGesture(rotateGesture:UIRotationGestureRecognizer) {
        let angle = rotateGesture.rotation
        let transform = CGAffineTransformRotate(imageView.transform, angle)
        imageView.transform = transform
        rotateGesture.rotation = 0
    }
    
}


// MARK:--- Setup Gesture
extension EditImageViewController:UIGestureRecognizerDelegate{
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

private extension EditImageViewController{
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