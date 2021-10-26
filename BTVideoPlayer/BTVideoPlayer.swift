//
//  BTVideoPlayer.swift
//  tum3rd
//
//  Created by Alex Chow on 2018/10/17.
//  Copyright © 2018 tum3rd. All rights reserved.
//

import AVKit
import Foundation

protocol BTVideoPlayerDelegate {
}

public class BTVideoPlayer: AVPlayer {
    typealias BTVideoPlayerItemStatusChanged = (_ sender: BTVideoPlayer, _ playerItem: AVPlayerItem, _ oldState: AVPlayerItem.Status?, _ newState: AVPlayerItem.Status) -> Void
    
    typealias BTVideoPlayerItemLoadingProgressChanged = (_ sender: BTVideoPlayer, _ playerItem: AVPlayerItem, _ loaded: Float) -> Void
    
    typealias BTVideoPlayerItemPlayingProgressChanged = (_ sender: BTVideoPlayer, _ playerItem: AVPlayerItem, _ progress: Float) -> Void
    
    typealias BTVideoPlayerTimeControlStatusChanged = (_ sender: BTVideoPlayer, _ oldState: TimeControlStatus?, _ newState: TimeControlStatus) -> Void
    
    var onPlayerItemStatusChanged: BTVideoPlayerItemStatusChanged?
    var onPlayerItemLoadingProgressChanged: BTVideoPlayerItemLoadingProgressChanged?
    var onPlayerItemPlayingProgressChanged: BTVideoPlayerItemPlayingProgressChanged?
    var onPlayerTimeControlStatusChanged: BTVideoPlayerTimeControlStatusChanged?
    
    var onVideoDidPlayEnd: ((_ sender: BTVideoPlayer) -> Void)?
    
    private var playingObserver: Any?
    private var timeControlObserver: Any?
    private var timeControlObserverContext = random()
    
    public override func replaceCurrentItem(with item: AVPlayerItem?) {
        pause()
        
        addPlayingObserver()
        
        if let citem = currentItem {
            removePlayerItemObservers(item: citem)
        }
        
        if let newItem = item {
            addPlayerItemObservers(item: newItem)
        }
        
        super.replaceCurrentItem(with: item)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &timeControlObserverContext {
            if let item = object as? AVPlayerItem, item == currentItem {
                if keyPath == #keyPath(AVPlayerItem.status) {
                    onPlayerItemStatusChanged?(self, item, change?[NSKeyValueChangeKey.oldKey] as? AVPlayerItem.Status, item.status)
                } else if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
                    onPlayerItemLoadingProgressChanged?(self, item, item.loadedProgress)
                }
            }
        }
    }
    
    private func removePlayerItemObservers(item: AVPlayerItem) {
        item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &timeControlObserverContext)
        item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), context: &timeControlObserverContext)
        NotificationCenter.default.removeObserver(self)
    }
    
    private func addPlayerItemObservers(item: AVPlayerItem) {
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &timeControlObserverContext)
        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: [.old, .new], context: &timeControlObserverContext)
        let selector = #selector(avplayerItemNotification(a:))
        NotificationCenter.default.addObserver(self, selector: selector, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: item)
        NotificationCenter.default.addObserver(self, selector: selector, name: Notification.Name.AVPlayerItemTimeJumped, object: item)
        NotificationCenter.default.addObserver(self, selector: selector, name: Notification.Name.AVPlayerItemPlaybackStalled, object: item)
        NotificationCenter.default.addObserver(self, selector: selector, name: Notification.Name.AVPlayerItemNewErrorLogEntry, object: item)
        NotificationCenter.default.addObserver(self, selector: selector, name: Notification.Name.AVPlayerItemNewAccessLogEntry, object: item)
        NotificationCenter.default.addObserver(self, selector: selector, name: Notification.Name.AVPlayerItemFailedToPlayToEndTime, object: item)
    }
    
    func addPlayingObserver() {
        if playingObserver != nil {
            return
        }
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        playingObserver = addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            if let totalTimeDuration = self?.currentItem?.duration {
                let currentTime: Float = Float(CMTimeGetSeconds(time))
                let totalTime: Float = Float(CMTimeGetSeconds(totalTimeDuration))
                let progress = totalTime > 0 ? currentTime / totalTime : 0
                self?.onPlayerItemPlayingProgressChanged?(self!, self!.currentItem!, progress)
            }
        }
        
        timeControlObserver = CallbackObserver(beOvserved: self, keyPath: #keyPath(AVPlayer.timeControlStatus), options: [.new, .old]) { [weak self] _, _, change, _ in
            self?.onPlayerTimeControlStatusChanged?(self!, change?[NSKeyValueChangeKey.oldKey] as? TimeControlStatus, self!.timeControlStatus)
        }
    }
    
    func killPlayer() {
        onPlayerItemStatusChanged = nil
        onVideoDidPlayEnd = nil
        onPlayerTimeControlStatusChanged = nil
        onPlayerItemLoadingProgressChanged = nil
        onPlayerItemPlayingProgressChanged = nil
        super.replaceCurrentItem(with: nil)
        playingObserver = nil
        timeControlObserver = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        
        playingObserver = nil
        timeControlObserver = nil
        
        debugLog("Deinited:\(self.description)")
    }
    
    @objc func avplayerItemNotification(a: Notification) {
        if let item = a.object as? AVPlayerItem, item == currentItem {
            if a.name == .AVPlayerItemDidPlayToEndTime {
                onVideoDidPlayEnd?(self)
            }
        }
    }
}

