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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK:--- Memory Management
    deinit{
        print("\(#function) \(self.dynamicType)")
    }
}