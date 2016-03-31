//
//  CreateVideoUltility.swift
//  MergeImageToVideo
//
//  Created by dungvh on 3/29/16.
//  Copyright © 2016 dungvh. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

// MARK: --- Queue
protocol ExcutableQueue {
    var queue: dispatch_queue_t { get }
}

extension ExcutableQueue {
    func execute(closure: () -> Void) {
        dispatch_async(queue, closure)
    }
}

struct Delay:ExcutableQueue {
    private var kindOfQueue:Queue
    private var delay:Double
    internal var queue: dispatch_queue_t{
        return kindOfQueue.queue
    }
    
    init(delay:Double,queue:Queue){
        self.kindOfQueue = queue
        self.delay = delay
    }
    
    func execute(closure: () -> Void) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * self.delay)), queue, closure)
    }
}

enum Queue: ExcutableQueue {
    case Main
    case UserInteractive
    case UserInitiated
    case Utility
    case Background
    
    var queue: dispatch_queue_t {
        switch self {
        case .Main:
            return dispatch_get_main_queue()
        case .UserInteractive:
            return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
        case .UserInitiated:
            return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
        case .Utility:
            return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
        case .Background:
            return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        }
    }
}

enum SerialQueue: String, ExcutableQueue {
    case DownLoadImage = "myApp.SerialQueue.DownLoadImage"
    case UpLoadFile = "myApp.SerialQueue.UpLoadFile"
    
    var queue: dispatch_queue_t {
        return dispatch_queue_create(rawValue, DISPATCH_QUEUE_SERIAL)
    }
}

// MARK: --- Class Joint Image

protocol ApplyEffectToVideo:class {
    func applyVideoEffectsToComposition(composition:AVMutableVideoComposition,size:CGSize)
    func exportVideoToUrl() -> NSURL?
    func exportDidFinish(session:AVAssetExportSession?)
}

final class VideoMergeImage {
    
    private let videoAsset:AVAsset
    private weak var delegate:ApplyEffectToVideo?
    
    init(url:NSURL,delegate:ApplyEffectToVideo?){
        videoAsset = AVAsset(URL: url)
        self.delegate = delegate
    }
    
    deinit{
        print("\(#function) class : \(self.dynamicType)")
    }
}

extension VideoMergeImage{
    func videoOuput() throws{
        // - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances
        let mixComposition = AVMutableComposition()
        
        //- Video track
        let videoTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                                                                     preferredTrackID: kCMPersistentTrackID_Invalid)
        
        try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, self.videoAsset.duration),
                                       ofTrack: self.videoAsset.tracksWithMediaType(AVMediaTypeVideo).first!,
                                       atTime: kCMTimeZero)
        
        // - Create AVMutableVideoCompositionInstruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.videoAsset.duration)
        
        // - Create an AVMutableVideoCompositionLayerInstruction for the video track
        let videolayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let videoAssetTrack = self.videoAsset.tracksWithMediaType(AVMediaTypeVideo).first!
        
        var videoAssetOrientation_ = UIImageOrientation.Up
        var isVideoAssetPortrait_ = false
        
        let videoTransform = videoAssetTrack.preferredTransform
        if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
            videoAssetOrientation_ = .Right;
            isVideoAssetPortrait_ = true;
        }
        
        if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
            videoAssetOrientation_ =  .Left;
            isVideoAssetPortrait_ = true;
        }
        if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
            videoAssetOrientation_ =  .Up;
        }
        if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
            videoAssetOrientation_ = .Down;
        }
        
        
        
        videolayerInstruction.setTransform(videoAssetTrack.preferredTransform, atTime: kCMTimeZero)
        videolayerInstruction.setOpacity(0.0, atTime: self.videoAsset.duration)
        
        // - Add instructions
        
        mainInstruction.layerInstructions = [videolayerInstruction]
        
        let mainCompositionInst = AVMutableVideoComposition()
        var naturalSize = CGSizeZero
        if isVideoAssetPortrait_{
            naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width)
        }else{
            naturalSize = videoAssetTrack.naturalSize
        }
        
        let renderWidth = naturalSize.width
        let renderHeight = naturalSize.height
        
        mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight)
        mainCompositionInst.instructions = [mainInstruction]
        mainCompositionInst.frameDuration = CMTimeMake(1, 30)
        
        // - Apply Effect
        self.delegate?.applyVideoEffectsToComposition(mainCompositionInst, size: naturalSize)
        
        // - Get Path
        guard let url = self.delegate?.exportVideoToUrl() else {
            throw NSError(domain: "com.saveUrlVideo", code: 794, userInfo: [NSLocalizedDescriptionKey:"No Url To Save!!!!"])
        }
        
        let exporter = AVAssetExportSession(asset: mixComposition,
                                            presetName: AVAssetExportPresetMediumQuality)
        exporter?.outputURL = url
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = mainCompositionInst
        exporter?.exportAsynchronouslyWithCompletionHandler({ 
            NSOperationQueue.mainQueue().addOperationWithBlock({ [weak self] in
                self?.delegate?.exportDidFinish(exporter)
            })
        })
        
    }
    
    
}