class CallbackObserver: NSObject {
    typealias CallbackObserved = (CallbackObserver, Any?, [NSKeyValueChangeKey: Any]?, UnsafeMutableRawPointer?) -> Void
    
    var onObserved: CallbackObserved?
    
    var keyPath: String
    
    var beOvserved: NSObject?
    
    private var observerContext = random()
    
    init(beOvserved: NSObject, keyPath: String, options: NSKeyValueObservingOptions, onObserved: @escaping CallbackObserved) {
        self.onObserved = onObserved
        self.keyPath = keyPath
        self.beOvserved = beOvserved
        super.init()
        debugLog("Inited:\(description)")
        beOvserved.addObserver(self, forKeyPath: self.keyPath, options: options, context: &observerContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &observerContext && keyPath == self.keyPath {
            onObserved?(self, object, change, context)
        }
    }
    
    deinit {
        debugLog("Deinited:\(self.description)")
        beOvserved?.removeObserver(self, forKeyPath: keyPath, context: &observerContext)
    }
}

// MARK: AVPlayerItem+loadedProgress

extension AVPlayerItem {
    var loadedProgress: Float {
        let timeRanges = loadedTimeRanges
        if let timerange = timeRanges.first as? CMTimeRange {
            let bufferDuration = CMTimeAdd(timerange.start, timerange.duration)
            let duration = CMTimeGetSeconds(bufferDuration)
            let totalDuration = CMTimeGetSeconds(self.duration)
            let progress = totalDuration > 0 ? Float(duration / totalDuration) : 0
            return progress
        }
        return 0
    }
    
    var videoTimeDuration: Float64 {
        let totalDuration = CMTimeGetSeconds(self.duration)
        return totalDuration
    }
    
    var loadedTime: Float64 {
        let timeRanges = loadedTimeRanges
        if let timerange = timeRanges.first as? CMTimeRange {
            let bufferDuration = CMTimeAdd(timerange.start, timerange.duration)
            let duration = CMTimeGetSeconds(bufferDuration)
            return duration
        }
        return 0
    }
    
    var playingTime: Float64 {
        return CMTimeGetSeconds(currentTime())
    }
    
    var shortageFramesForCurrentTime: Bool {
        let loaded = loadedProgress
        let loadedT = loadedTime
        let playingT = playingTime
        
        #if DEBUG
        dPrint("loaded:\(loaded) playing:\(playingTime) loadedtime:\(loadedTime)")
        #endif
        
        return loaded < 1 && playingT + 5 >= loadedT
    }
    
    var existsThumbnail: Bool {
        if let range = self.seekableTimeRanges.first as? CMTimeRange {
            return CMTimeGetSeconds(CMTimeAdd(range.start, range.duration)) >= 0.1
        }
        return false
    }
}
