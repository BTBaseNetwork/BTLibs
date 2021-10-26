//
//  AdManager+GDT.swift
//  AdManager
//
//  Created by Alex Chow on 2017/5/22.
//  Copyright © 2017年 Bahamut. All rights reserved.
//

//Copy libGDTMobSDK.a to project directory and add reference to Target
//Import h file in Bridge Header: #import "GDTAd.h"

import Foundation

class GDTConfig {
    var enabled:Bool = true
    var appId:String!
    var bannerId:String!
    var instertitialId:String!
    var splashId:String!
    var nativeId:String!
}

extension GDTConfig{
    static func fromAdManagerList()->GDTConfig?{
        if let url = AdManager.localConfigURLIfExists,let dict = NSDictionary(contentsOf: url)?.value(forKey: "GDT") as? NSDictionary{
            
            let gdt = GDTConfig()
            gdt.enabled = dict["Enabled"] as? Bool ?? true
            gdt.appId = dict["AppId"] as? String
            gdt.bannerId = dict["BannerId"] as? String
            gdt.instertitialId = dict["InstertitialId"] as? String
            gdt.splashId = dict["SplashId"] as? String
            gdt.nativeId = dict["NativeId"] as? String
            
            if String.isNullOrWhiteSpace(gdt.appId){
                return nil
            }else{
                return gdt
            }
            
        }else{
            return nil
        }
    }
}

fileprivate class GDTSplashAdDG: NSObject,GDTSplashAdDelegate {
    private(set) static var instance = GDTSplashAdDG()
    
    var lastSplashPresented = Date(timeIntervalSince1970: 0)
    
    var splashBottomView:UIView!
    var splash:GDTSplashAd!
    var splashAdLoaded = false
    var rootViewController:UIViewController!
    var keyWindow:UIWindow!
    
    func splashAdSuccessPresentScreen(_ splashAd: GDTSplashAd!) {
        dPrint("[GDTSplashAdDG]: splashAdSuccessPresentScreen")
        lastSplashPresented = Date()
        splashAdLoaded = true
    }
    
    func splashAdClicked(_ splashAd: GDTSplashAd!) {
        dPrint("[GDTSplashAdDG]: splashAdClicked")
    }
    
    func splashAdFail(toPresent splashAd: GDTSplashAd!, withError error: Error!) {
        dPrint("[GDTSplashAdDG]: splashAdFail:\(error?.localizedDescription ?? "Unknow")")
        tryResetRootVC()
    }
    
    func splashAdWillClosed(_ splashAd: GDTSplashAd!) {
        dPrint("[GDTSplashAdDG]: splashAdWillClosed")
    }
    
    func splashAdLifeTime(_ time: UInt) {
        dPrint("[GDTSplashAdDG]: splashAdLifeTime:\(time)")
    }
    
    func splashAdExposured(_ splashAd: GDTSplashAd!) {
        dPrint("[GDTSplashAdDG]: splashAdExposured")
    }
    
    func splashAdClosed(_ splashAd: GDTSplashAd!) {
        dPrint("[GDTSplashAdDG]: splashAdClosed")
        tryResetRootVC()
    }
    
    func splashAdDidDismissFullScreenModal(_ splashAd: GDTSplashAd!) {
        dPrint("[GDTSplashAdDG]: splashAdDidDismissFullScreenModal")
    }
    
    func splashAdDidPresentFullScreenModal(_ splashAd: GDTSplashAd!) {
        dPrint("[GDTSplashAdDG]: splashAdDidPresentFullScreenModal")
    }
    
    func splashAdWillDismissFullScreenModal(_ splashAd: GDTSplashAd!) {
        dPrint("[GDTSplashAdDG]: splashAdWillDismissFullScreenModal")
    }
    
    func splashAdWillPresentFullScreenModal(_ splashAd: GDTSplashAd!) {
        dPrint("[GDTSplashAdDG]: splashAdWillPresentFullScreenModal")
    }
    
    func splashAdApplicationWillEnterBackground(_ splashAd: GDTSplashAd!) {
        dPrint("[GDTSplashAdDG]: splashAdApplicationWillEnterBackground")
    }
    
    func tryResetRootVC() {
        if let rvc = rootViewController{
            DispatchQueue.main.async {
                self.keyWindow?.rootViewController = rvc
                self.keyWindow?.makeKeyAndVisible()
                self.rootViewController = nil
                self.keyWindow = nil
            }
        }
    }
}

