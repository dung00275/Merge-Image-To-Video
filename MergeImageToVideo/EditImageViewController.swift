//
//  EditImageViewController.swift
//  MergeImageToVideo
//
//  Created by dungvh on 3/28/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit

class EditImageViewController: UIViewController {
    
    var currentImage:UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = currentImage
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