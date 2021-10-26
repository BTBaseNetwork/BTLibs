//
//  StoreKitHelper.swift
//  ibeauty
//
//  Created by Alex Chow on 2018/11/29.
//  Copyright © 2018 btbase. All rights reserved.
//

import Foundation
import StoreKit

class StoreKitHelper : NSObject,SKStoreProductViewControllerDelegate{
    
    static private var shared = StoreKitHelper()
    
    static func showProductViewController(rootVC:UIViewController, itunesItemId:String) {
        let vc = SKStoreProductViewController()
        vc.delegate = StoreKitHelper.shared
        rootVC.present(vc, animated: true) {
            vc.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier:itunesItemId], completionBlock: nil)
        }
    }
    
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
