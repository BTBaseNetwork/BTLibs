//
//  AdManager+Config.swift
//  AdManager
//
//  Created by Alex Chow on 2018/12/4.
//  Copyright © 2018 btbase. All rights reserved.
//

import Foundation

extension Notification.Name{
    static var adManagerConfigDidUpdated:Notification.Name{ return Notification.Name(rawValue: "adManagerConfigDidUpdated") }
}

extension AdManager{
//    private static var remoteConfigUrl:URL?{
//        if let bundleId = Bundle.main.bundleIdentifier{
//            return URL(string: "http://staticres.qncdn.btbase.mobi/adconfigs/\(bundleId).plist")!
//        }
//        return nil
//    }
    
    private static var embededConfigUrl:URL?{ return Bundle.main.url(forResource: "AdManager", withExtension: "plist") }
    static var localConfigPath:String{
        let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        return "\(dir)/AdManager.plist"
    }
    
    static var localConfigURL:URL{
        return URL(fileURLWithPath: localConfigPath)
    }
    
    static var localConfigURLIfExists:URL?{
        if FileManager.default.fileExists(atPath: localConfigPath){
            return localConfigURL
        }else{
            return nil
        }
    }
    
    static func initConfig() {
        if !FileManager.default.fileExists(atPath: localConfigPath),let embeded = embededConfigUrl {
            do{
                try FileManager.default.copyItem(at: embeded, to: localConfigURL)
                dPrint("[AdManager] Copy Embeded Config To Local Config")
            }catch let err{
                dPrint("[AdManager] Init Config:\(err.localizedDescription)")
            }
        }
    }
    
    static func fetchRemoteConfig(timeoutDays:Int = 1) {
        var url:URL!
        
        if let localConfigUrl = AdManager.localConfigURLIfExists,let dict = NSDictionary(contentsOf: localConfigUrl)?.value(forKey: "OnlineConfig") as? NSDictionary{
            if let onlinrUrlstr = dict["Url"] as? String,!String.isNullOrWhiteSpace(onlinrUrlstr){
                url = URL(string: onlinrUrlstr)
            }else{
                dPrint("[AdManager] OnlineConfig Url Is Empty")
                return
            }
        }else{
            dPrint("[AdManager] OnlineConfig Is None")
            return
        }
        
        if let attrs = try? FileManager.default.attributesOfItem(atPath: localConfigURL.path){
            if let date = (attrs[FileAttributeKey.modificationDate] ?? attrs[FileAttributeKey.creationDate]) as? Date{
                if date.timeIntervalSinceNow < TimeInterval(timeoutDays * 3600 * 24){
                    dPrint("[AdManager] Local config is not timeout")
                    return
                }
            }
        }
        
        URLSession(configuration: URLSessionConfiguration.default).dataTask(with: url) { data, response, error in
            if error == nil,let res = response as? HTTPURLResponse,res.statusCode >= 200 && res.statusCode < 300, let resultData = data {
                do{
                    try resultData.write(to: localConfigURL, options: Data.WritingOptions.atomicWrite)
                    NotificationCenter.default.post(name: .adManagerConfigDidUpdated, object: nil)
                    dPrint("[AdManager] Local config updated with remote config")
                }catch let err{
                    dPrint("[AdManager] Can't write remote config to local:\(err.localizedDescription)")
                }
            } else {
                dPrint("[AdManager] Can't read remote config")
            }
        }.resume()
    }
}
