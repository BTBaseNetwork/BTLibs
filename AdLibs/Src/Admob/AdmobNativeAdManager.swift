//
//  AdmobNativeAdManager.swift
//  tum3rd
//
//  Created by Alex Chow on 2019/11/4.
//  Copyright © 2019 Tumblreader. All rights reserved.
//

import Foundation
import GoogleMobileAds

extension AdManager{
    func admobNativeAdManager() -> AdmobNativeAdManager {
        return AdmobNativeAdManager.shared
    }
}

class AdmobNativeAdManager : NSObject,GADAdLoaderDelegate{
    
    
    static let shared = AdmobNativeAdManager()
    
    private override init(){}
    
    var rootVc:UIViewController!
    
    var adLoader: GADAdLoader!
    
    var adUnitId:String!
    
    var cachedAds = [GADNativeAd]()
    
    var maxCacheAds = 3
    
    func startLoadNativeAds(vc:UIViewController,maxCacheAds:Int) {
        self.rootVc = vc
        self.maxCacheAds = maxCacheAds
        adUnitId = AdmobConfig.fromAdManagerList()?.nativeId
        loadAds()
    }
    
    private func loadAds() {
        guard adUnitId != nil && adLoader == nil else {
            return
        }
        
        adLoader = GADAdLoader(adUnitID: adUnitId, rootViewController: rootVc,
                               adTypes: [GADAdLoaderAdType.customNative],
                               options: [])
        adLoader.delegate = self
        adLoader.load(GADRequest())
        dPrint("[AdmobNativeAdManager] Start Load New NativeAd, Cached:\(cachedAds.count)")
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        // A unified native ad has loaded, and can be displayed.
        cachedAds.append(nativeAd)
        dPrint("[AdmobNativeAdManager] NativeAd Received, Cached:\(cachedAds.count)")
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        
    }
    
    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        // The adLoader has finished loading ads, and a new request can be sent.
        self.adLoader = nil
        if cachedAds.count < maxCacheAds {
            DispatchQueue.global().async {
                self.loadAds()
            }
        }else{
            dPrint("[AdmobNativeAdManager] NativeAds DidFinishLoading, Cached:\(cachedAds.count)")
        }
    }
    
    func popNativeAd() -> GADNativeAd? {
        let ad = cachedAds.popLast()
        
        dPrint("[AdmobNativeAdManager] Pop NativeAd, Cached:\(cachedAds.count)")
        
        if cachedAds.count == 0 {
            loadAds()
        }
        return ad
    }
    
    func popNativeAds(count:Int) -> [GADNativeAd] {
        var result = [GADNativeAd]()
        for _ in 0..<count {
            if let item  = cachedAds.popLast(){
                result.append(item)
            }else{
                break
            }
        }
        
        dPrint("[AdmobNativeAdManager] Pop NativeAds, Cached:\(cachedAds.count)")
        
        if cachedAds.count == 0 {
            loadAds()
        }
        
        return result
        
    }
}
