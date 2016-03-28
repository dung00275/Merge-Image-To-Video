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
        
        guard let controller = segue.destinationViewController as? CameraViewController else{
            return
        }
        
        controller.delegate = self
        
        
    }
    

    override func openCamera() {
        self.performSegueWithIdentifier("OpenCamera", sender: self)
    }
}
extension ViewController:CameraViewControllerDelegate{
    func takePhoto(image: UIImage, controller: CameraViewController?) {
        self.dismissViewControllerAnimated(true, completion: nil)
        imageView.image = image
    }
    
    
}



