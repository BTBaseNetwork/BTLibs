//
//  AdManager+Inmobi.swift
//  AdManager
//
//  Created by Alex Chow on 2018/12/3.
//  Copyright © 2018 btbase. All rights reserved.
//

import Foundation
import InMobiSDK


// MARK: AdManager + Inmobi In-Feed

extension AdManager {
    func loadOneInfeedAds() {
    }
}

class InMobiInFeedAdManager: NSObject, IMNativeDelegate {
    static let shared = InMobiInFeedAdManager()
    private var inMobiInfeedAds = [IMNative]()
    
    private var loading = [IMNative]()
    
    func loadAds(count: Int) {
        for _ in 0..<count {
            if let ad = IMNative(placementId: 1539129775449) {
                ad.delegate = self
                ad.load()
                loading.append(ad)
            }
        }
    }
    
    func popOneAd(callback: (IMNative?) -> Void) {
        if inMobiInfeedAds.count > 0 {
            callback(inMobiInfeedAds.popLast())
        } else {
            callback(nil)
        }
    }
    
    func native(_ native: IMNative!, didFailToLoadWithError error: IMRequestStatus!) {
        DispatchQueue.main.async {
            dPrint("[inmobi] infeed ad load failure")
            self.loading.removeElement { $0.hashValue == native.hashValue }
        }
    }
    
    func nativeDidFinishLoading(_ native: IMNative!) {
        DispatchQueue.main.async {
            dPrint("[inmobi] infeed ad loaded")
            self.inMobiInfeedAds.append(native)
        }
    }
}


// MARK: AdManager + Inmobi Splash Ad

var isSecondScreenDisplayed = false // Use this to check if second screen has to be shown or not
var splashAdView: UIView! // Use this to check visibility of second screen
var inMobiSplashAd: IMNative!
var splashTimeout: Timer!

extension AdManager: IMNativeDelegate {
    private static func inmobiLoadSplashAd() {
        dPrint("[inmobi] loadSplashAd")
        inMobiSplashAd = IMNative(placementId: 1539854077600)
        inMobiSplashAd?.delegate = AdManager.shared
        inMobiSplashAd?.load()
    }
    
    static func enableAppRelaunchSplashAd() {
        NotificationCenter.default.addObserver(AdManager.shared, selector: #selector(tryShowSplashAdOnAppWillEnterForeground(a:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    static func disableAppRelaunchSplashAd() {
        NotificationCenter.default.removeObserver(AdManager.shared, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func tryShowSplashAdOnAppWillEnterForeground(a: Any) {
        if let topVC = UIViewController.topViewController() {
            AdManager.tryShowSplashAd(atViewController: topVC)
        }
    }
    
    static func tryShowSplashAd(atViewController vc: UIViewController, requestTimeOut: TimeInterval = 3) {
        if inMobiSplashAd != nil {
            return
        }
        inmobiLoadSplashAd()
        if let launchScreen = UIViewController.instanceFromStoryBoard("LaunchScreen", identifier: "LaunchScreen").view {
            launchScreen.removeFromSuperview()
            launchScreen.frame = UIScreen.main.bounds
            vc.view.addSubview(launchScreen)
            splashAdView = launchScreen
            splashTimeout = Timer.scheduledTimer(withTimeInterval: requestTimeOut, repeats: false, block: { _ in
                splashTimeout = nil
                self.dismissSplashAd()
            })
        }
    }
    
    private static func dismissSplashAd() {
        if isSecondScreenDisplayed {
            dPrint("[inmobi] Splash Ad Is Displayed")
        } else {
            dPrint("[inmobi] Load Splash Ad Timeout Or Error")
            splashAdView.isHidden = true
            inMobiSplashAd.recyclePrimaryView()
            inMobiSplashAd = nil
            splashAdView.removeFromSuperview()
            splashAdView = nil
        }
    }
    
    // MARK: IMNativeDelegate
    
    internal func nativeWillPresentScreen(_ native: IMNative) {
        dPrint("[inmobi] Native Ad will present screen")
        isSecondScreenDisplayed = true
        splashAdView.addSubview(native.primaryView(ofWidth: UIScreen.main.bounds.width))
    }
    
    internal func native(_ native: IMNative!, didFailToLoadWithError error: IMRequestStatus!) {
        dPrint("[inmobi] didFailToLoadWithError:\(error.debugDescription)")
    }
}
