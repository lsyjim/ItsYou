//
//  MainVC.swift
//  ItsYou
//
//  Created by Lai Jiun Yung on 2016/3/7.
//
//

import UIKit
import GoogleMobileAds
let m_maskView:UIView = UIView(frame: CGRect(x: 0,y: 0,width: SCREEN_WIDTH,height: SCREEN_HEIGHT))


class MainVC: UIViewController, BannerViewDelegate, FullScreenContentDelegate, UIScrollViewDelegate {
    let m_indicatior:UIActivityIndicatorView = UIActivityIndicatorView()

    var m_startNum:Int!
    var m_endNum:Int!
    var m_orderNum:Int = 1
    var m_aryNums:NSMutableArray!
    var m_scrollView:UIScrollView!
    var m_drawLotsButton:UIButton!
    var m_resetButton:UIButton!
    var m_titleLabel:UILabel!
    var m_frame:CGRect!
    var m_labelH:CGFloat = 80.0
    // Timer 僅保留供設定頁回呼使用，不再用於自動跳廣告
    var m_timmer:Timer?

    var m_GADBannerView:BannerView!
    var m_GADInterstitial:InterstitialAd?   // v13.4：GAD 前綴全移除
    var m_isGADActivite:Bool = false
    var m_isGADInterstitialCanShow:Bool = true
    var m_isInterstitialLoading:Bool = false  // 防止重複發請求
    
    var m_adStage:UIViewController!
    var m_settingNumView:SettingNumView!

    // 轉盤模式相關（與數字抽籤完全獨立）
    var m_wheelView:WheelView!
    var m_numberModeViews:[UIView] = []   // 數字模式專屬元件，切換時整組顯示 / 隱藏
    var m_menuButton:UIButton!            // 左上選單鈕
    var m_settingButton:UIButton!         // 右上設定鈕
    var m_modeView:UIView!                // 模式選擇彈出面板（仿 SettingView）
    var m_modeNumberButton:UIButton!      // 模式：數字抽籤
    var m_modeWheelButton:UIButton!       // 模式：轉盤抽籤
    
    func refreshWithFrame(_ frame: CGRect) {
        self.view.frame = frame
        self.view.backgroundColor = UIColor.white
        m_adStage = UIViewController()
        self.view.addSubview(m_adStage.view)
        
        self.dataInit()
        self.frameInit()
        self.adInit()
    
    }
    //MARK: - Override
    //------------------------------------------------------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        // 預載插頁廣告，等用戶操作再顯示
        self.createAndLoadInterstitial()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    //MARK: - Init
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func dataInit() {
        m_startNum = USER_DEFAULTS.integer(forKey: "START_NUM")
        m_endNum = USER_DEFAULTS.integer(forKey: "END_NUM")
        m_aryNums = NSMutableArray()
        for i in m_startNum...m_endNum {
            m_aryNums.add("\(i)")
        }
    }
    
    func frameInit() {
    
        var w:CGFloat
        if UIDevice.current.userInterfaceIdiom == .pad {
            w = SCREEN_WIDTH * 3 / 12
            m_labelH = 120.0
        } else {
            w = SCREEN_WIDTH * 3 / 8
        }

        // 廣告高度固定 40pt，不隨裝置變動，避免遮住 AdMob 意見回饋按鈕
        let adH: CGFloat = 40

        // 按鈕區域總高 = 按鈕直徑 + 上下間距 + 廣告（全部貼底）
        let buttonAreaH: CGFloat = w + 20 + adH

        m_frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: m_labelH)

        m_titleLabel = UILabel(frame:CGRect(x: 44,y: 0,width: SCREEN_WIDTH - 88,height: 64))
        m_titleLabel.text = String(format:"%d ~ %d",m_startNum,m_endNum)
        m_titleLabel.textColor = COLOR_LINE_GREY
        m_titleLabel.textAlignment = NSTextAlignment.center
        self.view.addSubview(m_titleLabel)
        //在此塊容器上掛載一份捲軸容器
        m_scrollView = UIScrollView()
        m_scrollView.frame = CGRect(x: 0, y: 64, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 64 - buttonAreaH)
        m_scrollView.backgroundColor = CTransform.getColorWithHex("f0eff5")
        m_scrollView.delegate = self
        m_scrollView.showsVerticalScrollIndicator = true;//顯示右側垂直拉Bar條
        m_scrollView.showsHorizontalScrollIndicator = false;
        self.view.addSubview(m_scrollView)
        let line1 = UIView(frame: CGRect(x: 0,y: 63,width: SCREEN_WIDTH,height: 1))
        line1.backgroundColor = COLOR_LINE_GREY
        self.view.addSubview(line1)

