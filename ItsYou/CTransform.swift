//
//  CTransform.swift
//  ItsYou
//
//  Created by Lai Jiun Yung on 2016/3/16.
//
//

import UIKit

class CTransform: NSObject {
    //MARK: - 取得顏色方法
    //-------------------------------------------------------------------------------------------------------------------------------------
    class func getColorWithHex(_ hex:String) -> UIColor {//直接給16進位的色碼
        var cString:String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString = (cString as NSString).substring(from: 1)
        }
        
        if (cString.count != 6) {
            return UIColor.gray
        }
        
        let rString = (cString as NSString).substring(to: 2)
        let gString = ((cString as NSString).substring(from: 2) as NSString).substring(to: 2)
        let bString = ((cString as NSString).substring(from: 4) as NSString).substring(to: 2)
        
        let r = UInt32(rString, radix: 16) ?? 0
        let g = UInt32(gString, radix: 16) ?? 0
        let b = UInt32(bString, radix: 16) ?? 0

        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
    }
}

public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        // iPod touch
        case "iPod5,1":                                         return "iPod touch 5"
        case "iPod7,1":                                         return "iPod touch 6"
        case "iPod9,1":                                         return "iPod touch 7"

        // iPhone 4 ~ 6s
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":             return "iPhone 4"
        case "iPhone4,1":                                       return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                          return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                          return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                          return "iPhone 5s"
        case "iPhone7,2":                                       return "iPhone 6"
        case "iPhone7,1":                                       return "iPhone 6 Plus"
        case "iPhone8,1":                                       return "iPhone 6s"
        case "iPhone8,2":                                       return "iPhone 6s Plus"
        case "iPhone8,4":                                       return "iPhone SE (1st)"

        // iPhone 7 ~ X
        case "iPhone9,1", "iPhone9,3":                          return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                          return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4":                        return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":                        return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":                        return "iPhone X"

        // iPhone XS ~ 11
        case "iPhone11,2":                                      return "iPhone XS"
        case "iPhone11,4", "iPhone11,6":                        return "iPhone XS Max"
        case "iPhone11,8":                                      return "iPhone XR"
        case "iPhone12,1":                                      return "iPhone 11"
        case "iPhone12,3":                                      return "iPhone 11 Pro"
        case "iPhone12,5":                                      return "iPhone 11 Pro Max"
        case "iPhone12,8":                                      return "iPhone SE (2nd)"

        // iPhone 12
        case "iPhone13,1":                                      return "iPhone 12 mini"
        case "iPhone13,2":                                      return "iPhone 12"
        case "iPhone13,3":                                      return "iPhone 12 Pro"
        case "iPhone13,4":                                      return "iPhone 12 Pro Max"

        // iPhone 13
        case "iPhone14,4":                                      return "iPhone 13 mini"
        case "iPhone14,5":                                      return "iPhone 13"
        case "iPhone14,2":                                      return "iPhone 13 Pro"
        case "iPhone14,3":                                      return "iPhone 13 Pro Max"
        case "iPhone14,6":                                      return "iPhone SE (3rd)"

        // iPhone 14
        case "iPhone14,7":                                      return "iPhone 14"
        case "iPhone14,8":                                      return "iPhone 14 Plus"
        case "iPhone15,2":                                      return "iPhone 14 Pro"
        case "iPhone15,3":                                      return "iPhone 14 Pro Max"

        // iPhone 15
        case "iPhone15,4":                                      return "iPhone 15"
        case "iPhone15,5":                                      return "iPhone 15 Plus"
        case "iPhone16,1":                                      return "iPhone 15 Pro"
        case "iPhone16,2":                                      return "iPhone 15 Pro Max"

        // iPhone 16
        case "iPhone17,3":                                      return "iPhone 16"
        case "iPhone17,4":                                      return "iPhone 16 Plus"
        case "iPhone17,1":                                      return "iPhone 16 Pro"
        case "iPhone17,2":                                      return "iPhone 16 Pro Max"
        case "iPhone17,5":                                      return "iPhone 16e"

        // iPad (標準)
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":        return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":                   return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":                   return "iPad 4"
        case "iPad6,11", "iPad6,12":                            return "iPad 5"
        case "iPad7,5", "iPad7,6":                              return "iPad 6"
        case "iPad7,11", "iPad7,12":                            return "iPad 7"
        case "iPad11,6", "iPad11,7":                            return "iPad 8"
        case "iPad12,1", "iPad12,2":                            return "iPad 9"
        case "iPad13,18", "iPad13,19":                          return "iPad 10"

        // iPad Air
        case "iPad4,1", "iPad4,2", "iPad4,3":                   return "iPad Air"
        case "iPad5,3", "iPad5,4":                              return "iPad Air 2"
        case "iPad11,3", "iPad11,4":                            return "iPad Air 3"
        case "iPad13,1", "iPad13,2":                            return "iPad Air 4"
        case "iPad13,16", "iPad13,17":                          return "iPad Air 5"
        case "iPad14,8", "iPad14,9":                            return "iPad Air 11-inch (M2)"
        case "iPad14,10", "iPad14,11":                          return "iPad Air 13-inch (M2)"

        // iPad Mini
        case "iPad2,5", "iPad2,6", "iPad2,7":                   return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":                   return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":                   return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                              return "iPad Mini 4"
        case "iPad11,1", "iPad11,2":                            return "iPad Mini 5"
        case "iPad14,1", "iPad14,2":                            return "iPad Mini 6"
        case "iPad16,1", "iPad16,2":                            return "iPad Mini 7"

        // iPad Pro
        case "iPad6,7", "iPad6,8":                              return "iPad Pro 12.9-inch (1st)"
        case "iPad6,3", "iPad6,4":                              return "iPad Pro 9.7-inch"
        case "iPad7,1", "iPad7,2":                              return "iPad Pro 12.9-inch (2nd)"
        case "iPad7,3", "iPad7,4":                              return "iPad Pro 10.5-inch"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":        return "iPad Pro 11-inch (1st)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":        return "iPad Pro 12.9-inch (3rd)"
        case "iPad8,9", "iPad8,10":                             return "iPad Pro 11-inch (2nd)"
        case "iPad8,11", "iPad8,12":                            return "iPad Pro 12.9-inch (4th)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":    return "iPad Pro 11-inch (3rd)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":  return "iPad Pro 12.9-inch (5th)"
        case "iPad14,3", "iPad14,4":                            return "iPad Pro 11-inch (4th)"
        case "iPad14,5", "iPad14,6":                            return "iPad Pro 12.9-inch (6th)"
        case "iPad16,3", "iPad16,4":                            return "iPad Pro 11-inch (M4)"
        case "iPad16,5", "iPad16,6":                            return "iPad Pro 13-inch (M4)"

        // Apple TV
        case "AppleTV5,3":                                      return "Apple TV 4"
        case "AppleTV6,2":                                      return "Apple TV 4K"
        case "AppleTV11,1":                                     return "Apple TV 4K (2nd)"
        case "AppleTV14,1":                                     return "Apple TV 4K (3rd)"

        // Apple Watch
        case "Watch1,1", "Watch1,2":                            return "Apple Watch (1st)"
        case "Watch2,6", "Watch2,7":                            return "Apple Watch Series 1"
        case "Watch2,3", "Watch2,4":                            return "Apple Watch Series 2"
        case "Watch3,1", "Watch3,2", "Watch3,3", "Watch3,4":    return "Apple Watch Series 3"
        case "Watch4,1", "Watch4,2", "Watch4,3", "Watch4,4":    return "Apple Watch Series 4"

        // Simulator（x86_64 / i386 / arm64）
        case "i386", "x86_64", "arm64":                         return "Simulator"

        default:                                                return identifier
        }
    }
    
}
