//
//  AdmobBanner+UIViewController.swift
//  tum3rd
//
//  Created by Alex Chow on 2019/11/4.
//  Copyright © 2019 Tumblreader. All rights reserved.
//

import Foundation
import GoogleMobileAds

private var bannerAds = [String: GADBannerView?]()
extension UIViewController {
    
    private func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.adUnitID = AdmobConfig.fromAdManagerList()?.bannerId
        bannerView.rootViewController = self
        bannerView.delegate = AdmobBannerDG.shared
        bannerAds[self.description] = bannerView
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: bottomLayoutGuide,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
        ])
        bannerView.load(GADRequest())
    }
    
    func admobTryLoadBannerAdOnViewDidAppear() {
        if AdManager.hasNoAdsPrivilege || !AdManager.isAdmobEnabled() {
            if let banner = bannerAds.removeValue(forKey: self.description) {
                banner?.removeFromSuperview()
            }
        } else if !bannerAds.keys.contains(self.description) {
            bannerAds[self.description] = nil
            // In this case, we instantiate the banner with desired ad size.
            let bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
            addBannerViewToView(bannerView)
        }
    }

    func admobTryCloseBannerAdOnViewControllerDeinit() {
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

private class AdmobBannerDG: NSObject,GADBannerViewDelegate {
    static let shared = AdmobBannerDG()
    
    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        bannerAds.removeValue(forKey: self.description)
    }
    
}
