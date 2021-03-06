//
//  LocaleExtensions.swift
//  BTBaseSDK
//
//  Created by Alex Chow on 2018/6/5.
//  Copyright © 2018年 btbase. All rights reserved.
//

import Foundation
public extension Locale {
    public static var preferredLangCode: String {
        let lang = Locale.preferredLanguages[0]
        if #available(iOS 9.0, *) {
            if let index = lang.range(of: "-", options: .backwards, range: nil, locale: nil)?.lowerBound {
                return String(lang[..<index])
            }
            return lang
        } else {
            return lang
        }
    }
    
    public static var preferredLangCodeUnderlined: String {
        return preferredLangCode.replacingOccurrences(of: "-", with: "_")
    }
    
    public static var isRegionChina: Bool {
        return Locale.current.regionCode!.lowercased() == "cn"
    }
    
    public static var isRegionUS: Bool {
        return Locale.current.regionCode!.lowercased() == "us"
    }
}
