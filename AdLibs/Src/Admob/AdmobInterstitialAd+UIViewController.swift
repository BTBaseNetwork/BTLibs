//
//  AdmobInsertAd+UIViewController.swift
//  tum3rd
//
//  Created by Alex Chow on 2019/11/4.
//  Copyright © 2019 Tumblreader. All rights reserved.
//

import Foundation
import GoogleMobileAds

extension UIViewController{
    
    func admobTryShowInterstitialAd(adUnitId:String) -> Bool {
        guard !AdManager.hasNoAdsPrivilege && AdManager.isAdmobEnabled() else {
            return false
        }
        return AdmobInterstitialAdManager.shared.showAd(adUnitId: adUnitId, rootVC: self)
    }
    
    func admobTryShowStaticAd() -> Bool {
        if let config = AdmobConfig.fromAdManagerList(),let adUnitId = config.staticId{
            return admobTryShowInterstitialAd(adUnitId: adUnitId)
        }
        return false
    }
    
    func admobTryShowVideoAd() -> Bool {
        if let config = AdmobConfig.fromAdManagerList(),let adUnitId = config.videoId{
            return admobTryShowInterstitialAd(adUnitId: adUnitId)
        }
        return false
    }
    
    func admobTryShowInterstitialAd() -> Bool {
        return admobTryShowVideoAd() || admobTryShowStaticAd()
    }
}

extension AdManager{
    func admobLoadInterstitialAds() {
        if let config = AdmobConfig.fromAdManagerList(),let adUnitId = config.videoId{
            AdmobInterstitialAdManager.shared.createAndLoadInterstitial(adUnitId)
        }
        
        if let config = AdmobConfig.fromAdManagerList(),let adUnitId = config.staticId{
            AdmobInterstitialAdManager.shared.createAndLoadInterstitial(adUnitId)
        }
    }
    
    func admobLoadInterstitialAd(adUnitId:String) {
        AdmobInterstitialAdManager.shared.createAndLoadInterstitial(adUnitId)
    }
    
    func admobIsInterstitialAdReady() -> Bool {
        return admobIsVideoAdReady() || admobIsStaticAdReady()
    }
    
    func admobIsInterstitialAdReady(adUnitId:String) -> Bool {
        return AdmobInterstitialAdManager.shared.isAdReady(adUnitId: adUnitId)
    }
    
    func admobIsStaticAdReady() -> Bool {
        if let config = AdmobConfig.fromAdManagerList(),let adUnitId = config.staticId{
            return AdmobInterstitialAdManager.shared.isAdReady(adUnitId: adUnitId)
        }
        return false
    }
    
    func admobIsVideoAdReady() -> Bool {
        if let config = AdmobConfig.fromAdManagerList(),let adUnitId = config.videoId{
            return AdmobInterstitialAdManager.shared.isAdReady(adUnitId: adUnitId)
        }
        return false
    }
}

private class AdmobInterstitialAdManager:NSObject,GADFullScreenContentDelegate {
    static let shared = AdmobInterstitialAdManager()
    
    private var cachedAds = [String:GADInterstitialAd]()
    private var loadingAds = [String]()
    
    func isAdReady(adUnitId:String) -> Bool {
        if let _ = cachedAds[adUnitId]{
            return true
        }
        return false
    }
    
    func showAd(adUnitId:String,rootVC:UIViewController) -> Bool {
        
        if let ad = cachedAds[adUnitId]{
            ad.present(fromRootViewController: rootVC)
            return true
        }
        return false
    }
    
    func createAndLoadInterstitial(_ adUnitID:String) {
        if loadingAds.contains(adUnitID) {
            AdManager.dPrintMessage("createAndLoadInterstitial:\(adUnitID) Is Loading")
            return
        }else if cachedAds.keys.contains(adUnitID){
            AdManager.dPrintMessage("createAndLoadInterstitial:\(adUnitID) Is Loaded")
            return
        }
        AdManager.dPrintMessage("createAndLoadInterstitial:\(adUnitID)")
        loadingAds.append(adUnitID)
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { (loadedAd, error) in
            self.loadingAds.removeAll { id in return id == adUnitID }
            if let err = error{
                NotificationCenter.default.post(Notification(name: .admobFullScreenAdFailedToReceive, object: nil, userInfo: ["adunit" : adUnitID,"error":err]))
                AdManager.dPrintMessage(err.localizedDescription)
                DispatchQueue.main.afterMS(3000) {
                    self.createAndLoadInterstitial(adUnitID)
                }
            }else if let ad = loadedAd{
                self.cachedAds[ad.adUnitID] = ad
                ad.fullScreenContentDelegate = self
                NotificationCenter.default.post(Notification(name: .admobFullScreenAdDidReceived, object: nil, userInfo: ["adunit" : adUnitID]))
                AdManager.dPrintMessage("loaded interstitial ad:\(adUnitID)")
            }
        }
    }
    
    //MARK:GADFullScreenContentDelegate
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        AdManager.dPrintMessage("interstitialad adDidRecordImpression")
        if let iad = ad as? GADInterstitialAd {
            NotificationCenter.default.post(Notification(name: .admobFullScreenAdDidRecordImpression, object: nil, userInfo: ["adunit" : iad.adUnitID]))
        }
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        AdManager.dPrintMessage("interstitialad adWillPresentFullScreenContent")
        if let iad = ad as? GADInterstitialAd {
            NotificationCenter.default.post(Notification(name: .admobFullScreenAdWillPresent, object: nil, userInfo: ["adunit" : iad.adUnitID]))
        }
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        AdManager.dPrintMessage("interstitialad adDidDismissFullScreenContent")
        if let iad = ad as? GADInterstitialAd {
            NotificationCenter.default.post(Notification(name: .admobFullScreenAdDidDismiss, object: nil, userInfo: ["adunit" : iad.adUnitID]))
            cachedAds.removeValue(forKey: iad.adUnitID)
            DispatchQueue.main.afterMS(3000) {
                self.createAndLoadInterstitial(iad.adUnitID)
            }
        }
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        AdManager.dPrintMessage("interstitialad didFailToPresentFullScreenContentWithError")
        if let iad = ad as? GADInterstitialAd {
            NotificationCenter.default.post(Notification(name: .admobFullScreenAdDidFailToPresent, object: nil, userInfo: ["adunit" : iad.adUnitID]))
            cachedAds.removeValue(forKey: iad.adUnitID)
            DispatchQueue.main.afterMS(3000) {
                self.createAndLoadInterstitial(iad.adUnitID)
            }
        }
    }
    
    
}
