//
//  Bahamut
//
//  Created by AlexChow on 15/9/6.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit

// MARK: NoStatusBarViewController

class NoStatusBarViewController: UIViewController {
    open override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: instanceFromStoryBoard

extension UIViewController {
    static func instanceFromStoryBoard(_ storyBoardName: String, identifier: String, bundle: Bundle = Bundle.main) -> UIViewController {
        let storyBoard = UIStoryboard(name: storyBoardName, bundle: bundle)
        return storyBoard.instantiateViewController(withIdentifier: identifier)
    }
}

//MARK: Orientation

class ForcePortraitNavController: UINavigationController {
    override var shouldAutorotate: Bool { return false }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { return .portrait }
}

@objc
protocol OrientationsNavigationController {
    func supportedViewOrientations() -> UIInterfaceOrientationMask
}

class UIOrientationsNavigationController: UINavigationController, OrientationsNavigationController {
    var lockOrientationPortrait: Bool = false
    func supportedViewOrientations() -> UIInterfaceOrientationMask {
        if lockOrientationPortrait {
            return UIInterfaceOrientationMask.portrait
        }
        return UIInterfaceOrientationMask.all
    }
}

extension UIViewController {
    func setOverCurrentContext() {
        modalPresentationStyle = .overCurrentContext
        providesPresentationContextTransitionStyle = true
        definesPresentationContext = true
    }
}

//MARK: UIViewController + topViewController
extension UIViewController {
    
    static func topViewController(_ viewController: UIViewController? = nil) -> UIViewController? {
        let viewController = viewController ?? UIApplication.shared.keyWindow?.rootViewController
        
        if let navigationController = viewController as? UINavigationController,
            !navigationController.viewControllers.isEmpty
        {
            return self.topViewController(navigationController.viewControllers.last)
            
        } else if let tabBarController = viewController as? UITabBarController,
            let selectedController = tabBarController.selectedViewController
        {
            return self.topViewController(selectedController)
            
        } else if let presentedController = viewController?.presentedViewController {
            return self.topViewController(presentedController)
            
        }
        
        return viewController
    }
}
