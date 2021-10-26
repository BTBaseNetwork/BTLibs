//
//  BahamutTextView.swift
//  Vessage
//
//  Created by Alex Chow on 2016/12/1.
//  Copyright © 2016年 Bahamut. All rights reserved.
//

import Foundation
import UIKit

class BahamutTextView: UITextView {
    var placeHolder: String? {
        didSet {
            placeHolderLabel?.text = placeHolder
        }
    }
    
    var limitedLength = 0

    fileprivate(set) var placeHolderLabel: UILabel? {
        didSet {
            placeHolderLabel?.text = placeHolder
            placeHolderLabel?.isHidden = !String.isNullOrEmpty(text)
            placeHolderLabel?.numberOfLines = 0
            NotificationCenter.default.addObserver(self, selector: #selector(BahamutTextView.onTextChanged(a:)), name: UITextView.textDidChangeNotification, object: self)
        }
    }

    override var text: String! {
        didSet {
            placeHolderLabel?.isHidden = !String.isNullOrEmpty(text)
        }
    }

    @objc func onTextChanged(a: Notification) {
        if let t = a.object as? BahamutTextView,t == self{
            placeHolderLabel?.isHidden = !String.isNullOrEmpty(text)
            if limitedLength > 0 && text.lengthOfBytes(using: .utf8) > limitedLength{
                text = String(text.prefix(limitedLength))
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var placeHolderTextAlign: NSTextAlignment = .left {
        didSet {
            placeHolderLabel?.textAlignment = placeHolderTextAlign
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if placeHolderLabel == nil {
            enablesReturnKeyAutomatically = true
            placeHolderLabel = UILabel()
            placeHolderLabel?.textColor = UIColor.lightGray
            addSubview(placeHolderLabel!)
        }
        placeHolderLabel?.textAlignment = placeHolderTextAlign
        placeHolderLabel?.font = font
        placeHolderLabel?.text = placeHolder
        placeHolderLabel?.frame = CGRect(x: 6, y: 8, width: bounds.size.width - 12, height: bounds.size.height - 12)
        placeHolderLabel?.sizeToFit()
    }
}
