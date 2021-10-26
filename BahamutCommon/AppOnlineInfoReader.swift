//
//  AppOnlineInfoReader.swift
//  AppOnlineInfoReader
//
//  Created by Alex Chow on 2018/11/29.
//  Copyright © 2018 btbase. All rights reserved.
//

import Foundation

class AppOnlineInfoReader {
    
    private static var mAppDetail:NSDictionary!
    
    private static var appDetailPersistentFilePath:String{
        let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        return "\(dir)/appOnlineInfo.plist"
    }
    
    static var onlineInfoUpdateDate:Date?{
        if let attrs = try? FileManager.default.attributesOfItem(atPath: appDetailPersistentFilePath){
            if let d = (attrs[.modificationDate] ?? attrs[.creationDate]) as? Date{
                return d
            }
        }
        return nil
    }
    
    private(set) static var onlineAppDetail:NSDictionary?{
        get{
            if mAppDetail == nil{
                mAppDetail = NSDictionary(contentsOfFile: appDetailPersistentFilePath)
            }
            return mAppDetail
        }
        
        set{
            if let nv = newValue{
                DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
                    if nv.write(toFile: appDetailPersistentFilePath, atomically: true){
                        mAppDetail = nv
                        #if DEBUG
                        dPrint("[AppOnlineInfoReader] New Online App Detail Wrote, Online Version:\(onlineVersion)")
                        #endif
                    }else{
                        #if DEBUG
                        dPrint("[AppOnlineInfoReader] Write New Online App Detail Error")
                        #endif
                    }
                }
            }
        }
    }
    
    private static var cachedAppVersion: String {
        
        get{
            return UserDefaults.standard.string(forKey: "AppOnlineInfoReader_cachedAppVersion") ?? "0"
        }
        
        set{
            UserDefaults.standard.set(newValue, forKey: "AppOnlineInfoReader_cachedAppVersion")
        }
    }
    
    static var appVersion: String {
        if let infoDic = Bundle.main.infoDictionary {
            let version = infoDic["CFBundleShortVersionString"] as! String
            return version
        }
        return "1.0"
    }
    
    static var buildVersion: Int {
        if let infoDic = Bundle.main.infoDictionary {
            let version = infoDic["CFBundleVersion"] as! String
            return Int(version) ?? 1
        }
        return 1
    }
    
    
    static var onlineVersion: String {
        get {
            return onlineAppDetail?["version"] as? String ?? "0"
        }
    }
    
    static var appStoreItemId: String? {
        get {
            if let appItemId = onlineAppDetail?["trackId"] as? Int64{
                return "\(appItemId)"
            }
            return nil
        }
    }
    
    static var developerId: String? {
        get {
            if let id = onlineAppDetail?["artistId"] as? Int64{
                return "\(id)"
            }
            return nil
        }
    }
    
    static var isCurrentVersionNewer:Bool{
        return compareVersion(versionA: appVersion, versionB: onlineVersion) > 0
    }
    
    static var isOnlineVersionNewer:Bool{
        return compareVersion(versionA: onlineVersion, versionB: appVersion) > 0
    }
    
    static var isCurrentVersionOnline:Bool{
        return compareVersion(versionA: appVersion, versionB: onlineVersion) == 0
    }
    
    static func compareVersion(versionA:String,versionB:String) -> Int{
        let verAComps = versionA.components(separatedBy: ".").map{Int.from(hexString: $0)!}
        let verBComps = versionB.components(separatedBy: ".").map{Int.from(hexString: $0)!}
        
        for i in 0..<min(verAComps.count,verBComps.count) {
            if verAComps[i] > verBComps[i] {
                return 1
            }else if verAComps[i] < verBComps[i]{
                return -1
            }
        }
        
        if verAComps.count > verBComps.count{
            return 1
        }else if verBComps.count > verAComps.count{
            return -1
        }
        
        return 0
    }
    
    private(set) static var isAppUpdatedFromLastLaunch = false
    
    static func start(timeoutDays:Int = 7){
        
        if compareVersion(versionA: cachedAppVersion, versionB: appVersion) < 0 {
            #if DEBUG
            dPrint("[AppOnlineInfoReader] App Updated")
            #endif
            isAppUpdatedFromLastLaunch = true
        }
        
        cachedAppVersion = appVersion
        
        if isAppUpdatedFromLastLaunch || isCurrentVersionNewer{
            updateOnlineBuildVersion()
        }else if let ud = onlineInfoUpdateDate{
            let lastUpdateDaysToNow = abs(ud.timeIntervalSinceNow) / 3600 / 24
            if lastUpdateDaysToNow > Double(timeoutDays){
                updateOnlineBuildVersion()
            }else{
                #if DEBUG
                dPrint("[AppOnlineInfoReader] No Need For Update Online Info, Last Update Date:\(ud.description)")
                #endif
            }
        }else{
            updateOnlineBuildVersion()
        }
    }
    
    static func updateOnlineBuildVersion() {
        guard let bundleId = Bundle.main.bundleIdentifier,let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            return
        }

        URLSession(configuration: URLSessionConfiguration.default).dataTask(with: url) { data, _, error in
            if error == nil, let resultData = data {
                do{
                    let jobj = try JSONSerialization.jsonObject(with: resultData, options: JSONSerialization.ReadingOptions(rawValue: 0))
                    if let dict = jobj as? NSDictionary,let resultCount = dict["resultCount"] as? Int, resultCount > 0,let results = dict["results"] as? [NSDictionary]{
                        
                        for (_,appDetail) in results.enumerated(){
                            if let itemBundleId = appDetail["bundleId"] as? String, bundleId == itemBundleId {
                                onlineAppDetail = appDetail
                                break
                            }
                        }
                    }else{
                        #if DEBUG
                        dPrint("[AppOnlineInfoReader] App Bundle Id Not Found")
                        #endif
                    }
                }catch let err{
                    #if DEBUG
                    dPrint("[AppOnlineInfoReader] Download App Detail Error:\(err.localizedDescription)")
                    #endif
                }
            } else {
                #if DEBUG
                dPrint("[AppOnlineInfoReader] Can't read online build version")
                #endif
            }
            }.resume()
    }
}

extension Int{
    static func from(hexString:String) -> Int?{
        var sum = 0
        // 整形的 utf8 编码范围
        let intRange = 48...57
        // 小写 a~f 的 utf8 的编码范围
        let lowercaseRange = 97...102
        // 大写 A~F 的 utf8 的编码范围
        let uppercasedRange = 65...70
        for c in hexString.utf8CString {
            var intC = Int(c.byteSwapped)
            if intC == 0 {
                break
            } else if intRange.contains(intC) {
                intC -= 48
            } else if lowercaseRange.contains(intC) {
                intC -= 87
            } else if uppercasedRange.contains(intC) {
                intC -= 55
            } else {
                return nil
            }
            sum = sum * 16 + intC
        }
        return sum
    }
}
