//
//  Admob+UnityAds.swift
//  tum3rd
//
//  Created by Alex Chow on 2019/11/4.
//  Copyright © 2019 Tumblreader. All rights reserved.
//
//pod 'GoogleMobileAdsMediationUnity'
import Foundation
import UnityAdapter
import UnityAds

extension AdManager {
    func setupAdmobMediationUnityAds() {        
        if let config = AdmobConfig.fromAdManagerList(),config.gdpr{
            let data = UADSMetaData()
            data.setValue(config.gdpr, forKey: "gdpr.consent")
            data.commit()
        }
    }
}
