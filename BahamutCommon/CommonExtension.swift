//
//  CommonExtension.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/26.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

extension UIDevice {
    static func isSimulator() -> Bool {
        return TARGET_IPHONE_SIMULATOR == Int32("1")
    }

    static func isHeadPhoneInserted(includeBluetooth: Bool = true) -> Bool {
        for desc in AVAudioSession.sharedInstance().currentRoute.outputs {
            var ports = [convertFromAVAudioSessionPort(AVAudioSession.Port.headphones)]
            if includeBluetooth {
                ports.append(contentsOf: [convertFromAVAudioSessionPort(AVAudioSession.Port.bluetoothLE), convertFromAVAudioSessionPort(AVAudioSession.Port.bluetoothA2DP), convertFromAVAudioSessionPort(AVAudioSession.Port.bluetoothHFP)])
            }
            return ports.contains(convertFromAVAudioSessionPort(desc.portType))
        }
        return false
    }

    // 4s Or Older
    static func isSmallScreenDevice() -> Bool {
        let size = UIScreen.main.bounds
        return max(size.width, size.height) < 568
    }

    static func isIPadDevice() -> Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }

    static func isIPhoneDevice() -> Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionPort(_ input: AVAudioSession.Port) -> String {
    return input.rawValue
}

typealias NoParamsHandler = ()->Void

func debugLog(_ format: String, _ args: CVarArg...) {
    #if DEBUG
    print("\(Date().toAccurateDateTimeString()): \(String(format: format, arguments: args))")
    #endif
}

func dPrint(_ item: @autoclosure () -> Any) {
    #if DEBUG
    print(item())
    #endif
}
