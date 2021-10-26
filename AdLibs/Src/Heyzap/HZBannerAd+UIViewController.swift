//
//  HZBannerAd+UIViewController.swift
//  AdManager
//
//  Created by Alex Chow on 2018/10/16.
//  Copyright © 2018 tum3rd. All rights reserved.
//

import Foundation

// MARK: Ad

private var bannerAds = [String: HZBannerAd?]()
extension UIViewController {
    func heyzapTryLoadBannerAdOnViewDidAppear() {
        if AdManager.hasNoAdsPrivilege || !AdManager.isHeyzapEnabled() {
            if let banner = bannerAds.removeValue(forKey: self.description) {
                banner?.removeFromSuperview()
            }
        } else if !bannerAds.keys.contains(self.description) {
            bannerAds[self.description] = nil
            let options = HZBannerAdOptions()
            HZBannerAd.placeBanner(in: self.view, position: .bottom, options: options, delegate: HZBannerDG(), success: { (banner) in
                if !AdManager.hasNoAdsPrivilege,let b = banner {
                    bannerAds[self.description] = b
                } else {
                    banner?.removeFromSuperview()
                    bannerAds.removeValue(forKey: self.description)
                }
            }) { (err) in
                #if DEBUG
                if let e = err {
                    dPrint(e)
                }
                #endif
            }
        }
    }

    func heyzapTryCloseBannerAdOnViewControllerDeinit() {
        if let banner = bannerAds.removeValue(forKey: self.description) {
            banner?.removeFromSuperview()
        }
    }
    
    func removeAllBannerAd() {
        for kv in bannerAds {
            kv.value?.removeFromSuperview()
        }
        
        bannerAds.removeAll()
    }
}

private class HZBannerDG: NSObject,HZBannerAdDelegate {}
