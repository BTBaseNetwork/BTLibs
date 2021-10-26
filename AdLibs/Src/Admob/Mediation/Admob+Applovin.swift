//
//  Admob+Applovin.swift
//  tum3rd
//
//  Created by Alex Chow on 2019/11/4.
//  Copyright © 2019 Tumblreader. All rights reserved.
//
//pod 'GoogleMobileAdsMediationAppLovin'
import Foundation
import AppLovinAdapter
import AppLovinSDK

extension AdManager {
    func setupAdmobMediationApplovin() {
        if let config = AdmobConfig.fromAdManagerList(),config.gdpr{
            ALPrivacySettings.setHasUserConsent(config.gdpr)
        }
    }
}
