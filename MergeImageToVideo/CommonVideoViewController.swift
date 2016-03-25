//
//  CommonVideoViewController.swift
//  MergeImageToVideo
//
//  Created by dungvh on 3/25/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit
import Photos
import MobileCoreServices

enum AccessPhotoError:ErrorType,CustomStringConvertible {
    case NotPermit,
    Restricted,
    Denied
    
    internal var description: String{
        switch self {
            case .NotPermit:
                return "This Application is not permit to access photo library!!!!"
            case .Restricted:
                return "This Application was beeen Restricted to access photo library!!!!"
            case .Denied:
                return "This Application was beeen Denied to access photo library!!!!"
        }
        
        
    }
}

func showError(message:String?,controller:UIViewController?)  {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
    let alertAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
    alert.addAction(alertAction)
    controller?.presentViewController(alert, animated: true, completion: nil)
}
class CommonVideoViewController: UIViewController {
    
   
    
    private func requestAccessPhotoLibrary(access:(inner:() throws -> Bool) -> ()) {
        let currentStatus = PHPhotoLibrary.authorizationStatus()
        switch currentStatus {
            case .NotDetermined:
                PHPhotoLibrary.requestAuthorization {(status) in
                    if status == .Authorized{
                        access(inner: {return true})
                    }else{
                        access(inner: {throw AccessPhotoError.NotPermit})
                    }
                    
                }
            case .Authorized:
                access(inner: {return true})
            case .Restricted:
                access(inner: {throw AccessPhotoError.Restricted})
            case .Denied:
                access(inner: {throw AccessPhotoError.Denied})
        }
    }

    
    
    func startMediaBrowserFromViewController() {
       self.requestAccessPhotoLibrary { [weak self](inner) in
            do{
                let result = try inner()
                if result == true {
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self?.openChoosePhoto()
                    })
                    
                }
                
            }catch let error as AccessPhotoError{
                NSOperationQueue.mainQueue().addOperationWithBlock({ 
                    showError(error.description, controller: self)
                })
            }catch {
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    showError("Something Error!!!", controller: self)
                })
                
            }
        }
        
        
    }

}

// MARK: --- Open Photo
extension CommonVideoViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    private func openChoosePhoto(){
        let controller = UIImagePickerController()
        controller.sourceType = .PhotoLibrary
        controller.mediaTypes = [String(kUTTypeImage)]
        controller.delegate = self
        controller.allowsEditing = true
        
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        print("function : \(#function)")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        print("function : \(#function)")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}