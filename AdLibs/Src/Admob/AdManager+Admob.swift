//
//  AdManager+Admob.swift
//  tum3rd
//
//  Created by Alex Chow on 2019/11/4.
//  Copyright © 2019 Tumblreader. All rights reserved.
//
import Foundation
import GoogleMobileAds


extension Notification.Name{
    
    static let admobFullScreenAdDidReceived = Notification.Name(rawValue: "admobFullScreenAdDidReceived")
    static let admobFullScreenAdFailedToReceive = Notification.Name(rawValue: "admobFullScreenAdFailedToReceive")
    static let admobFullScreenAdDidRecordImpression = Notification.Name(rawValue: "admobFullScreenAdDidRecordImpression")
    static let admobFullScreenAdWillPresent = Notification.Name(rawValue: "admobFullScreenAdWillPresent")
    static let admobFullScreenAdDidFailToPresent = Notification.Name(rawValue: "admobFullScreenAdDidFailToPresent")
    static let admobFullScreenAdDidDismiss = Notification.Name(rawValue: "admobFullScreenAdDidDismiss")
    
    static let admobDidInited = Notification.Name(rawValue: "admobDidInited")
}

class AdmobConfig {
    var enabled:Bool = true
    var appId:String!
    var bannerId:String!
    var staticId:String!
    var videoId:String!
    var rewardedId:String!
    var irewardedId:String!
    var nativeId:String!
    var splashId:String!
    var splashInterval:TimeInterval = 30
    var gdpr:Bool = true
}

private var admobEnabled = false
private var admobInited = false

extension AdmobConfig{
    static func fromAdManagerList()->AdmobConfig?{
        if let url = AdManager.localConfigURLIfExists,let dict = NSDictionary(contentsOf: url)?.value(forKey: "Admob") as? NSDictionary{
            
            let config = AdmobConfig()
            config.enabled = dict["Enabled"] as? Bool ?? true
            config.appId = dict["AppId"] as? String
            config.bannerId = dict["BannerId"] as? String
            config.staticId = dict["StaticId"] as? String
            config.videoId = dict["VideoId"] as? String
            config.rewardedId = dict["RewardedId"] as? String
            config.irewardedId = dict["IRewardedId"] as? String
            config.nativeId = dict["NativeId"] as? String
            config.splashId = dict["SplashId"] as? String
            config.splashInterval = (dict["SplashInterval"] as? TimeInterval) ?? 30
            config.gdpr = dict["GDPR"] as? Bool ?? true
            
            if String.isNullOrWhiteSpace(config.appId){
                return nil
            }else{
                return config
            }
            
        }else{
            return nil
        }
    }
}

extension AdManager{
    static func addAdmob() {
        NotificationCenter.default.addObserver(forName: .adManagerDidStart, object: nil, queue: nil) { (_) in
            initAdmob()
        }
        
        NotificationCenter.default.addObserver(forName: .adManagerConfigDidUpdated, object: nil, queue: nil) { (_) in
            if let config = AdmobConfig.fromAdManagerList(){
                if admobEnabled && !config.enabled{
                    dPrintMessage("Admob Is Disabled")
                    admobEnabled = false
                }else if admobEnabled && config.enabled{
                    initAdmob()
                }
            }
        }
        
        dPrintMessage("Add Admob")
    }
    
    static func isAdmobEnabled() -> Bool{
        return admobEnabled
    }
    
    static func isAdmobInited() -> Bool{
        return admobInited
    }
    
    static func initAdmob(){
        if let config = AdmobConfig.fromAdManagerList(){
            if config.enabled{
                admobEnabled = true
                admobInited = false
                GADMobileAds.sharedInstance().start { (status) in
                    admobInited = true
                    NotificationCenter.default.post(Notification(name: .admobDidInited, object: nil, userInfo: nil))
                    dPrintMessage("Admob inited")
                }
            }else{
                admobEnabled = false
                dPrintMessage("Admob Is Disable")
            }
        }else{
            admobEnabled = false
            dPrintMessage("Admob Config Not Exists")
        }
    }
}

