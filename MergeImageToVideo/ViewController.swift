//
//  ViewController.swift
//  MergeImageToVideo
//
//  Created by dungvh on 3/25/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import UIKit

class ViewController: CommonVideoViewController {

    @IBOutlet weak var imageView: UIImageView!
    var imageFinal:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startOpenCameraFromViewController()
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



