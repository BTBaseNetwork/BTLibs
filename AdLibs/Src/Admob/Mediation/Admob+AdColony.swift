//
//  Admob+AdColony.swift
//  tum3rd
//
//  Created by Alex Chow on 2019/11/4.
//  Copyright © 2019 Tumblreader. All rights reserved.
//

//pod 'GoogleMobileAdsMediationAdColony'
import Foundation
import AdColonyAdapter

extension AdManager {
    func setupAdmobMediationAdColony() {
        if let config = AdmobConfig.fromAdManagerList(),config.gdpr,let option = GADMediationAdapterAdColony.appOptions{
            option.gdprRequired = config.gdpr
            option.gdprConsentString = "1"
        }
    }
}
