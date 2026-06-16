//
//  PaywallView.swift
//  ItsYou
//
//  升級完整版頁（全螢幕覆蓋層）。
//  條列解鎖項目，價格由 StoreManager.product 在地化顯示（不寫死），含還原購買。
//

import UIKit

class PaywallView: UIView {

    var m_parentObj: UIViewController?

    var m_card: UIView!
    var m_purchaseButton: UIButton!
    var m_restoreButton: UIButton!
    var m_indicator: UIActivityIndicatorView!

    //MARK: - Init
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func refreshWithFrame(_ frame: CGRect) {
        self.frame = frame
        self.backgroundColor = COLOR_BLUR_BLACK
        self.isHidden = true
        self.layoutInit()
    }

    func layoutInit() {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let cardW: CGFloat = isPad ? 460 : SCREEN_WIDTH - 60
        let cardH: CGFloat = 440
        m_card = UIView(frame: CGRect(x: 0, y: 0, width: cardW, height: cardH))
        m_card.center = CGPoint(x: SCREEN_WIDTH / 2, y: SCREEN_HEIGHT / 2)
        m_card.backgroundColor = CTransform.getColorWithHex("f0eff5")
        m_card.layer.cornerRadius = 16
        m_card.layer.masksToBounds = true
        self.addSubview(m_card)

        // 關閉鈕
        let closeButton = UIButton(frame: CGRect(x: cardW - 44, y: 6, width: 38, height: 38))
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(CTransform.getColorWithHex("656565"), for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        closeButton.addTarget(self, action: #selector(PaywallView.hide), for: .touchUpInside)
        m_card.addSubview(closeButton)

        // 標題
        let titleLabel = UILabel(frame: CGRect(x: 16, y: 28, width: cardW - 32, height: 36))
        titleLabel.text = "PaywallTitle".localized
        titleLabel.textAlignment = .center
        titleLabel.textColor = CTransform.getColorWithHex("656565")
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        m_card.addSubview(titleLabel)

        // 解鎖項目條列
        let features = ["PaywallFeatureDice".localized,
                        "PaywallFeatureCoin".localized,
                        "PaywallFeatureNoAds".localized]
        var y: CGFloat = titleLabel.frame.maxY + 24
        for f in features {
            let label = UILabel(frame: CGRect(x: 36, y: y, width: cardW - 60, height: 34))
            label.text = "✓  \(f)"
            label.textColor = CTransform.getColorWithHex("7b8b6f")
            label.font = UIFont.systemFont(ofSize: 18)
            m_card.addSubview(label)
            y += 42
        }

        // 購買鈕
        m_purchaseButton = UIButton(frame: CGRect(x: 30, y: cardH - 130, width: cardW - 60, height: 54))
        m_purchaseButton.backgroundColor = CTransform.getColorWithHex("965454")
        m_purchaseButton.setTitleColor(UIColor.white, for: .normal)
        m_purchaseButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        m_purchaseButton.layer.cornerRadius = 12
        m_purchaseButton.addTarget(self, action: #selector(PaywallView.onPurchaseAction), for: .touchUpInside)
        m_card.addSubview(m_purchaseButton)

        // 還原購買鈕
        m_restoreButton = UIButton(frame: CGRect(x: 30, y: cardH - 66, width: cardW - 60, height: 40))
        m_restoreButton.setTitle("RestorePurchase".localized, for: .normal)
        m_restoreButton.setTitleColor(COLOR_MENU_LIST, for: .normal)
        m_restoreButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        m_restoreButton.addTarget(self, action: #selector(PaywallView.onRestoreAction), for: .touchUpInside)
        m_card.addSubview(m_restoreButton)

        // 載入指示
        m_indicator = UIActivityIndicatorView(style: .medium)
        m_indicator.center = CGPoint(x: cardW / 2, y: cardH - 103)
        m_indicator.hidesWhenStopped = true
        m_card.addSubview(m_indicator)
    }

    //MARK: - Show / Hide
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func show() {
        self.refreshPriceTitle()
        self.isHidden = false
        self.alpha = 0
        UIView.animate(withDuration: 0.2) { self.alpha = 1 }
    }

    @objc func hide() {
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }) { _ in
            self.isHidden = true
        }
    }

    // 價格一律由 StoreKit 在地化顯示，不可寫死
    func refreshPriceTitle() {
        if let product = StoreManager.shared.product {
            m_purchaseButton.setTitle("\("PaywallBuy".localized)  \(product.displayPrice)", for: .normal)
            m_purchaseButton.isEnabled = true
            m_purchaseButton.alpha = 1.0
        } else {
            m_purchaseButton.setTitle("PaywallLoading".localized, for: .normal)
            m_purchaseButton.isEnabled = false
            m_purchaseButton.alpha = 0.6
            // 嘗試重新載入商品
            Task {
                await StoreManager.shared.loadProducts()
                DispatchQueue.main.async { self.refreshPriceTitle() }
            }
        }
    }

    //MARK: - Actions
    //------------------------------------------------------------------------------------------------------------------------------------------------
    @objc func onPurchaseAction() {
        setBusy(true)
        Task {
            let ok = await StoreManager.shared.purchase()
            DispatchQueue.main.async {
                self.setBusy(false)
                if ok {
                    self.showAlert("PurchaseThanks".localized) { self.hide() }
                }
                // 取消或失敗不打擾，使用者可再試
            }
        }
    }

    @objc func onRestoreAction() {
        setBusy(true)
        Task {
            let ok = await StoreManager.shared.restore()
            DispatchQueue.main.async {
                self.setBusy(false)
                if ok {
                    self.showAlert("RestoreSuccess".localized) { self.hide() }
                } else {
                    self.showAlert("RestoreNone".localized, completion: nil)
                }
            }
        }
    }

    private func setBusy(_ busy: Bool) {
        if busy { m_indicator.startAnimating() } else { m_indicator.stopAnimating() }
        m_purchaseButton.isEnabled = !busy
        m_restoreButton.isEnabled = !busy
    }

    private func showAlert(_ message: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        m_parentObj?.present(alert, animated: true)
    }
}
