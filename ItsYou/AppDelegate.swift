//
//  AppDelegate.swift
//  ItsYou
//
//  Created by Lai Jiun Yung on 2016/3/7.
//
//

import UIKit
import GoogleMobileAds
import AppTrackingTransparency

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FullScreenContentDelegate {

    var window: UIWindow?
    var mainVC: MainVC?

    // MARK: - App Open Ad
    var m_appOpenAd: AppOpenAd?
    var m_isAppOpenAdLoading: Bool = false
    var m_backgroundDate: Date?
    var m_shouldShowOnLoad: Bool = true  // 首次啟動自動顯示，之後只預載不自動顯示
    let m_appOpenAdUnitID = "ca-app-pub-3873309169448072/4799232817"

    // MARK: - Application Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 內購：啟動監聽與商品載入，並以 currentEntitlements 推導 isPremium
        StoreManager.shared.start()

        // SDK 必須最優先初始化，任何廣告請求（包含 Banner）都必須在這之後
        MobileAds.shared.start { [weak self] _ in
            self?.loadAppOpenAd()
        }

        if USER_DEFAULTS.integer(forKey: "START_NUM") == 0 {
            USER_DEFAULTS.set(1, forKey: "START_NUM")
        }
        if USER_DEFAULTS.integer(forKey: "END_NUM") == 0 {
            USER_DEFAULTS.set(999, forKey: "END_NUM")
        }
        if USER_DEFAULTS.integer(forKey: "LIMIT") == 0 {
            USER_DEFAULTS.set(5, forKey: "LIMIT")
        }

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        mainVC = MainVC()
        mainVC?.refreshWithFrame(window!.frame)
        window!.rootViewController = mainVC
        window?.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // 記錄進入背景的時間，用來判斷回前景是否顯示廣告
        m_backgroundDate = Date()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // ATT 追蹤授權請求（iOS 14+），只在第一次詢問，之後跳過
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                    // 不管用戶選什麼，廣告都繼續跑（只是個人化程度不同）
                    // ATT 詢問期間先不顯示 App Open Ad，避免疊畫面
                    DispatchQueue.main.async {
                        self?.showOpenAdAfterATT()
                    }
                }
                return  // 等 ATT 回調再繼續
            }
        }

        // 從背景回來，若超過 4 小時才重新顯示，避免頻繁打擾使用者
        guard let backgroundDate = m_backgroundDate else { return }
        let threshold: TimeInterval = 4 * 60 * 60 // 4 小時
        if Date().timeIntervalSince(backgroundDate) >= threshold {
            showAppOpenAdIfAvailable()
        }
    }

    private func showOpenAdAfterATT() {
        // ATT 回調後，判斷是否需要顯示 App Open Ad（首次啟動）
        if m_shouldShowOnLoad {
            showAppOpenAdIfAvailable()
        } else {
            guard let backgroundDate = m_backgroundDate else { return }
            let threshold: TimeInterval = 4 * 60 * 60
            if Date().timeIntervalSince(backgroundDate) >= threshold {
                showAppOpenAdIfAvailable()
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    // MARK: - App Open Ad 載入

    func loadAppOpenAd() {
        // 完整版：不載入開屏廣告
        if StoreManager.shared.isPremium { return }
        // 避免重複載入
        guard !m_isAppOpenAdLoading, m_appOpenAd == nil else { return }
        m_isAppOpenAdLoading = true

        AppOpenAd.load(with: m_appOpenAdUnitID, request: Request()) { [weak self] ad, error in
            guard let self = self else { return }
            self.m_isAppOpenAdLoading = false

            if let error = error {
                print("App Open Ad 載入失敗: \(error.localizedDescription)")
                return
            }

            self.m_appOpenAd = ad
            self.m_appOpenAd?.fullScreenContentDelegate = self

            // 只有首次啟動才自動顯示，之後由前景回來的邏輯控制
            if self.m_shouldShowOnLoad {
                self.m_shouldShowOnLoad = false
                self.showAppOpenAdIfAvailable()
            }
        }
    }

    func showAppOpenAdIfAvailable() {
        // 完整版：不顯示開屏廣告
        if StoreManager.shared.isPremium { return }
        guard let rootVC = window?.rootViewController,
              let ad = m_appOpenAd else {
            loadAppOpenAd() // 還沒載入好就預先載入
            return
        }
        ad.present(from: rootVC)
        m_appOpenAd = nil
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // 廣告關閉後清除，並預載下一次用的廣告
        m_appOpenAd = nil
        loadAppOpenAd()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("App Open Ad 顯示失敗: \(error.localizedDescription)")
        m_appOpenAd = nil
        loadAppOpenAd()
    }

}
