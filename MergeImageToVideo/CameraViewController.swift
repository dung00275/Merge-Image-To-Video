//
//  CameraViewController.swift
//  MergeImageToVideo
//
//  Created by dungvh on 3/28/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

// MARK: --- Protocol
protocol CameraViewControllerDelegate:class {
    func takePhoto(image:UIImage,controller:CameraViewController?)
}

// MARK: --- Init
class CameraViewController: UIViewController {
    weak var delegate:CameraViewControllerDelegate?
    @IBOutlet weak var btnFlash: UIButton!
    
    private var session:AVCaptureSession!
    private var previewLayer:AVCaptureVideoPreviewLayer!
    private var captureDevice:AVCaptureDevice!
    
    private var cameraType:AVCaptureDevicePosition = .Front
        {
        didSet(oldValue){
            guard self.cameraType != oldValue else{
                return
            }
            do{
                try changeCamera()
            }catch let error as NSError {
                NSOperationQueue.mainQueue().addOperationWithBlock({ [weak self] in
                    showError(error.localizedDescription, controller: self)
                })
            }
        }
    }
    
    private var stillImageOutput:AVCaptureStillImageOutput!
    
    private var _currentFlashMode = AVCaptureFlashMode.Off{
        didSet{
            self.btnFlash.selected = self._currentFlashMode == .On
        }
    }
    
    private var currentFlashMode:AVCaptureFlashMode {
        get{
            return _currentFlashMode
        }
        
        set(newValue){
            guard newValue != self._currentFlashMode else{
                return
            }
            
            do{
                let result = try changeFlashMode(newValue)
                if result == true {
                    self._currentFlashMode = newValue
                }
                
            }catch let error as NSError {
                print(error.localizedDescription)
            }
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do{
            try setupView()
        }catch let error as NSError {
            showError(error.localizedDescription, controller: self)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK:--- Memory Management
    deinit{
        print("\(#function) \(self.dynamicType)")
        if session != nil
        {
            self.session.stopRunning()
            self.previewLayer.removeFromSuperlayer()
            self.session = nil
        }
    }
    
}

// MARK: --- Helper
private extension CameraViewController{
    
    func isFlashAvailable() -> Bool {
        
        guard let currentCameraInput = self.session.inputs.first as? AVCaptureInput else{
            return false
        }
        guard let deviceInput = currentCameraInput as? AVCaptureDeviceInput else{
            return false
        }
        
        return deviceInput.device.torchAvailable
    }
    
    func getCameraDevice() -> AVCaptureDevice? {
        guard let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as? [AVCaptureDevice] else{
            return nil
        }
        
        for device in devices {
            if device.position == self.cameraType {
                return device
            }
        }
        
        return nil
    }
    
    func captureConnection() -> AVCaptureConnection? {
        guard let stillImageOutput = stillImageOutput else {return nil}
        guard let connections = stillImageOutput.connections as? [AVCaptureConnection] else{return nil}
        
        for connection in connections {
            guard let ports = connection.inputPorts as? [AVCaptureInputPort] else{
                continue
            }
            for port in ports {
                if port.mediaType == AVMediaTypeVideo {
                    return connection
                }
            }
        }
        
        return nil
    }
}

// MARK: --- Change Flash Mode
private extension CameraViewController{
    func changeFlashMode(mode:AVCaptureFlashMode) throws -> Bool {
        guard let currentCameraInput = self.session.inputs.first as? AVCaptureInput else{
            return false
        }
        
        guard let deviceInput = currentCameraInput as? AVCaptureDeviceInput else{
            return false
        }
        
        if !deviceInput.device.torchAvailable{
            return false
        }
        self.session.beginConfiguration()
        
        defer{
            self.session.commitConfiguration()
        }
        
        try deviceInput.device.lockForConfiguration()
        if mode == .On{
            deviceInput.device.torchMode = .On
        }else
        {
            deviceInput.device.torchMode = .Off
        }
        
        deviceInput.device.unlockForConfiguration()
        
        return true
    }
    
    
}

// MARK: --- Change Camera
private extension CameraViewController{
    func changeCamera() throws{
        guard let session = self.session else {
            throw NSError(domain: "com.changeCamera", code: 479, userInfo: [NSLocalizedDescriptionKey:"Error Session"])
        }
        
        guard let newDevice = self.getCameraDevice() else{
            throw NSError(domain: "com.changeCamera", code: 480, userInfo: [NSLocalizedDescriptionKey:"No Camera To Change"])
        }
        
        let newVideoInput = try AVCaptureDeviceInput(device: newDevice)
        
        defer{
            session.addInput(newVideoInput)
            self.captureDevice = newDevice
            session.commitConfiguration()
            self.btnFlash.enabled = isFlashAvailable()
            if !self.btnFlash.enabled{
                self._currentFlashMode = .Off
            }
        }
        
        session.beginConfiguration()
        guard let currentCameraInput = session.inputs.first as? AVCaptureInput else {
            return
        }
        
        session.removeInput(currentCameraInput)
        
        
    }
}

// MARK: --- Setup
private extension CameraViewController{
    func setupView() throws {
        guard session == nil else {
            throw NSError(domain: "com.InitCamera", code: 467, userInfo: [NSLocalizedDescriptionKey:"Already Session"])
        }
        
        defer{
            self.btnFlash.enabled = isFlashAvailable()
        }
        
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSessionPresetPhoto
        
        let captureLayer = AVCaptureVideoPreviewLayer(session: session)
        captureLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        captureLayer.frame = view.bounds
        self.view.layer.insertSublayer(captureLayer, atIndex: 0)
        
        self.previewLayer = captureLayer
        
        self.captureDevice = getCameraDevice() ?? AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let input = try AVCaptureDeviceInput(device: self.captureDevice)
        self.session.addInput(input)
        self.previewLayer.connection.videoOrientation = .Portrait
        self.stillImageOutput = AVCaptureStillImageOutput()
        self.session.addOutput(stillImageOutput)
        self.session.startRunning()
    }
    
}

// MARK: --- Got Image
extension CameraViewController{
    private func capture(takeImage:(result:() throws -> UIImage) -> ()) {
        guard let videoConnection = captureConnection() else {
            takeImage(result:
                {throw NSError(
                domain: "com.TakeImage",
                code: 468,
                userInfo: [NSLocalizedDescriptionKey:"No connection to outputImage"])})
            return
        }
        
        self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) { (buffer, error) in
            guard error == nil else{
                takeImage(result: {throw error})
                return
            }
            
            guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer), image = UIImage(data: data) else {
                takeImage(result:
                    {throw NSError(
                        domain: "com.TakeImage",
                        code: 468,
                        userInfo: [NSLocalizedDescriptionKey:"No Image!!!"])})
                return
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock({
                takeImage(result: {return image})
            })
        }
    }
}

// MARK: --- Action
extension CameraViewController{
    
    @IBAction func tapByChangeFlash(sender: AnyObject) {
        self.currentFlashMode = self.currentFlashMode == .On ? .Off : .On
    }
    
    @IBAction func tapByChangeCamera(sender: UIButton) {
        self.cameraType = self.cameraType == .Front ? .Back : .Front
    }
    
    
    @IBAction func tapByTakeImage(sender: AnyObject) {
        capture { [weak self](result) in
            do{
                let image = try result()
                self?.delegate?.takePhoto(image, controller: self)
            }catch let error as NSError {
                NSOperationQueue.mainQueue().addOperationWithBlock({ 
                    showError(error.localizedDescription, controller: self)
                })
            }
        }
    }
    
    @IBAction func tapByCancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
