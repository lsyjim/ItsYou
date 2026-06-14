//
//  Config.swift
//  ItsYou
//
//  Created by Lai Jiun Yung on 2016/3/7.
//
//

import UIKit
//MARK: - 取得系統預設設定
//-------------------------------------------------------------------------------------------------------------------------------------
let SCREEN_WIDTH:CGFloat = UIScreen.main.bounds.size.width //取得螢幕的寬
let SCREEN_HEIGHT:CGFloat = UIScreen.main.bounds.size.height//取得螢幕的高
let NAVI_BAR_HEIGHT:CGFloat = 64.0 //導覽列的高
let COLOR_NAVI_BAR:UIColor = UIColor(red: 99/255.0, green: 176/255.0, blue: 255/255.0, alpha: 1.0)//導覽列的顏色
let COLOR_MENU_LIST:UIColor = UIColor(red: 0/255.0, green: 122/255.0, blue: 206/255.0, alpha: 1.0)//側邊選單顏色
let COLOR_BLUR_BLACK:UIColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4)
let COLOR_LINE_GREY:UIColor = UIColor(red: 200/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1.0)
let USER_DEFAULTS:UserDefaults = UserDefaults.standard
//MARK: - 自定義LOG
//-------------------------------------------------------------------------------------------------------------------------------------
func CLog(_ message: String,
          functionName:  String = #function, fileNameWithPath: NSString = #file, lineNumber: Int = #line ) {
        // In the default arguments to this function:
        // 1) If I use a String type, the macros (e.g., __LINE__) don't expand at run time.
        //  "\(__FUNCTION__)\(__FILE__)\(__LINE__)"
        // 2) A tuple type, like,
        // typealias SMLogFuncDetails = (String, String, Int)
        //  SMLogFuncDetails = (__FUNCTION__, __FILE__, __LINE__)
        //  doesn't work either.
        // 3) This String = __FUNCTION__ + __FILE__
        //  also doesn't work.
        
        let fileNameWithoutPath = fileNameWithPath.lastPathComponent
        let output = "\(Date())[\(functionName) in \(fileNameWithoutPath), line \(lineNumber)]:\(message)"
//        if isLog {
            print(output)
//        }
    
}

//MARK: - 轉盤主題資料存取（WheelView 與 SettingNumView 共用）
//-------------------------------------------------------------------------------------------------------------------------------------
// 每個主題格式：["name": String, "items": [String]]
func wheelThemes() -> [[String: Any]] {
    return USER_DEFAULTS.array(forKey: "WHEEL_THEMES") as? [[String: Any]] ?? []
}

func setWheelThemes(_ themes: [[String: Any]]) {
    USER_DEFAULTS.set(themes, forKey: "WHEEL_THEMES")
}

func wheelCurrentIndex() -> Int {
    let count = wheelThemes().count
    var idx = USER_DEFAULTS.integer(forKey: "WHEEL_CURRENT")
    if idx >= count { idx = max(0, count - 1) }
    if idx < 0 { idx = 0 }
    return idx
}

func setWheelCurrentIndex(_ i: Int) {
    USER_DEFAULTS.set(i, forKey: "WHEEL_CURRENT")
}

func wheelCurrentThemeName() -> String {
    let themes = wheelThemes()
    let idx = wheelCurrentIndex()
    if idx < themes.count { return themes[idx]["name"] as? String ?? "" }
    return ""
}

// 首次啟動 / 舊版升級：確保至少有一個主題（沿用舊的 WHEEL_ITEMS 內容）
func ensureWheelThemesInited() {
    if USER_DEFAULTS.array(forKey: "WHEEL_THEMES") != nil { return }
    var items: [String]
    if let old = USER_DEFAULTS.array(forKey: "WHEEL_ITEMS") as? [String], !old.isEmpty {
        items = old   // 從舊版單一轉盤搬移內容
    } else {
        items = ["WheelSample1".localized,
                 "WheelSample2".localized,
                 "WheelSample3".localized,
                 "WheelSample4".localized]
    }
    let theme: [String: Any] = ["name": "ThemeDefault".localized, "items": items]
    setWheelThemes([theme])
    setWheelCurrentIndex(0)
}

//MARK: - 多語系用
//-------------------------------------------------------------------------------------------------------------------------------------
extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    
    //給自己的字串加個註解吧
    func localizedWithComment(_ comment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: comment)
    }
}
