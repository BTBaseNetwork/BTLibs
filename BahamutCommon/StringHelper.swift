//
//  TestStringHelper.swift
//  Bahamut
//
//  Created by AlexChow on 15/8/2.
//  Copyright (c) 2015年 GStudio. All rights reserved.
//

import Foundation

extension String {
    func getRegexExpresstion(options: NSRegularExpression.Options = []) -> NSRegularExpression? {
        do {
            return try NSRegularExpression(pattern: self, options: options)
        } catch let err {
            dPrint(err)
        }
        return nil
    }
}

extension String {
    func makeNSRange() -> NSRange {
        let length = distance(from: startIndex, to: endIndex)
        let range = NSMakeRange(0, length)
        return range
    }

    func makeRange(range: NSRange) -> Range<String.Index> {
        let locationIndex = index(startIndex, offsetBy: range.location)
        let endIndex = index(locationIndex, offsetBy: range.length)
        return Range(uncheckedBounds: (lower: locationIndex, upper: endIndex))
    }
}

public class StringHelper {
    public static let httpUrlPattern = "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"

    public static func IntToLetter(_ letterIndex: Int) -> Character {
        return (Character(UnicodeScalar(letterIndex)!))
    }

    public static func IntToLetterString(_ letterIndex: Int) -> String {
        return "\(IntToLetter(letterIndex))"
    }

    public static func chineseToLatinLetters(words: String) -> String {
        let pinyin = NSMutableString(string: words)
        CFStringTransform(pinyin, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(pinyin, nil, kCFStringTransformStripCombiningMarks, false) // kCFStringTransformMandarinLatin带音标
        return pinyin.lowercased
    }

    public static func getResemblePY(originPY: String) -> String {
        return originPY.replacingOccurrences(of: "zh", with: "z")
            .replacingOccurrences(of: "ch", with: "c")
            .replacingOccurrences(of: "sh", with: "s")
            .replacingOccurrences(of: "ang", with: "an")
            .replacingOccurrences(of: "ing", with: "in")
            .replacingOccurrences(of: "eng", with: "en")
    }

    public static func getSimplifyURLAttributeString(origin: String, urlTips: String, attchLinkMark: Bool) -> (String?, [NSRange]?, [String]?) {
        var urls = [String]()

        if let regex = httpUrlPattern.getRegexExpresstion(options: NSRegularExpression.Options.caseInsensitive) {
            let arrayOfAllMatches = regex.matches(in: origin, options: [], range: origin.makeNSRange())
            for match in arrayOfAllMatches {
                let url = origin.substring(with: origin.makeRange(range: match.range))
                urls.append(url)
            }
        }

        if urls.count > 0 {
            var ranges = [NSRange]()
            let urlReplace = attchLinkMark ? "@#\(urlTips)" : "#\(urlTips)#"
            var result = origin.replacingOccurrences(of: httpUrlPattern, with: urlReplace, options: [.regularExpression, .caseInsensitive], range: nil)
            if let rgx = urlTips.getRegexExpresstion(options: NSRegularExpression.Options.caseInsensitive) {
                let matches = rgx.matches(in: result, options: [], range: result.makeNSRange())
                for mt in matches {
                    ranges.append(mt.range)
                }
            }
            result = result.replacingOccurrences(of: urlReplace, with: attchLinkMark ? "🔗\(urlTips)" : " \(urlTips) ")
            return (result, ranges, urls)
        }
        return (nil, nil, nil)
    }
}

public extension String {
    public func toUTF8EncodingData() -> Data! {
        return data(using: String.Encoding.utf8)
    }
}

public extension String {
    public static func isNullOrEmpty(_ value: String?) -> Bool {
        if let v = value {
            if v == "" {
                return true
            }
            return false
        } else {
            return true
        }
    }

    public static func isNullOrWhiteSpace(_ value: String?) -> Bool {
        if isNullOrEmpty(value) {
            return true
        } else {
            let v = value?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return isNullOrEmpty(v)
        }
    }
}

public extension String {
    public static func jsonStringWithDictionary(_ dict: NSDictionary) -> String? {
        do {
            let j = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            return String(data: j, encoding: String.Encoding.utf8)
        } catch {
            return nil
        }
    }

    public static func miniJsonStringWithDictionary(_ dict: NSDictionary) -> String? {
        do {
            let j = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions(rawValue: UInt(0)))
            return String(data: j, encoding: String.Encoding.utf8)
        } catch {
            return nil
        }
    }
}

public extension String {
    // 分割字符
    public func split(_ s: String) -> [String] {
        if s.isEmpty {
            var x = [String]()
            for y in self {
                x.append(String(y))
            }
            return x
        }
        return components(separatedBy: s)
    }

    // 去掉左右空格
    public func trim() -> String {
        return trimmingCharacters(in: CharacterSet.whitespaces)
    }

    // 是否包含字符串
    public func has(_ s: String) -> Bool {
        if range(of: s) != nil {
            return true
        } else {
            return false
        }
    }

    // 是否包含前缀
    public func hasBegin(_ s: String) -> Bool {
        if hasPrefix(s) {
            return true
        } else {
            return false
        }
    }

    // 是否包含后缀
    public func hasEnd(_ s: String) -> Bool {
        if hasSuffix(s) {
            return true
        } else {
            return false
        }
    }

    /*
     public func substringFromIndex(_ index:Int) -> String
     {
     return self.substring(from: self.characters.index(self.startIndex, offsetBy: index))
     }

     public func substringToIndex(_ index:Int) -> String
     {
     return self.substring(to: self.characters.index(self.startIndex, offsetBy: index))
     }

     public func substringWithRange(_ startIndex:Int,endIndex:Int) -> String
     {
     return self.substring(with: self.characters.index(self.startIndex, offsetBy: startIndex)..<self.characters.index(self.startIndex, offsetBy: endIndex))
     }

     public func substringWithRange(_ range:Range<Int>) -> String
     {
     return substringWithRange(range.lowerBound, endIndex: range.upperBound)
     }
     */

    public func substringWithRange(_ startIndex: Index, endIndex: Index) -> String {
        return substring(with: startIndex ..< endIndex)
    }

    // 反转
    public func reverse() -> String {
        let s = split("").reversed()
        var x = ""
        for y in s {
            x += y
        }
        return x
    }
}

func LocalizedString(_ key: String, tableName: String? = nil, bundle: Bundle! = Bundle.main) -> String {
    return NSLocalizedString(key, tableName: tableName, bundle: bundle, value: "", comment: "")
}
