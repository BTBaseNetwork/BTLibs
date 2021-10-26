//
//  HZInsertAd+UIViewController.swift
//  AdManager
//
//  Created by Alex Chow on 2018/11/29.
//  Copyright © 2018 btbase. All rights reserved.
//

import Foundation


extension UIViewController{
    func heyzapTryShowInsertAd(withTag tag:String?) -> Bool {
        guard !AdManager.hasNoAdsPrivilege && AdManager.isHeyzapEnabled() else {
            return false
        }
        
        let opt = HZShowOptions()
        opt.viewController = self
        opt.tag = tag
        if tag == nil ? HZVideoAd.isAvailable() : HZVideoAd.isAvailable(forTag: tag){
            HZVideoAd.show(with: opt)
            return true
        }else if tag == nil ? HZInterstitialAd.isAvailable() : HZInterstitialAd.isAvailable(forTag: tag){
            HZInterstitialAd.show(with: opt)
            return true
        }else{
            return false
        }
    }
    
    func heyzapTryShowInsertAd() -> Bool {
        return heyzapTryShowInsertAd(withTag: nil)
    }
}
