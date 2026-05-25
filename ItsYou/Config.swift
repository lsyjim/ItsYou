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
