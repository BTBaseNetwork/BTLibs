//
//  AdmobRewardedAd+UIViewController.swift
//  tum3rd
//
//  Created by Alex Chow on 2019/11/4.
//  Copyright © 2019 Tumblreader. All rights reserved.
//

import Foundation
import GoogleMobileAds

extension UIViewController{
    func admobTryShowInterstitialRewardedAd(adUnitId:String,forcePresent:Bool = false) -> Bool {
        guard ( forcePresent || !AdManager.hasNoAdsPrivilege) && AdManager.isAdmobEnabled() else {
            return false
        }
        return AdmobInterstitialRewardedAdManager.shared.showAd(adUnitId: adUnitId, rootVC: self)
    }
    
    func admobTryShowInterstitialRewardedAd(forcePresent:Bool = false) -> Bool {
        if let config = AdmobConfig.fromAdManagerList(),let adUnitId = config.irewardedId{
            return admobTryShowInterstitialRewardedAd(adUnitId: adUnitId, forcePresent: forcePresent)
        }
        return false
    }
}

extension AdManager{
    func admobLoadInterstitialRewardedAd() {
        if let config = AdmobConfig.fromAdManagerList(),let adUnitId = config.irewardedId{
            AdmobInterstitialRewardedAdManager.shared.createAndLoadIRewardedAd(adUnitId)
        }
    }
    
    func admobLoadInterstitialRewardedAd(adUnitId:String) {
        AdmobInterstitialRewardedAdManager.shared.createAndLoadIRewardedAd(adUnitId)
    }
    
    func admobIsInterstitialRewardAdReady() -> Bool {
        if let config = AdmobConfig.fromAdManagerList(),let adUnitId = config.irewardedId{
            return admobIsInterstitialRewardAdReady(adUnitId: adUnitId)
        }
        return false
    }
    
    func admobIsInterstitialRewardAdReady(adUnitId:String) -> Bool {
        return AdmobInterstitialRewardedAdManager.shared.isAdReady(adUnitId: adUnitId)
    }
}

extension Notification.Name{
    
    static let admobInterstitialRewardedAdUserEarned = Notification.Name(rawValue: "admobInterstitialRewardedAdUserEarned")
     
}

private class AdmobInterstitialRewardedAdManager:NSObject, GADFullScreenContentDelegate {
    
    static let shared = AdmobInterstitialRewardedAdManager()
    
    private var cachedAds = [String:GADRewardedInterstitialAd]()
    private var loadingAds = [String]()
    
    func isAdReady(adUnitId:String) -> Bool {
        if let _ = cachedAds[adUnitId]{
            return true
        }
        return false
    }
    
    func showAd(adUnitId:String,rootVC:UIViewController) -> Bool {
        if let ad = cachedAds[adUnitId] {
            ad.present(fromRootViewController: rootVC) {
                NotificationCenter.default.post(Notification(name: .admobInterstitialRewardedAdUserEarned, object: nil, userInfo: ["adunit" : ad.adUnitID]))
            }
            return true
        }
        return false
    }
    
    func createAndLoadIRewardedAd(_ adUnitID:String) {
        if loadingAds.contains(adUnitID) {
            AdManager.dPrintMessage("createAndLoadIRewardedAd:\(adUnitID) Is Loading")
            return
        }else if cachedAds.keys.contains(adUnitID){
            AdManager.dPrintMessage("createAndLoadIRewardedAd:\(adUnitID) Is Loaded")
            return
        }
        AdManager.dPrintMessage("createAndLoadIRewardedAd:\(adUnitID)")
        loadingAds.append(adUnitID)
        GADRewardedInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { (loadedAd, error) in
            self.loadingAds.removeAll { id in return id == adUnitID }
            if let err = error{
                NotificationCenter.default.post(Notification(name: .admobFullScreenAdFailedToReceive, object: nil, userInfo: ["adunit" : adUnitID,"error":err]))
                AdManager.dPrintMessage(err.localizedDescription)
                DispatchQueue.main.afterMS(3000) {
                    self.createAndLoadIRewardedAd(adUnitID)
                }
            }else if let ad = loadedAd{
                self.cachedAds[ad.adUnitID] = ad
                ad.fullScreenContentDelegate = self
                NotificationCenter.default.post(Notification(name: .admobFullScreenAdDidReceived, object: nil, userInfo: ["adunit" : adUnitID]))
                AdManager.dPrintMessage("loaded irewarded ad:\(adUnitID)")
            }
        }
    }
    
    //MARK:GADFullScreenContentDelegate
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        AdManager.dPrintMessage("irewardedad GADFullScreenPresentingAd")
        if let rad = ad as? GADRewardedInterstitialAd {
            NotificationCenter.default.post(Notification(name: .admobFullScreenAdDidRecordImpression, object: nil, userInfo: ["adunit" : rad.adUnitID]))
        }
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        AdManager.dPrintMessage("irewardedad GADFullScreenPresentingAd")
        if let rad = ad as? GADRewardedInterstitialAd {
            NotificationCenter.default.post(Notification(name: .admobFullScreenAdWillPresent, object: nil, userInfo: ["adunit" : rad.adUnitID]))
        }
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        AdManager.dPrintMessage("irewardedad GADFullScreenPresentingAd")
        if let rad = ad as? GADRewardedInterstitialAd {
            NotificationCenter.default.post(Notification(name: .admobFullScreenAdDidDismiss, object: nil, userInfo: ["adunit" : rad.adUnitID]))
            cachedAds.removeValue(forKey: rad.adUnitID)
            DispatchQueue.main.afterMS(3000) { self.createAndLoadIRewardedAd(rad.adUnitID) }
        }
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        AdManager.dPrintMessage("irewardedad didFailToPresentFullScreenContentWithError")
        if let rad = ad as? GADRewardedInterstitialAd {
            NotificationCenter.default.post(Notification(name: .admobFullScreenAdDidFailToPresent, object: nil, userInfo: ["adunit" : rad.adUnitID]))
            cachedAds.removeValue(forKey: rad.adUnitID)
            DispatchQueue.main.afterMS(3000) { self.createAndLoadIRewardedAd(rad.adUnitID) }
        }
    }
}

