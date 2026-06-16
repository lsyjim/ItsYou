//
//  SettingNumView.swift
//  ItsYou
//
//  Created by Lai Jiun Yung on 2016/3/16.
//
//

import UIKit
import MessageUI

class SettingNumView: UIView, UITextFieldDelegate, MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    let m_fromButton:UIButton = UIButton()
    let m_toButton:UIButton = UIButton()
    let m_limitButton:UIButton = UIButton()
    var m_nowTFisWho:String!

    // 轉盤模式：主題管理
    var m_numberSettingViews:[UIView] = []   // 數字模式專屬設定元件，轉盤模式時隱藏
    var m_themeAddButton:UIButton!           // 新增主題鈕
    var m_themeTable:UITableView!            // 主題清單
    
    var m_parentObj:AnyObject?//找到老爸是誰
    var m_onDoneCallBack:Selector?//請老爸callback
    var m_onTimerCallBack:Selector?//請求老爸的Timer重新啟動
    var m_onAdCallBack:Selector?//請求老爸開個廣告
    var m_orderSettingChanged:Bool = false  // 記錄正反序是否有變更
    
    //建構email專用的Controller
    var mailController:MFMailComposeViewController!
    
    func refreshWithFrame(_ frame:CGRect) {
        self.frame = frame
        self.backgroundColor = UIColor.clear
        
        let leftButton = UIButton(frame: CGRect(x: 0,y: 0,width: SCREEN_WIDTH/3,height: SCREEN_HEIGHT))
        leftButton.addTarget(self, action: #selector(SettingNumView.onLeftAction), for: .touchUpInside)
        self.addSubview(leftButton)
        
        let mainView = UIView(frame: CGRect(x: SCREEN_WIDTH/3,y: 0,width: SCREEN_WIDTH*2/3,height: SCREEN_HEIGHT))
        mainView.backgroundColor = CTransform.getColorWithHex("f0eff5")
        mainView.layer.shadowOpacity = 0.2
        mainView.layer.shadowColor = UIColor.black.cgColor
        mainView.layer.shadowOffset = CGSize(width: -5, height: 0)
        mainView.layer.shadowRadius = 5
        self.addSubview(mainView)
        var adH:CGFloat
        if UIDevice.current.userInterfaceIdiom == .pad {
            adH = 90.0
        }else {
            adH = 50.0
        }
        let H:CGFloat = 44
        let labelW:CGFloat = 70
        let space:CGFloat = 5
        let fromLabel = UILabel(frame: CGRect(x: space,y: 20,width: labelW,height: H))
        fromLabel.text = "FROM"
        fromLabel.textAlignment = NSTextAlignment.left
        fromLabel.textColor = UIColor.black
        fromLabel.font = UIFont.systemFont(ofSize: H*0.5)
        mainView.addSubview(fromLabel)
        
        m_fromButton.frame = CGRect(x: labelW + space*2, y: 20, width: mainView.frame.size.width - labelW - space*3, height: H)
        m_fromButton.layer.borderColor = COLOR_LINE_GREY.cgColor
        m_fromButton.layer.borderWidth = 1
        m_fromButton.layer.masksToBounds = true
        m_fromButton.layer.cornerRadius = 5
        // contentEdgeInsets deprecated in iOS 15 — using titleEdgeInsets for right padding
        m_fromButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        m_fromButton.setTitle(String(format: "%d",USER_DEFAULTS.integer(forKey: "START_NUM")), for: UIControl.State())
        m_fromButton.titleLabel?.font = UIFont.systemFont(ofSize: H*0.5)
        m_fromButton.setTitleColor(UIColor.black, for: UIControl.State())
        m_fromButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        m_fromButton.addTarget(self, action: #selector(SettingNumView.onButtonAction(_:)), for: .touchUpInside)
        mainView.addSubview(m_fromButton)
        
        
        
        let toLabel = UILabel(frame: CGRect(x: space,y: fromLabel.frame.origin.y + fromLabel.frame.height + space*2,width: labelW,height: H))
        //        toLabel.backgroundColor = COLOR_MENU_LIST
        toLabel.text = "TO"
        toLabel.textAlignment = NSTextAlignment.left
        toLabel.textColor = UIColor.black
        toLabel.font = UIFont.systemFont(ofSize: H*0.5)
        mainView.addSubview(toLabel)
        
        m_toButton.frame = CGRect(x: m_fromButton.frame.origin.x, y: toLabel.frame.origin.y, width: m_fromButton.frame.width, height: H)
        m_toButton.layer.borderColor = COLOR_LINE_GREY.cgColor
        m_toButton.layer.borderWidth = 1
        m_toButton.layer.masksToBounds = true
        m_toButton.layer.cornerRadius = 5
        m_toButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        m_toButton.setTitle(String(format: "%d",USER_DEFAULTS.integer(forKey: "END_NUM")), for: UIControl.State())
        m_toButton.setTitleColor(UIColor.black, for: UIControl.State())
        m_toButton.titleLabel?.font = UIFont.systemFont(ofSize: H*0.5)
        m_toButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        m_toButton.addTarget(self, action: #selector(SettingNumView.onButtonAction(_:)), for: .touchUpInside)
        mainView.addSubview(m_toButton)
        
        let limitLabel = UILabel(frame: CGRect(x: space,y: toLabel.frame.origin.y + toLabel.frame.height + space*2,width: labelW,height: H))
        limitLabel.text = "LIMIT"
        limitLabel.textAlignment = NSTextAlignment.left
        limitLabel.textColor = UIColor.black
        limitLabel.font = UIFont.systemFont(ofSize: H*0.5)
        mainView.addSubview(limitLabel)
        
        m_limitButton.frame = CGRect(x: m_fromButton.frame.origin.x, y: limitLabel.frame.origin.y, width: m_fromButton.frame.width, height: H)
        m_limitButton.layer.borderColor = COLOR_LINE_GREY.cgColor
        m_limitButton.layer.borderWidth = 1
        m_limitButton.layer.masksToBounds = true
        m_limitButton.layer.cornerRadius = 5
        m_limitButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        m_limitButton.setTitle(String(format: "%d",USER_DEFAULTS.integer(forKey: "LIMIT")), for: UIControl.State())
        m_limitButton.setTitleColor(UIColor.black, for: UIControl.State())
        m_limitButton.titleLabel?.font = UIFont.systemFont(ofSize: H*0.5)
        m_limitButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        m_limitButton.addTarget(self, action: #selector(SettingNumView.onButtonAction(_:)), for: .touchUpInside)
        mainView.addSubview(m_limitButton)
        
        
        let autoLabel = UILabel(frame: CGRect(x: space,y: limitLabel.frame.origin.y + limitLabel.frame.height + space*2,width: labelW,height: H))
        autoLabel.text = "AUTO"
        autoLabel.textAlignment = NSTextAlignment.left
        autoLabel.textColor = UIColor.black
        autoLabel.font = UIFont.systemFont(ofSize: H*0.5)
        mainView.addSubview(autoLabel)
        
        let autoButton = UIButton(frame: CGRect(x: m_fromButton.frame.origin.x, y: autoLabel.frame.origin.y, width: m_fromButton.frame.width, height: H))
        autoButton.setTitle(USER_DEFAULTS.bool(forKey: "isAutoDraw") ? "Auto".localized : "Manually".localized, for: UIControl.State())
        autoButton.setTitleColor(COLOR_MENU_LIST, for: UIControl.State())
        autoButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        autoButton.addTarget(self, action: #selector(SettingNumView.onAutoAction(_:)), for: .touchUpInside)
        mainView.addSubview(autoButton)
        
        
        //還原購買（內購）
        let restoreButton = UIButton(frame: CGRect(x: 0,y: SCREEN_HEIGHT - adH - H*4 - space*4,width: mainView.frame.width,height: H))
        restoreButton.setTitle("RestorePurchase".localized, for: UIControl.State())
        restoreButton.setTitleColor(COLOR_MENU_LIST, for: UIControl.State())
        restoreButton.addTarget(self, action: #selector(SettingNumView.onRestoreAction), for: .touchUpInside)
        mainView.addSubview(restoreButton)

        let adButton = UIButton(frame: CGRect(x: 0,y: SCREEN_HEIGHT - adH - H*3 - space*3,width: mainView.frame.width,height: H))
        adButton.setTitle("CAD".localized, for: UIControl.State())
        adButton.setTitleColor(COLOR_MENU_LIST, for: UIControl.State())
        adButton.addTarget(self, action: #selector(SettingNumView.onAdAction), for: .touchUpInside)
        mainView.addSubview(adButton)
        
        let rateButton = UIButton(frame: CGRect(x: 0,y: SCREEN_HEIGHT - adH - H*2 - space*2,width: mainView.frame.width,height: H))
        rateButton.setTitle("RateUS".localized, for: UIControl.State())
        rateButton.setTitleColor(COLOR_MENU_LIST, for: UIControl.State())
        rateButton.addTarget(self, action: #selector(SettingNumView.onRateAction), for: .touchUpInside)
        mainView.addSubview(rateButton)
        
        let mailButton = UIButton(frame: CGRect(x: 0,y: SCREEN_HEIGHT - adH - H - space,width: mainView.frame.width,height: H))
        mailButton.setTitle("Feedback".localized, for: UIControl.State())
        mailButton.setTitleColor(COLOR_MENU_LIST, for: UIControl.State())
        mailButton.addTarget(self, action: #selector(SettingNumView.onMailAction), for: .touchUpInside)
        mainView.addSubview(mailButton)
        
        //2018.12.22新增順序顯示
        let orderLabel = UILabel(frame: CGRect(x: space,y: autoLabel.frame.origin.y + autoLabel.frame.height + space*2,width: labelW,height: H))
        orderLabel.text = "ORDER"
        orderLabel.textAlignment = NSTextAlignment.left
        orderLabel.textColor = UIColor.black
        orderLabel.font = UIFont.systemFont(ofSize: H*0.4)
        mainView.addSubview(orderLabel)
        
        let orderButton = UIButton(frame: CGRect(x: m_fromButton.frame.origin.x, y: orderLabel.frame.origin.y, width: m_fromButton.frame.width, height: H))
        orderButton.setTitle(USER_DEFAULTS.bool(forKey: "isPositiveOrder") ? "Positive".localized : "Reverse".localized, for: UIControl.State())
        orderButton.setTitleColor(COLOR_MENU_LIST, for: UIControl.State())
        orderButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        orderButton.addTarget(self, action: #selector(SettingNumView.onOrderAction(_:)), for: .touchUpInside)
        mainView.addSubview(orderButton)

        //收集數字模式專屬設定元件，轉盤模式時整組隱藏
        m_numberSettingViews = [fromLabel, m_fromButton, toLabel, m_toButton,
                                limitLabel, m_limitButton, autoLabel, autoButton,
                                orderLabel, orderButton]

        //轉盤模式：上方改放主題管理（新增鈕 + 主題清單），高度到「還原購買」上方 10px
        let cadY = SCREEN_HEIGHT - adH - H*4 - space*4   // 與最上方的底部按鈕（還原購買）同一個 Y
        m_themeAddButton = UIButton(frame: CGRect(x: space, y: 20, width: mainView.frame.width - space*2, height: H))
        m_themeAddButton.setTitle("ThemeAdd".localized, for: UIControl.State())
        m_themeAddButton.setTitleColor(COLOR_MENU_LIST, for: UIControl.State())
        m_themeAddButton.titleLabel?.font = UIFont.systemFont(ofSize: H*0.45)
        m_themeAddButton.layer.borderColor = COLOR_LINE_GREY.cgColor
        m_themeAddButton.layer.borderWidth = 1
        m_themeAddButton.layer.cornerRadius = 5
        m_themeAddButton.addTarget(self, action: #selector(SettingNumView.onThemeAddAction), for: .touchUpInside)
        m_themeAddButton.isHidden = true
        mainView.addSubview(m_themeAddButton)

        let themeTableY = m_themeAddButton.frame.origin.y + H + space
        m_themeTable = UITableView(frame: CGRect(x: 0, y: themeTableY,
                                                 width: mainView.frame.width,
                                                 height: max(0, (cadY - 10) - themeTableY)))
        m_themeTable.backgroundColor = CTransform.getColorWithHex("f0eff5")
        m_themeTable.dataSource = self
        m_themeTable.delegate = self
        m_themeTable.rowHeight = 48
        m_themeTable.register(UITableViewCell.self, forCellReuseIdentifier: "themeCell")
        m_themeTable.isHidden = true
        mainView.addSubview(m_themeTable)
    }

    //依目前模式切換設定面板上半部內容
    func prepareForMode() {
        let isWheel = USER_DEFAULTS.bool(forKey: "WHEEL_MODE_ON")
        for v in m_numberSettingViews { v.isHidden = isWheel }
        m_themeAddButton.isHidden = !isWheel
        m_themeTable.isHidden = !isWheel
        if isWheel {
            ensureWheelThemesInited()
            m_themeTable.reloadData()
        }
    }

    //MARK: - 主題清單 UITableView
    //----------------------------------------------------------------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wheelThemes().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "themeCell", for: indexPath)
        let themes = wheelThemes()
        cell.textLabel?.text = themes[indexPath.row]["name"] as? String
        cell.textLabel?.textColor = CTransform.getColorWithHex("656565")
        cell.accessoryType = (indexPath.row == wheelCurrentIndex()) ? .checkmark : .none
        cell.backgroundColor = CTransform.getColorWithHex("f0eff5")   // 與表格底色一致，不全白
        return cell
    }

    //點擊切換當前主題
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        setWheelCurrentIndex(indexPath.row)
        tableView.reloadData()
    }

    //左滑刪除（至少保留一個主題）
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { return }
        var themes = wheelThemes()
        if themes.count <= 1 {
            self.showAlertWithMessage("ThemeNeedOne".localized)
            return
        }
        let cur = wheelCurrentIndex()
        themes.remove(at: indexPath.row)
        setWheelThemes(themes)
        var newCur = cur
        if indexPath.row < cur { newCur = cur - 1 }
        else if indexPath.row == cur { newCur = min(cur, themes.count - 1) }
        setWheelCurrentIndex(newCur)
        tableView.reloadData()
    }

    //往右滑 → 改名
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let rename = UIContextualAction(style: .normal, title: "WheelEdit".localized) { [weak self] _, _, done in
            self?.renameTheme(at: indexPath.row)
            done(true)
        }
        rename.backgroundColor = COLOR_MENU_LIST
        return UISwipeActionsConfiguration(actions: [rename])
    }

    //主題改名
    func renameTheme(at index: Int) {
        var themes = wheelThemes()
        if index >= themes.count { return }
        let alert = UIAlertController(title: "ThemeAddTitle".localized, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = themes[index]["name"] as? String
            tf.placeholder = "ThemeNamePlaceholder".localized
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let name = alert?.textFields?.first?.text ?? ""
            if name.isEmpty { return }
            var themes = wheelThemes()
            if index < themes.count {
                themes[index]["name"] = name
                setWheelThemes(themes)
                self.m_themeTable.reloadData()
            }
        })
        m_parentObj?.present(alert, animated: true)
    }

    @objc func onThemeAddAction() {
        let alert = UIAlertController(title: "ThemeAddTitle".localized, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "ThemeNamePlaceholder".localized
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let name = alert?.textFields?.first?.text ?? ""
            if name.isEmpty { return }
            var themes = wheelThemes()
            themes.append(["name": name, "items": [String]()])
            setWheelThemes(themes)
            setWheelCurrentIndex(themes.count - 1)   // 新增後設為當前主題
            self.m_themeTable.reloadData()
        })
        m_parentObj?.present(alert, animated: true)
    }
    
    @objc func onLeftAction() {
        // 若正反序有變更，先觸發主畫面清空 reset，再關閉面板
        if m_orderSettingChanged {
            m_orderSettingChanged = false
            if let parentObj = m_parentObj, let cb = m_onDoneCallBack, parentObj.responds(to: cb) {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    Thread.detachNewThreadSelector(cb, toTarget: parentObj, with: self)
                }
            }
        }
        // 回傳告知請求Timer啟動(Call Back)
        if ((m_parentObj != nil) && (m_onTimerCallBack != nil)) {
            if (m_parentObj?.responds(to: m_onTimerCallBack!)) == true {
                let time = DispatchTime.now() + Double(Int64(0)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {
                    Thread.detachNewThreadSelector(self.m_onTimerCallBack!, toTarget: self.m_parentObj!, with: self)
                })
            }
        }
        UIView.animate(withDuration: 0.25) {
            m_maskView.alpha = 0.0
            self.frame = CGRect(x: SCREEN_WIDTH, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        }
    }
    
    @objc func onButtonAction(_ sender: UIButton) {
        let isLimit = (sender == m_limitButton)
        let who: String = (sender == m_fromButton) ? "from" : (sender == m_toButton ? "to" : "limit")
        let title = isLimit ? "LIMIT" : "Input".localized
        let message = isLimit ? "NumOfDraw".localized : "1 ~ 99999"
        let placeholder = isLimit ? "Most1000".localized : "Most5".localized
        let maxLen = isLimit ? 3 : 4

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = placeholder
            tf.keyboardType = .numberPad
            tf.addTarget(self, action: #selector(self.onAlertTextChanged(_:)), for: .editingChanged)
            objc_setAssociatedObject(tf, &SettingNumView.maxLenKey, maxLen, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let text = alert?.textFields?.first?.text ?? ""
            self.handleInputDone(text: text, who: who)
        })
        m_parentObj?.present(alert, animated: true)
    }

    private static var maxLenKey = "maxLenKey"

    @objc private func onAlertTextChanged(_ tf: UITextField) {
        let maxLen = objc_getAssociatedObject(tf, &SettingNumView.maxLenKey) as? Int ?? 5
        if let text = tf.text, text.count > maxLen {
            tf.text = String(text.prefix(maxLen))
        }
    }

    private func handleInputDone(text: String, who: String) {
        let safeText = text.isEmpty ? "1" : text
        if who == "from" {
            m_fromButton.setTitle(safeText, for: .normal)
            USER_DEFAULTS.set(Int(safeText) ?? 1, forKey: "START_NUM")
        } else if who == "to" {
            m_toButton.setTitle(safeText, for: .normal)
            USER_DEFAULTS.set(Int(safeText) ?? 1, forKey: "END_NUM")
        } else if who == "limit" {
            var limit = Int(safeText) ?? 1
            if limit > 1000 { limit = 1000 }
            else if limit == 0 { limit = 1 }
            m_limitButton.setTitle(String(format: "%d", limit), for: .normal)
            USER_DEFAULTS.set(limit, forKey: "LIMIT")
        }
        if USER_DEFAULTS.integer(forKey: "END_NUM") < USER_DEFAULTS.integer(forKey: "START_NUM") {
            let temp = USER_DEFAULTS.integer(forKey: "END_NUM")
            USER_DEFAULTS.set(USER_DEFAULTS.integer(forKey: "START_NUM"), forKey: "END_NUM")
            USER_DEFAULTS.set(temp, forKey: "START_NUM")
            m_fromButton.setTitle(String(format: "%d", USER_DEFAULTS.integer(forKey: "START_NUM")), for: .normal)
            m_toButton.setTitle(String(format: "%d", USER_DEFAULTS.integer(forKey: "END_NUM")), for: .normal)
        }
        if let parentObj = m_parentObj, let cb = m_onDoneCallBack, parentObj.responds(to: cb) {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                Thread.detachNewThreadSelector(cb, toTarget: parentObj, with: self)
            }
        }
    }
    
    @objc func onAutoAction(_ sender:UIButton) {
        if USER_DEFAULTS.bool(forKey: "isAutoDraw") {
            USER_DEFAULTS.set(false, forKey: "isAutoDraw")
        }else {
            USER_DEFAULTS.set(true, forKey: "isAutoDraw")
        }
        sender.setTitle(USER_DEFAULTS.bool(forKey: "isAutoDraw") ? "Auto".localized : "Manually".localized, for: UIControl.State())
    }
    //2018.12.22新增順序按鈕功能
    @objc func onOrderAction(_ sender:UIButton){
        if USER_DEFAULTS.bool(forKey: "isPositiveOrder") {
            USER_DEFAULTS.set(false, forKey: "isPositiveOrder")
        }else {
            USER_DEFAULTS.set(true, forKey: "isPositiveOrder")
        }
        sender.setTitle(USER_DEFAULTS.bool(forKey: "isPositiveOrder") ? "Positive".localized : "Reverse".localized, for: UIControl.State())
        m_orderSettingChanged = true  // 標記正反序已變更，關閉面板時觸發清空
    }
   
    @objc func onAdAction() {
        //回傳告知請求開啟廣告(Call Back)
        if ((m_parentObj != nil) && (m_onAdCallBack != nil)) {
            if (m_parentObj?.responds(to: m_onAdCallBack!)) == true {
                let time = DispatchTime.now() + Double(Int64(0)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: {
                    Thread.detachNewThreadSelector(self.m_onAdCallBack!, toTarget: self.m_parentObj!, with: self)
                })
            }
        }
    }
    
    //還原購買（內購）
    @objc func onRestoreAction() {
        Task {
            let ok = await StoreManager.shared.restore()
            DispatchQueue.main.async {
                self.showAlertWithMessage(ok ? "RestoreSuccess".localized : "RestoreNone".localized)
            }
        }
    }

    @objc func onRateAction() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/bars/id1094133993"),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    @objc func onMailAction() {
        let infoDic:NSDictionary = Bundle.main.infoDictionary! as NSDictionary
        self.showEmail(eTitle: "Feedback".localized, eContent: "\("APPNAME".localized): \("ITSYOU".localized)\n\("APPVERSION".localized): \(infoDic["CFBundleShortVersionString"] as! String)\n\("DEVICE".localized): \(UIDevice.current.modelName)\n\("OS".localized): \(UIDevice.current.systemVersion)\n\n\("LEAVEOPINION".localized)：\n", eSubject: "Feedback".localized, ePicture: nil, eRecipients: ["lsyjim@hotmail.com"], eAttachment: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 字數限制改由 onAlertTextChanged 處理，此方法保留供其他 textField 使用
        return true
    }
    
    //MARK: - Normal Function
    //----------------------------------------------------------------------------------------------------------------------------------------------------------
    
    //自定義方法，把基本參數全部傳給mailcontroller
    func showEmail(eTitle title:String, eContent content:String, eSubject subject:String, ePicture pic:UIImage?, eRecipients aryRecipients:Array<String>?, eAttachment attachment:Data?) {
        if mailController == nil {
            mailController = MFMailComposeViewController()
        }
        mailController.title = title
        mailController.mailComposeDelegate = self
        mailController.setSubject(subject)
        mailController.setMessageBody(content, isHTML: false)//載入文檔內容是否指定為HTML格式
        //        let imageData:NSData = UIImagePNGRepresentation(pic!)!
        //        mailController.addAttachmentData(imageData, mimeType: "", fileName: "iCon.png")
        if aryRecipients != nil {//判斷是否有指定收件人
            mailController.setToRecipients(aryRecipients)
        }
        
        if attachment != nil {//判斷是否有夾帶附件
            mailController.addAttachmentData(attachment!, mimeType: "text/csv", fileName: "Report.csv")
        }
        if !MFMailComposeViewController.canSendMail() {//
            self.showAlertWithMessage("無法使用郵件功能")
        }
        
        self.m_parentObj?.present(mailController, animated: true, completion: nil)
        
    }
    
    //MARK: - Mail Delegate
    //----------------------------------------------------------------------------------------------------------------------------------------------------------
    //郵件的controller代理方法，表示執行郵件完成，要關閉mailcontroller
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if result == MFMailComposeResult.sent {
            self.showAlertWithMessage("感謝回饋")
        }
        mailController.dismiss(animated: true, completion: nil)
        mailController = nil
    }
    
    func showAlertWithMessage(_ str: String) {
        let alert = UIAlertController(title: str, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        m_parentObj?.present(alert, animated: true)
    }
}
