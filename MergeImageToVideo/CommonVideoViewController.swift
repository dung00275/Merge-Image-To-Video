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

// MARK:--- Error Access type
enum AccessLibraryError:ErrorType,CustomStringConvertible {
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


// MARK:--- Check Access
class CommonVideoViewController: UIViewController {
    
    private func requestAccessCamera(access:(inner:() throws -> Bool) -> ()) {
        
        guard UIImagePickerController.isSourceTypeAvailable(.Camera) else{
            access(inner: { throw NSError(domain: "com.openPhotoLibrary", code: 478, userInfo: [NSLocalizedDescriptionKey:"Camera is unavailable!!!"])})
            return
        }
        
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch status {
            case .Authorized:
                access(inner: {return true})
            case .Denied:
                 access(inner: {throw AccessLibraryError.Denied})
            case .Restricted:
                access(inner: {throw AccessLibraryError.Restricted})
            case .NotDetermined:
                AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted:Bool) in
                    if granted{
                        access(inner: {return true})
                    }else{
                        access(inner: {throw AccessLibraryError.NotPermit})
                    }
                })
        }
        
    }
   
    private func requestAccessPhotoLibrary(access:(inner:() throws -> Bool) -> ()) {
        guard UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) else{
            access(inner: { throw NSError(domain: "com.openPhotoLibrary", code: 478, userInfo: [NSLocalizedDescriptionKey:"Can't Open Photo Library!!!"])})
            return
        }
        
        let currentStatus = PHPhotoLibrary.authorizationStatus()
        switch currentStatus {
            case .NotDetermined:
                PHPhotoLibrary.requestAuthorization {(status) in
                    if status == .Authorized{
                        access(inner: {return true})
                    }else{
                        access(inner: {throw AccessLibraryError.NotPermit})
                    }
                    
                }
            case .Authorized:
                access(inner: {return true})
            case .Restricted:
                access(inner: {throw AccessLibraryError.Restricted})
            case .Denied:
                access(inner: {throw AccessLibraryError.Denied})
        }
    }
}

// MARK: --- Public function to check + open 
extension CommonVideoViewController{
    
    // Camera
    func startOpenCameraFromViewController(){
        self.requestAccessCamera { [weak self](inner) in
            do{
                let result = try inner()
                guard result == true else{
                    throw NSError(domain: "com.openCamera", code: 488, userInfo: [NSLocalizedDescriptionKey:"Error Unknown"])
                }
                
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    self?.openCamera()
                })

            }catch let error as AccessLibraryError{
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    showError(error.description, controller: self)
                })
            }catch{
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    showError("Something Error!!!", controller: self)
                })
            }
        }
    }
    
    // Photo
    func startPhotoBrowserFromViewController() {
        self.requestAccessPhotoLibrary { [weak self](inner) in
            do{
                let result = try inner()
                
                guard result == true else{
                    throw NSError(domain: "com.openPhotoLibrary", code: 488, userInfo: [NSLocalizedDescriptionKey:"Error Unknown"])
                }
                
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    self?.openChoosePhoto()
                })
                
            }catch let error as AccessLibraryError{
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


// MARK: --- Open Camera + Override
extension CommonVideoViewController{
    func openCamera() {
        print("Please Override \(#function)")
    }
}

// MARK: --- Open Photo + Override
extension CommonVideoViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func openChoosePhoto(){
        let controller = UIImagePickerController()
        controller.sourceType = .SavedPhotosAlbum
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
        
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else{
            return
        }
        
        handleImageChooseImage(image)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        print("function : \(#function)")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: --- Handle complete choose image
extension CommonVideoViewController{
    func handleImageChooseImage(image:UIImage)  {
        print("Please Override \(#function)")
    }
}


