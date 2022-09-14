//
//  AdManager.swift
//  AdManager
//
//  Created by Alex Chow on 2018/10/18.
//  Copyright © 2018 tum3rd. All rights reserved.
//

import Foundation
import AdSupport
import AppTrackingTransparency

let fetchNativeCount: UInt = 3

extension Notification.Name{
    static var adManagerDidStart:Notification.Name{ return Notification.Name(rawValue: "adManagerDidStart") }
}

class AdManager: NSObject {
    
    static var hasNoAdsPrivilege:Bool{
        get{ return UserSetting.isSettingEnable("hasNoAdsPrivilege") }
        set{ UserSetting.setSetting("hasNoAdsPrivilege", enable: newValue) }
    }
    
    static var advertisingId:String{
        return "\(ASIdentifierManager.shared().advertisingIdentifier.uuidString)"
    }
    
    static var advertisingIdMD5:String{
        return "\(advertisingId.md5)"
    }
    
    private(set) static var shared = AdManager()

    static func start() {
        #if DEBUG
        dPrintMessage("[AdManager] AdIdentifier:\(advertisingId)")
        dPrintMessage("[AdManager] AdIdentifierMd5:\(advertisingIdMD5)")
        #endif
        if #available(iOS 14, *) {
            //Request IDFA
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                // Tracking authorization completed. Start loading ads here.
                // loadAd()
                initConfig()
                NotificationCenter.default.post(name: .adManagerDidStart, object: nil)
            })
        } else {
            // Fallback on earlier versions
            initConfig()
            NotificationCenter.default.post(name: .adManagerDidStart, object: nil)
        }
        

    }
    
    static func dPrintMessage(_ message:String?) {
        dPrint("[AdManager] \(message ?? "Empty Message")")
    }
}