extension AdManager{
    static func addGDT() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.adManagerDidStart, object: nil, queue: nil) { (_) in
            dPrint("[AdManager] GDT Inited")
        }
        
        dPrint("[AdManager] Add GDT")
    }
    
    func gdtSplashAdLastPresentation() -> Date {
        return GDTSplashAdDG.instance.lastSplashPresented
    }
    
    func gdtShowSplash(window:UIWindow,fetchDelay:Int = 3,bottomView:UIView? = nil, launchScrBoardId:String = "LaunchScreen",vcId:String = "LaunchScreen") {
        guard let gdtc = GDTConfig.fromAdManagerList(),gdtc.enabled else {
            dPrint("[AdManager] GDT Is Disable")
            return
        }
        
        guard !String.isNullOrWhiteSpace(gdtc.appId)  else {
            dPrint("[AdManager] GDT App Is Empty")
            return
        }
        
        guard !String.isNullOrWhiteSpace(gdtc.splashId)  else {
            dPrint("[AdManager] GDT SplashAd ID Is Empty")
            return
        }
        
        guard !AdManager.hasNoAdsPrivilege else {
            return
        }
        
        gdtSetLaunchScreenBackground(window: window, launchScrBoardId: launchScrBoardId, vcId: vcId)
        configureGDTAndShowSplashAd(window: window, bottomView: bottomView, fetchDelay: fetchDelay)
    }
    
    private func gdtSetLaunchScreenBackground(window:UIWindow,launchScr:UIViewController) {
        window.makeKeyAndVisible()
        if let rootVC = window.rootViewController{
            GDTSplashAdDG.instance.splashAdLoaded = false
            GDTSplashAdDG.instance.rootViewController = rootVC
            GDTSplashAdDG.instance.keyWindow = window
            launchScr.modalPresentationStyle = .fullScreen
            window.rootViewController = launchScr
            window.makeKeyAndVisible()
        }
    }
    
    private func gdtSetLaunchScreenBackground(window:UIWindow,launchScrBoardId:String = "LaunchScreen",vcId:String = "LaunchScreen"){
        let launchScrVC = UIViewController.instanceFromStoryBoard(launchScrBoardId, identifier: vcId)
        gdtSetLaunchScreenBackground(window: window, launchScr: launchScrVC)
    }
    
    private func configureGDTAndShowSplashAd(window:UIWindow,bottomView:UIView?,fetchDelay:Int) {
        guard let config = GDTConfig.fromAdManagerList(),let splashId = config.splashId,let appId = config.appId,let splashAd = GDTSplashAd(appId: appId, placementId: splashId) else {
            GDTSplashAdDG.instance.tryResetRootVC()
            return
        }
        GDTSplashAdDG.instance.splash = splashAd
        GDTSplashAdDG.instance.splashAdLoaded = false
        splashAd.fetchDelay = fetchDelay
        splashAd.delegate = GDTSplashAdDG.instance
        if bottomView == nil{
            splashAd.loadAndShow(in: window)
        }else{
            GDTSplashAdDG.instance.splashBottomView = bottomView
            splashAd.loadAndShow(in: window, withBottomView: bottomView)
        }
        
    }
    
    private func configureGDTAndShowSplashAd(window:UIWindow,bottomLogo:UIImage,fetchDelay:Int) {
        let logo = UIImageView(image:bottomLogo)
        logo.contentMode = .center
        let bottomView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 100))
        bottomView.addSubview(logo)
        logo.center = bottomView.center
        bottomView.backgroundColor = UIColor.white
        configureGDTAndShowSplashAd(window:window,bottomView:bottomView,fetchDelay:fetchDelay)
    }
    
}
