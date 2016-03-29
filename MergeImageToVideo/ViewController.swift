//
//  ViewController.swift
//  MergeImageToVideo
//
//  Created by dungvh on 3/25/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import AVKit

final class ViewController: CommonVideoViewController {

    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    var imageFinal:UIImage?
    var imageReszie:UIImage!
    var videoExporter:VideoMergeImage!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        startPhotoBrowserFromViewController()
        
        guard let path = NSBundle.mainBundle().pathForResource("sampleVideo", ofType: "mp4") else{
            return
        }
        
        let url = NSURL(fileURLWithPath: path)
        
        videoExporter = VideoMergeImage(url: url, delegate: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier{
        case "OpenCamera":
            guard let controller = segue.destinationViewController as? CameraViewController else{
                return
            }
            
            controller.delegate = self
        case "EditImage":
            guard let controller = segue.destinationViewController as? EditImageViewController else{
                return
            }
            let image = sender as? UIImage
            controller.currentImage = image
        default:
            break
        }
    }
    
    
    @IBAction func UnwinEditImage(segue:UIStoryboardSegue){
       imageView.image = imageFinal
        view.bringSubviewToFront(self.indicator)
    }
    

    override func openCamera() {
        self.performSegueWithIdentifier("OpenCamera", sender: self)
    }
    
    override func handleImageChooseImage(image: UIImage) {
        self.performSegueWithIdentifier("EditImage", sender: image)
    }
}



extension ViewController:CameraViewControllerDelegate{
    func takePhoto(image: UIImage, controller: CameraViewController?) {
        self.dismissViewControllerAnimated(true, completion: nil)
        handleImageChooseImage(image)
    }
    
}

extension ViewController{
    
    @IBAction func tapByGetImage(sender: AnyObject) {
        let alert = UIAlertController(title: "What do u want???", message: "Get Image From :", preferredStyle: .ActionSheet)
        
        let actionOpenPhoto = UIAlertAction(title: "Photo Libray", style: .Default) { [weak self](_) in
            self?.startPhotoBrowserFromViewController()
        }
        
        let actionOpenCamera = UIAlertAction(title: "Camera", style: .Default) { [weak self](_) in
            self?.startOpenCameraFromViewController()
        }
        alert.addAction(actionOpenPhoto)
        alert.addAction(actionOpenCamera)
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func tapByApplyToVideo(sender: AnyObject) {
        guard let _ = imageFinal else{
            return
        }
        
        let imageFromImageView = takeImageFromView(self.imageView)
        let imageResize = resizeImageWithNewSize(imageFromImageView, newSize: CGSizeMake(160, 160))!
        self.imageReszie = imageResize
        
        indicator.startAnimating()
        
        Queue.Background.execute { [weak self] in
            do{
                try self?.videoExporter.videoOuput()
            }catch let error as NSError {
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    self?.indicator.stopAnimating()
                    showError(error.localizedDescription, controller: self)
                })
                
            }
        }
        
        
    }
    
}

extension ViewController:ApplyEffectToVideo{
    func applyVideoEffectsToComposition(composition: AVMutableVideoComposition, size: CGSize) {
        
        let overLay = CALayer()
        overLay.contents = imageReszie.CGImage
        overLay.frame = CGRectMake(size.width/2-64, size.height/2 + 100, 160, 160)
        overLay.masksToBounds = true
        overLay.cornerRadius = 80
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 2
        animation.repeatCount = 5
        animation.autoreverses = true
        
        animation.fromValue = 0
        animation.toValue = 2 * M_PI
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        overLay.addAnimation(animation, forKey: "rotation")
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRectMake(0, 0, size.width, size.height)
        videoLayer.frame = CGRectMake(0, 0, size.width, size.height)
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overLay)
        
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer,
                                                                        inLayer: parentLayer)
        
        
    }
    
    func exportVideoToUrl() -> NSURL? {
        let manager = NSFileManager.defaultManager()
        let urlPath = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let fileUrl =  urlPath?.URLByAppendingPathComponent("FinalVideo-test\(arc4random() % 1000).mov")
        return fileUrl
    }
    
    func exportDidFinish(session: AVAssetExportSession?) {
        print(session?.error?.localizedDescription)
        self.indicator.stopAnimating()
        if session?.status == AVAssetExportSessionStatus.Completed {
            guard let outputURL = session?.outputURL else {
                return
            }
            
            print("save as : \(outputURL)")
            
            let playerController = AVPlayerViewController()
            playerController.player = AVPlayer(URL: outputURL)
            
            
            self.presentViewController(playerController, animated: true, completion: nil)
            
        }
        
        
    }
}



