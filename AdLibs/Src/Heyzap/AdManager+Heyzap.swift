//
//  AdManager+Heyzap.swift
//  AdManager
//
//  Created by Alex Chow on 2018/12/4.
//  Copyright © 2018 btbase. All rights reserved.
//

import Foundation
import AlamofireImage

private let DEFAULT_HEYZAP_PUBLISHER_ID = "3bbb2281529aeadf3f47239b7664b5c4"

class HeyzapConfig {
    var enabled:Bool = true
    var heyzapId:String!
}

private var heyzapEnabled = false

extension HeyzapConfig{
    static func fromAdManagerList()->HeyzapConfig?{
        if let url = AdManager.localConfigURLIfExists,let dict = NSDictionary(contentsOf: url)?.value(forKey: "Heyzap") as? NSDictionary{
            
            let config = HeyzapConfig()
            config.enabled = dict["Enabled"] as? Bool ?? true
            config.heyzapId = dict["HeyzapId"] as? String
            
            if String.isNullOrWhiteSpace(config.heyzapId){
                return nil
            }else{
                return config
            }
            
        }else{
            return nil
        }
    }
}

fileprivate var nativeAds = [HZNativeAd]()

extension AdManager{
    static func addHeyzap() {
        NotificationCenter.default.addObserver(forName: .adManagerDidStart, object: nil, queue: nil) { (_) in
            initHeyzap()
            heyzapFetchNativeAd()
            heyzapFetchInstertitialAds()
        }
        
        NotificationCenter.default.addObserver(forName: .adManagerConfigDidUpdated, object: nil, queue: nil) { (_) in
            if let config = HeyzapConfig.fromAdManagerList(){
                if HeyzapAds.isStarted() && !config.enabled{
                    dPrint("[AdManager] Heyzap Is Disabled")
                    heyzapEnabled = false
                }else if !HeyzapAds.isStarted() && config.enabled{
                    initHeyzap()
                }
            }
        }
        
        dPrint("[AdManager] Add Heyzap")
    }
    
    static func isHeyzapEnabled() -> Bool{
        return heyzapEnabled
    }
    
    static func initHeyzap(){
        if let config = HeyzapConfig.fromAdManagerList(){
            if config.enabled{
                heyzapEnabled = true
                if String.isNullOrWhiteSpace(config.heyzapId){
                    dPrint("[AdManager] AdManager.plist Not Exists, Use Default Heyzap Id")
                    HeyzapAds.start(withPublisherID: DEFAULT_HEYZAP_PUBLISHER_ID)
                }else{
                    HeyzapAds.start(withPublisherID: config.heyzapId)
                    dPrint("[AdManager] Heyzap Inited")
                }
            }else{
                heyzapEnabled = false
                dPrint("[AdManager] Heyzap Is Disable")
            }
        }else{
            dPrint("[AdManager] AdManager.plist Not Exists, Use Default Heyzap Id")
            heyzapEnabled = true
            HeyzapAds.start(withPublisherID: DEFAULT_HEYZAP_PUBLISHER_ID)
        }
    }
    
    static func heyzapShowTestVC(){
        HeyzapAds.presentMediationDebugViewController()
    }
    
    static func heyzapFetchInstertitialAds() {
        guard !AdManager.hasNoAdsPrivilege && heyzapEnabled else {
            return
        }
        
        HZIncentivizedAd.fetch()
        HZVideoAd.fetch()
    }
    
    static func heyzapFetchNativeAd() {
        guard !AdManager.hasNoAdsPrivilege && heyzapEnabled else {
            return
        }
        DispatchQueue.main.async {
            HZNativeAdController.fetchAds(fetchNativeCount, tag: nil) { _, adCollection in
                
                let ads = (adCollection?.ads?.map { $0 as! HZNativeAd }) ?? []
                
                if ads.count > 0 {
                    nativeAds = ads
                    let portraitReqs = ads.filter { ($0.portraitCreative?.url) != nil }.map { URLRequest(url: $0.portraitCreative.url) }
                    let iconReqs = ads.filter { ($0.iconImage?.url) != nil }.map { URLRequest(url: $0.iconImage.url) }
                    let landscapeReqs = ads.filter { ($0.landscapeCreative?.url) != nil }.map { URLRequest(url: $0.landscapeCreative.url) }
                    
                    var reqs = [URLRequest]()
                    reqs.append(contentsOf: portraitReqs)
                    reqs.append(contentsOf: iconReqs)
                    reqs.append(contentsOf: landscapeReqs)
                    
                    ImageDownloader.default.download(reqs)
                }
            }
        }
    }
    
    public static func heyzapPopANativeAd() -> HZNativeAd? {
        if nativeAds.count > 0 {
            return nativeAds.removeFirst()
        } else {
            heyzapFetchNativeAd()
        }
        return nil
    }
}