        let line2 = UIView(frame: CGRect(x: 0,y: m_scrollView.frame.origin.y + m_scrollView.frame.height,width: SCREEN_WIDTH,height: 1))
        line2.backgroundColor = COLOR_LINE_GREY
        self.view.addSubview(line2)

        // 按鈕中心 Y：從廣告頂部往上，留 w/2 + 10 的空間（adH 固定 40，全部貼底）
        let buttonCenterY: CGFloat = SCREEN_HEIGHT - 40 - w / 2 - 10

        //生成抽籤按鈕
        m_drawLotsButton = UIButton(frame: CGRect(x: 0, y: 0, width: w, height: w))
        m_drawLotsButton.center = CGPoint(x: SCREEN_WIDTH / 4 , y: buttonCenterY)
        m_drawLotsButton.setTitle("Draw".localized, for: UIControl.State())
        m_drawLotsButton.titleLabel?.font = UIFont.init(name: "Arial Rounded MT Bold", size: 26)
        m_drawLotsButton.setTitleColor(UIColor.black, for: .highlighted)
        m_drawLotsButton.backgroundColor = CTransform.getColorWithHex("965454")
        m_drawLotsButton.layer.cornerRadius = w/2;
        m_drawLotsButton.layer.masksToBounds = true;
        m_drawLotsButton.layer.borderWidth = 2;
        m_drawLotsButton.layer.borderColor = CTransform.getColorWithHex("656565").cgColor
        m_drawLotsButton.addTarget(self, action: #selector(MainVC.onDrawLotsAction(_:)), for: .touchUpInside)
        self.view.addSubview(m_drawLotsButton)

        //生成重置按鈕
        m_resetButton = UIButton(frame: CGRect(x: 0, y: 0, width: w, height: w))
        m_resetButton.center = CGPoint(x: SCREEN_WIDTH * 3 / 4, y: buttonCenterY)
        m_resetButton.setTitle("Reset".localized, for: UIControl.State())
        m_resetButton.titleLabel?.font = UIFont.init(name: "Arial Rounded MT Bold", size: 26)
        m_resetButton.setTitleColor(UIColor.black, for: .highlighted)
        m_resetButton.backgroundColor = CTransform.getColorWithHex("7b8b6f")
        m_resetButton.layer.cornerRadius = w/2;
        m_resetButton.layer.masksToBounds = true;
        m_resetButton.layer.borderWidth = 2;
        m_resetButton.layer.borderColor = CTransform.getColorWithHex("656565").cgColor
        m_resetButton.addTarget(self, action: #selector(MainVC.onResetAction), for: .touchUpInside)
        self.view.addSubview(m_resetButton)
        
        //收集數字模式專屬元件，供模式切換整組顯示 / 隱藏
        m_numberModeViews = [m_titleLabel, m_scrollView, line1, line2, m_drawLotsButton, m_resetButton]

        //生成轉盤畫面（疊在數字模式元件之上，但仍在頂部按鈕 / 廣告 / 設定頁之下）
        m_wheelView = WheelView()
        m_wheelView.refreshWithFrame(CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        m_wheelView.m_parentObj = self
        // 編輯介面開 / 關時，連動隱藏頂部按鈕避免誤觸
        m_wheelView.m_onEditToggle = { [weak self] isEditing in
            self?.m_menuButton.isHidden = isEditing
            self?.m_settingButton.isHidden = isEditing
        }
        // 轉盤結束時，沿用數字抽籤的 1/20 機率彈出插頁廣告
        m_wheelView.m_onWantAd = { [weak self] in
            self?.onAdAction()
        }
        self.view.addSubview(m_wheelView)

        //生成設定按鈕
        m_settingButton = UIButton(frame: CGRect(x: SCREEN_WIDTH - 44,y: 10,width: 44,height: 44))
        m_settingButton.setTitle("⚙", for: UIControl.State())
        m_settingButton.setTitleColor(UIColor.black, for: UIControl.State())
        m_settingButton.addTarget(self, action: #selector(MainVC.onSettingAction), for: .touchUpInside)
        self.view.addSubview(m_settingButton)

        //生成左上選單按鈕（對稱於右上 ⚙，用來切換數字 / 轉盤模式）
        m_menuButton = UIButton(frame: CGRect(x: 0,y: 10,width: 44,height: 44))
        m_menuButton.setTitle("☰", for: UIControl.State())
        m_menuButton.setTitleColor(UIColor.black, for: UIControl.State())
        m_menuButton.addTarget(self, action: #selector(MainVC.onMenuAction), for: .touchUpInside)
        self.view.addSubview(m_menuButton)

        //套用上次的模式（重開 App 回到上次模式）
        self.applyWheelMode(USER_DEFAULTS.bool(forKey: "WHEEL_MODE_ON"))

        m_maskView.backgroundColor = COLOR_BLUR_BLACK
        m_maskView.alpha = 0.0
        self.view.addSubview(m_maskView)
        //生成設定頁
        m_settingNumView = SettingNumView()
        m_settingNumView.refreshWithFrame(CGRect(x: SCREEN_WIDTH, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        m_settingNumView.m_parentObj = self
        m_settingNumView.m_onDoneCallBack = #selector(MainVC.onResetAction)
        m_settingNumView.m_onTimerCallBack = #selector(MainVC.onTimerAction)
        m_settingNumView.m_onAdCallBack = #selector(MainVC.onAdAction)
        self.view.addSubview(m_settingNumView)
        
        //生成轉圈圈
        m_indicatior.frame = CGRect(x: 0,y: 0,width: 100,height: 100)
        m_indicatior.center = CGPoint(x: self.view.center.x, y: self.view.center.y - NAVI_BAR_HEIGHT)
        m_indicatior.style = UIActivityIndicatorView.Style.medium
        self.view.addSubview(m_indicatior)
        m_indicatior.hidesWhenStopped = true

        //生成模式選擇面板（疊在最上層，含遮罩）
        self.buildModeView()
    }

    //生成模式選擇面板（仿 SettingView，從左側滑入）
    func buildModeView() {
        m_modeView = UIView(frame: CGRect(x: -SCREEN_WIDTH, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        m_modeView.backgroundColor = UIColor.clear

        let panelW = SCREEN_WIDTH * 2 / 3
        //右側透明關閉區
        let closeButton = UIButton(frame: CGRect(x: panelW, y: 0, width: SCREEN_WIDTH - panelW, height: SCREEN_HEIGHT))
        closeButton.addTarget(self, action: #selector(MainVC.closeModePanel), for: .touchUpInside)
        m_modeView.addSubview(closeButton)

        let mainView = UIView(frame: CGRect(x: 0, y: 0, width: panelW, height: SCREEN_HEIGHT))
        mainView.backgroundColor = CTransform.getColorWithHex("f0eff5")
        mainView.layer.shadowOpacity = 0.2
        mainView.layer.shadowColor = UIColor.black.cgColor
        mainView.layer.shadowOffset = CGSize(width: 5, height: 0)
        mainView.layer.shadowRadius = 5
        m_modeView.addSubview(mainView)

        let H: CGFloat = 50
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 30, width: panelW, height: H))
        titleLabel.text = "ModeTitle".localized
        titleLabel.textAlignment = .center
        titleLabel.textColor = CTransform.getColorWithHex("656565")
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        mainView.addSubview(titleLabel)

        m_modeNumberButton = UIButton(frame: CGRect(x: 0, y: titleLabel.frame.maxY + 20, width: panelW, height: H))
        m_modeNumberButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        m_modeNumberButton.addTarget(self, action: #selector(MainVC.onModeNumberAction), for: .touchUpInside)
        mainView.addSubview(m_modeNumberButton)

        m_modeWheelButton = UIButton(frame: CGRect(x: 0, y: m_modeNumberButton.frame.maxY + 10, width: panelW, height: H))
        m_modeWheelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        m_modeWheelButton.addTarget(self, action: #selector(MainVC.onModeWheelAction), for: .touchUpInside)
        mainView.addSubview(m_modeWheelButton)

        self.view.addSubview(m_modeView)
    }

    //更新兩個模式按鈕的勾選狀態
    func refreshModeButtons() {
        let on = USER_DEFAULTS.bool(forKey: "WHEEL_MODE_ON")
        m_modeNumberButton.setTitle((on ? "" : "✓ ") + "ModeNumber".localized, for: .normal)
        m_modeWheelButton.setTitle((on ? "✓ " : "") + "ModeWheel".localized, for: .normal)
        m_modeNumberButton.setTitleColor(on ? UIColor.black : COLOR_MENU_LIST, for: .normal)
        m_modeWheelButton.setTitleColor(on ? COLOR_MENU_LIST : UIColor.black, for: .normal)
    }
    
    func adInit() {

        // 使用標準 adaptive banner（約 50pt），容器鎖高 40pt 並 clip
        // ⓘ 意見回饋按鈕在廣告頂端，完整顯示；底部多出的 ~10pt 在螢幕外不影響
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: SCREEN_WIDTH)
        m_GADBannerView = BannerView(adSize: adSize)
        m_GADBannerView.rootViewController = self
        m_GADBannerView.delegate = self
        m_GADBannerView.adUnitID = "ca-app-pub-3873309169448072/9054671147"

        let adContainerH: CGFloat = 40
        let adView = UIView(frame: CGRect(x: 0, y: SCREEN_HEIGHT - adContainerH, width: SCREEN_WIDTH, height: adContainerH))
        adView.clipsToBounds = true  // 超過 40pt 的部分裁掉，不影響頂端按鈕區
        self.view.addSubview(adView)
        adView.addSubview(m_GADBannerView)
        m_GADBannerView.load(Request())

    }
    
    //MARK: - ScrollView Delegate
    //------------------------------------------------------------------------------------------------------------------------------------------------
    var isToButtom:Bool = false
    var isToTop:Bool = false
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //滾動結束
        if isToButtom {
            m_scrollView.setContentOffset(CGPoint(x: 0, y: m_scrollView.contentSize.height - m_scrollView.frame.height), animated: true)
        }
        if isToTop {
            m_scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //手指放開順間
        isToButtom = scrollView.contentOffset.y < -50.0 ? true : false
        isToTop = scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.height + 50.0 ? true : false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
    
    //MARK: - GAD Events
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func showAdBanner(_ isShow:Bool) {
        m_isGADActivite = isShow
        UIView.animate(withDuration: 0.25) {
            if isShow {
                self.m_GADBannerView.frame = CGRect(x: 0, y: 0, width: self.m_GADBannerView.frame.size.width, height: self.m_GADBannerView.frame.size.height)
            } else {
                self.m_GADBannerView.frame = CGRect(x: 0, y: self.m_GADBannerView.frame.size.height, width: self.m_GADBannerView.frame.size.width, height: self.m_GADBannerView.frame.size.height)
            }
        }
    }
    
    func createAndLoadInterstitial() {
        // 避免重複發請求，防止 "Too many recently failed requests"
        guard !m_isInterstitialLoading, m_GADInterstitial == nil else { return }
        m_isInterstitialLoading = true

        // v13.4：GAD 前綴全移除
        InterstitialAd.load(with: "ca-app-pub-3873309169448072/3210242744",
                            request: Request()) { [weak self] ad, error in
            guard let self = self else { return }
            self.m_isInterstitialLoading = false

            if let error = error {
                print("插頁廣告載入失敗: \(error.localizedDescription)")
                return
            }
            self.m_GADInterstitial = ad
            self.m_GADInterstitial?.fullScreenContentDelegate = self
            // 只有在用戶主動觸發（Reset / 設定頁）的情況下才立刻顯示
            if self.m_isGADInterstitialCanShow {
                self.m_isGADInterstitialCanShow = false
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.m_GADInterstitial?.present(from: self)
                    self.m_GADInterstitial = nil
                }
            }
        }
    }
    //MARK: - GADBannerViewDelegate
    //------------------------------------------------------------------------------------------------------------------------------------------------
    // v13.4：GAD 前綴移除，BannerView 取代 GADBannerView
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        //收到廣告
        self.showAdBanner(true)
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        //接收廣告發生錯誤
        self.showAdBanner(false)
    }

    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        //點選啟動廣告
    }

    func bannerViewWillDismissScreen(_ bannerView: BannerView) {
        //關閉廣告視窗
    }

    //MARK: - FullScreenContentDelegate（插頁廣告）
    //------------------------------------------------------------------------------------------------------------------------------------------------
    // v13.4：GADFullScreenContentDelegate → FullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // 關閉後清除舊物件，預載下一筆備用（不自動顯示）
        m_GADInterstitial = nil
        m_isGADInterstitialCanShow = false
        self.createAndLoadInterstitial()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("插頁廣告顯示失敗: \(error.localizedDescription)")
        m_GADInterstitial = nil
    }
    //MARK: - Actions
    //------------------------------------------------------------------------------------------------------------------------------------------------
    @objc func onDrawLotsAction(_ sender:UIButton) {
        var c:Int = 0//要抽的順位
        if USER_DEFAULTS.bool(forKey: "isAutoDraw") {//自動抽
            if m_aryNums.count < USER_DEFAULTS.integer(forKey: "LIMIT") {
                c = m_aryNums.count + 1
                if m_orderNum != 1 {
                    c = c + m_orderNum - 1
                }
            }else {
                c = USER_DEFAULTS.integer(forKey: "LIMIT") + 1
            }
        }else {//手動抽
            c = m_orderNum + 1
            if c > USER_DEFAULTS.integer(forKey: "LIMIT") {
                c = USER_DEFAULTS.integer(forKey: "LIMIT") + 1
            }
        }

        // 反序模式預算
        let isReverse = !USER_DEFAULTS.bool(forKey: "isPositiveOrder")
        let limit = USER_DEFAULTS.integer(forKey: "LIMIT")
        let space: CGFloat = 1.0
        let count: CGFloat = 5.0
        let w: CGFloat = (SCREEN_WIDTH - space * (count + 1)) / count
        // 反序：前 (limit-3) 個用小格，後 3 個用大格
        let smallGridCount = max(0, limit - 3)
        let smallGridRows = smallGridCount > 0 ? (smallGridCount + 4) / 5 : 0
        let bigCellBaseY = CGFloat(smallGridRows) * (m_labelH + 1)

        if m_aryNums.count > 0 {
            while m_orderNum != c {
                let result:Int = Int(arc4random_uniform(UInt32(m_aryNums.count)))

                // 反序：根據 m_orderNum 重新計算 m_frame
                if isReverse {
                    if m_orderNum <= smallGridCount {
                        // 小格區（前面幾名）
                        let col = CGFloat((m_orderNum - 1) % 5)
                        let row = CGFloat((m_orderNum - 1) / 5)
                        m_frame = CGRect(x: space + (w + space) * col,
                                         y: row * (m_labelH + 1),
                                         width: w, height: m_labelH)
                    } else {
                        // 大格區（最後 3 名，對應 3rd/2nd/1st）
                        let bigCellIndex = CGFloat(m_orderNum - smallGridCount - 1)
                        m_frame = CGRect(x: 0,
                                         y: bigCellBaseY + bigCellIndex * (m_labelH + 1),
                                         width: SCREEN_WIDTH, height: m_labelH)
                    }
                }

                let label = UILabel(frame: m_frame)
                label.text = " \(m_aryNums[result]) "
                label.textColor = CTransform.getColorWithHex("656565")
                label.adjustsFontSizeToFitWidth = true
                label.layer.borderColor = UIColor.white.cgColor
                label.layer.borderWidth = 1
                label.minimumScaleFactor = 0.1
                m_scrollView.addSubview(label)
                m_scrollView.contentSize = CGSize(width: m_scrollView.frame.size.width, height: m_frame.origin.y + m_frame.size.height + 1)
                m_aryNums.removeObject(at: result)

                let orderLabel = UILabel()
                orderLabel.frame = m_frame
                orderLabel.textAlignment = NSTextAlignment.left
                orderLabel.backgroundColor = UIColor.clear
                orderLabel.textColor = UIColor.gray
                orderLabel.font = UIFont.systemFont(ofSize: orderLabel.frame.height * 0.3)

                if isReverse {
                    // 反序：小格區標籤顯示名次（LIMIT、LIMIT-1…4），大格區顯示 3rd/2nd/1st
                    let bigCellIndex = m_orderNum - smallGridCount  // 1=3rd, 2=2nd, 3=1st
                    if m_orderNum <= smallGridCount {
                        // 小格：顯示當前名次編號
                        let displayRank = limit + 1 - m_orderNum
                        orderLabel.frame = CGRect(x: m_frame.origin.x, y: m_frame.origin.y, width: m_frame.size.width, height: m_frame.size.height / 4)
                        orderLabel.text = " \(displayRank)"
                        orderLabel.font = UIFont.systemFont(ofSize: orderLabel.frame.height * 0.4)
                        label.textAlignment = NSTextAlignment.center
                        label.font = UIFont(name: "Heiti TC", size: label.frame.height * 0.3)
                    } else if bigCellIndex == 1 {
                        // 3rd（倒數第三）
                        orderLabel.text = " 3rd"
                        label.textAlignment = NSTextAlignment.center
                        label.font = UIFont(name: "Arial", size: label.frame.height * 0.5)
                    } else if bigCellIndex == 2 {
                        // 2nd
                        orderLabel.text = " 2nd"
                        label.textAlignment = NSTextAlignment.center
                        label.font = UIFont(name: "Arial", size: label.frame.height * 0.7)
                    } else {
                        // 1st（最後抽出，最大）
                        orderLabel.text = " 1st"
                        label.textAlignment = NSTextAlignment.center
                        label.font = UIFont(name: "Arial", size: label.frame.height * 0.9)
                    }
                } else {
                    // 正序（原本邏輯不變）
                    if m_orderNum == 1 {
                        orderLabel.text = " 1st"
                        label.textAlignment = NSTextAlignment.center
                        label.font = UIFont(name: "Arial", size: label.frame.height * 0.9)
                    } else if m_orderNum == 2 {
                        orderLabel.text = " 2nd"
                        label.textAlignment = NSTextAlignment.center
                        label.font = UIFont(name: "Arial", size: label.frame.height * 0.7)
                    } else if m_orderNum == 3 {
                        orderLabel.text = " 3rd"
                        label.textAlignment = NSTextAlignment.center
                        label.font = UIFont(name: "Arial", size: label.frame.height * 0.5)
                    } else {
                        orderLabel.frame = CGRect(x: m_frame.origin.x, y: m_frame.origin.y, width: m_frame.size.width, height: m_frame.size.height / 4)
                        orderLabel.text = " \(m_orderNum)"
                        orderLabel.font = UIFont.systemFont(ofSize: orderLabel.frame.height * 0.4)
                        label.textAlignment = NSTextAlignment.center
                        label.font = UIFont(name: "Heiti TC", size: label.frame.height * 0.3)
                    }
                }

                m_scrollView.addSubview(orderLabel)
                m_orderNum += 1
                if m_scrollView.contentSize.height > m_scrollView.frame.size.height {
                    if !USER_DEFAULTS.bool(forKey: "isAutoDraw") {
                        m_scrollView.contentOffset = CGPoint(x: 0, y: m_scrollView.contentSize.height - m_scrollView.frame.size.height)
                    }
                }

                // 正序才需要更新 m_frame（反序在下次迭代開頭重新計算）
                if !isReverse {
                    if m_orderNum < 4 {
                        m_frame = CGRect(x: 0, y: m_frame.origin.y + m_frame.size.height + 1, width: m_frame.size.width, height: m_frame.size.height)
                    } else {
                        m_frame = CGRect(x: space+(w+space)*(CGFloat(m_orderNum + 1).truncatingRemainder(dividingBy: count)),
                                         y: ((m_frame.size.height+space) * 2)+(m_frame.size.height+space)*CGFloat(Int(m_orderNum + 1)/Int(count)),
                                         width: w, height: m_frame.size.height)
                    }
                }
            }
        }
    }
    
    
    @objc func onResetAction() {
        m_startNum = USER_DEFAULTS.integer(forKey: "START_NUM")
        m_endNum = USER_DEFAULTS.integer(forKey: "END_NUM")
        DispatchQueue.main.async {//這裡是CallBack所以UI的東西要在主線程做
            self.m_titleLabel.text = String(format:"%d ~ %d",self.m_startNum,self.m_endNum)
            self.m_indicatior.startAnimating()//開始轉圈圈
            for subview in self.m_scrollView.subviews {
                subview.removeFromSuperview()
            }
        }
        
        m_frame = CGRect(x: 0,y: 0, width: SCREEN_WIDTH, height: m_labelH)
        m_aryNums.removeAllObjects()
        for i in m_startNum ... m_endNum {
            m_aryNums.add("\(i)")
        }
        m_orderNum = 1
        DispatchQueue.main.async {
           self.m_indicatior.stopAnimating()//停止轉動
        }
        
        
        // Reset 是用戶主動觸發的自然斷點，適合顯示插頁廣告（1/5 機率，符合 AdMob 政策）
        if arc4random() % 20 == 0 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let interstitial = self.m_GADInterstitial {
                    interstitial.present(from: self)
                    self.m_GADInterstitial = nil
                } else {
                    // 廣告還沒載好：設旗標，載好後立刻顯示
                    self.m_isGADInterstitialCanShow = true
                    self.createAndLoadInterstitial()
                }
            }
        }
    }

    @objc func onSettingAction() {
        // 依目前模式切換設定面板內容（數字設定 or 轉盤主題清單）
        m_settingNumView.prepareForMode()
        UIView.beginAnimations("", context: nil)
        m_maskView.alpha = 1.0
        m_settingNumView.frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        UIView.commitAnimations()

    }

    @objc func onTimerAction() {
        // 設定面板關閉時呼叫：轉盤模式下刷新主題標題與轉盤內容
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if USER_DEFAULTS.bool(forKey: "WHEEL_MODE_ON") {
                self.m_wheelView.refreshTheme()
            }
        }
    }

    //MARK: - 模式切換（數字抽籤 <-> 轉盤抽籤）
    //------------------------------------------------------------------------------------------------------------------------------------------------
    @objc func onMenuAction() {
        // 彈出模式選擇面板（仿 SettingView）
        self.refreshModeButtons()
        UIView.animate(withDuration: 0.25) {
            m_maskView.alpha = 1.0
            self.m_modeView.frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        }
    }

    @objc func closeModePanel() {
        UIView.animate(withDuration: 0.25) {
            m_maskView.alpha = 0.0
            self.m_modeView.frame = CGRect(x: -SCREEN_WIDTH, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        }
    }

    @objc func onModeNumberAction() {
        self.applyWheelMode(false)
        self.closeModePanel()
    }

    @objc func onModeWheelAction() {
        self.applyWheelMode(true)
        self.closeModePanel()
    }

    func applyWheelMode(_ on:Bool) {
        USER_DEFAULTS.set(on, forKey: "WHEEL_MODE_ON")
        m_wheelView.isHidden = !on
        for v in m_numberModeViews {
            v.isHidden = on
        }
    }

    //直接開廣告（由 Thread.detachNewThreadSelector 呼叫，需切回主線程）
    @objc func onAdAction() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let interstitial = self.m_GADInterstitial {
                interstitial.present(from: self)
                self.m_GADInterstitial = nil
            } else {
                // 廣告還沒載好，設旗標讓它載完就顯示
                self.m_isGADInterstitialCanShow = true
                self.createAndLoadInterstitial()
            }
        }
    }
    
}
