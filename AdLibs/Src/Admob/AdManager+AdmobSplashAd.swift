//
//  AdmobSplashAd.swift
//  notouchphonealarm
//
//  Created by AlexChow on 2020/11/19.
//  Copyright © 2020 Bahamut. All rights reserved.
//

import Foundation
import GoogleMobileAds

fileprivate class AdmobAppOpenAdManager:NSObject,GADFullScreenContentDelegate{
    static let admobInitDelay = 2
    static let shared = AdmobAppOpenAdManager()
    private var appOpenAd:GADAppOpenAd?
    
    private var lastSplashPresented = Date(timeIntervalSince1970: 0)
    private var splashCancelDate = Date(timeIntervalSince1970: 0)
    private var cachedRootVc:UIViewController!
    private var cachedKeyWindow:UIWindow!
    
    private var checkAdLoadedTimer:Timer?
    
    private var appStartAdCalled = false
    private var canPresentResumeAd = false
    private var didEnterBackgroundOnce = false
    
    private var resumeAdMinInterval:TimeInterval = -1
    private var resumeAdWindow:UIWindow!
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        self.lastSplashPresented = Date()
        dPrint("[AdmobAppOpenAdManager] Splash Ad Will Present")
    }
    
    /*
    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        self.lastSplashPresented = Date()
        dPrint("[AdmobAppOpenAdManager] Splash Ad Did Presented")
    }*/
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        dPrint("[AdmobAppOpenAdManager] Splash Ad adDidDismissFullScreenContent")
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        dPrint("[AdmobAppOpenAdManager] Splash Ad didFailToPresentFullScreenContentWithError")
    }
    
    private func requestAppOpenAd() -> Bool{
        self.appOpenAd = nil
        if let config = AdmobConfig.fromAdManagerList(),config.enabled ,let adUnitId = config.splashId{
            let req = GADRequest()
            
            GADAppOpenAd.load(withAdUnitID: adUnitId, request: req, orientation: UIInterfaceOrientation.unknown) { (openAd, error) in
                if let err = error{
                    dPrint("[AdmobAppOpenAdManager] Load OpenAd Error:\(err.localizedDescription)")
                }else{
                    self.appOpenAd = openAd
                    self.appOpenAd?.fullScreenContentDelegate = self
                    dPrint("[AdmobAppOpenAdManager] OpenAd Loaded")
                }
            }
            return true
            
        }else{
            return false
        }
    }
    
    private func tryPresentAppOpenAd(rootVC:UIViewController) -> Bool {
        if let ad = self.appOpenAd {
            self.appOpenAd = nil
            ad.present(fromRootViewController: rootVC)
            _ = requestAppOpenAd()
            return true
        }else{
            _ = requestAppOpenAd()
            return false
        }
        
    }
    
    func getSplashAdLastPresentation() -> Date {
        return lastSplashPresented
    }
    
    func setupAppResumeAd(mainWindow:UIWindow,adMinTimeInterval:TimeInterval) {
        let notSetup = self.resumeAdWindow == nil
        
        self.resumeAdWindow = mainWindow
        self.resumeAdMinInterval = adMinTimeInterval
        
        if notSetup {
            NotificationCenter.default.addObserver(self, selector: #selector(onAppResume), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(onEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
    }
    
    func enableAppResumeAd(enabled:Bool) {
        canPresentResumeAd = enabled
        dPrint("[AdmobAppOpenAdManager] Resume Ad Enabled:\(enabled)")
    }
    
    @objc private func onEnterBackground(n:Notification){
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        didEnterBackgroundOnce = true
        dPrint("[AdmobAppOpenAdManager] Resume Ad EnterBackgroundOnce:\(didEnterBackgroundOnce)")
    }
    
    @objc private func onAppResume(n:Notification){
        if didEnterBackgroundOnce && canPresentResumeAd,let vc = self.resumeAdWindow?.rootViewController {
            let adDuration = Date().timeIntervalSince1970 - getSplashAdLastPresentation().timeIntervalSince1970
            if adDuration > resumeAdMinInterval {
                _ = tryPresentAppOpenAd(rootVC: vc)
            }else{
                dPrint("[AdmobAppOpenAdManager] Ad Duration Limited:\(adDuration) < \(resumeAdMinInterval)")
            }
        }
    }
    
    func showAppStartSplashAd(window:UIWindow,fetchDelay:Int = 3, launchScrBoardId:String = "LaunchScreen",vcId:String = "LaunchScreen") {
        
        if appStartAdCalled {
            dPrint("[AdmobAppOpenAdManager] App Start Splash Ad Can Only Call Onece")
            return
        }
        
        appStartAdCalled = true
        
        guard !AdManager.hasNoAdsPrivilege else {
            return
        }
        
        guard let admobconfig = AdmobConfig.fromAdManagerList(),admobconfig.enabled else {
            dPrint("[AdmobAppOpenAdManager] Admob Is Disable")
            return
        }
        
        guard !String.isNullOrWhiteSpace(admobconfig.appId)  else {
            dPrint("[AdmobAppOpenAdManager] Admob App Is Empty")
            return
        }
        
        guard !String.isNullOrWhiteSpace(admobconfig.splashId)  else {
            dPrint("[AdmobAppOpenAdManager] Admob SplashAd ID Is Empty")
            return
        }
        
        if AdManager.isAdmobInited() {
            if let _ = self.appOpenAd {
                if let vc = window.rootViewController{
                    _ = self.tryPresentAppOpenAd(rootVC:  vc)
                }
            }else if self.requestAppOpenAd(){
                cacheKeyWindowAndVC(window: window)
                splashCancelDate = Date().addSeconds(TimeInterval(fetchDelay))
                self.checkAdLoadedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: timerTick)
            }
        }else{
            dPrint("[AdmobAppOpenAdManager] Admob Is Not Ready, Waiting Admob Ready")
            cacheKeyWindowAndVC(window: window)
            setLaunchScreenBackground(window: window, launchScrBoardId: launchScrBoardId, vcId: vcId)
            splashCancelDate = Date().addSeconds(TimeInterval(fetchDelay + AdmobAppOpenAdManager.admobInitDelay))
            self.checkAdLoadedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: timerTickAdmobIniting)
        }
        
    }
    
    private func timerTickAdmobIniting(timer:Timer){
        if Date().timeIntervalSince1970 > self.splashCancelDate.timeIntervalSince1970{
            timer.invalidate()
            self.checkAdLoadedTimer = nil
            self.tryResetRootVC()
        }else if AdManager.isAdmobInited(){
            
            timer.invalidate()
            self.checkAdLoadedTimer = nil
            if self.requestAppOpenAd(){
                dPrint("[AdmobAppOpenAdManager] Admob Is Ready, Start Loading SplashAd")
                self.checkAdLoadedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: timerTick)
            }else{
                self.tryResetRootVC()
            }
        }
    }
    
    private func timerTick(timer:Timer){
        if Date().timeIntervalSince1970 > self.splashCancelDate.timeIntervalSince1970{
            timer.invalidate()
            self.checkAdLoadedTimer = nil
            self.tryResetRootVC()
        }else if let _ = self.appOpenAd{
            timer.invalidate()
            self.checkAdLoadedTimer = nil
            if let wd = self.cachedKeyWindow,let vc = self.cachedRootVc {
                clearCacheKeyWindowAndVC()
                wd.rootViewController = vc
                _ = tryPresentAppOpenAd(rootVC: vc)
            }
        }
    }
    
    private func cacheKeyWindowAndVC(window:UIWindow){
        self.cachedKeyWindow = window
        self.cachedRootVc = window.rootViewController
    }
    
    private func clearCacheKeyWindowAndVC(){
        self.cachedRootVc = nil
        self.cachedKeyWindow = nil
    }
    
    private func setLaunchScreenBackground(window:UIWindow,launchScr:UIViewController) {
        launchScr.modalPresentationStyle = .fullScreen
        window.rootViewController = launchScr
        window.makeKeyAndVisible()
    }
    
    private func setLaunchScreenBackground(window:UIWindow,launchScrBoardId:String = "LaunchScreen",vcId:String = "LaunchScreen"){
        let launchScrVC = UIViewController.instanceFromStoryBoard(launchScrBoardId, identifier: vcId)
        setLaunchScreenBackground(window: window, launchScr: launchScrVC)
    }
    
    private func tryResetRootVC() {
        if let window = cachedKeyWindow ,let rvc = cachedRootVc{
            clearCacheKeyWindowAndVC()
            DispatchQueue.main.async {
                window.rootViewController = rvc
                window.makeKeyAndVisible()
            }
        }
    }
}

extension AdManager{
    func admobTryShowAppStartSplashAd(window:UIWindow,fetchDelay:Int = 3, launchScrBoardId:String = "LaunchScreen",vcId:String = "LaunchScreen") {
        AdmobAppOpenAdManager.shared.showAppStartSplashAd(window: window, fetchDelay: fetchDelay, launchScrBoardId: launchScrBoardId, vcId: vcId)
    }
    
    func admobSetupAppResumeAd(mainWindow:UIWindow, adMinTimeInterval:TimeInterval,enabled:Bool) {
        AdmobAppOpenAdManager.shared.setupAppResumeAd(mainWindow: mainWindow, adMinTimeInterval: adMinTimeInterval)
        AdmobAppOpenAdManager.shared.enableAppResumeAd(enabled: enabled)
    }
    
    func admobEnableAppResumeAd(enabled:Bool) {
        AdmobAppOpenAdManager.shared.enableAppResumeAd(enabled: enabled)
    } 
}
