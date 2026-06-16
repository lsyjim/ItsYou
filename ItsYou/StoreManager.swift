//
//  StoreManager.swift
//  ItsYou
//
//  StoreKit 2 內購管理（單例）。單一非消耗性商品「完整版」一次買斷永久解鎖。
//  isPremium 一律以 StoreKit 的 currentEntitlements 為真實依據，
//  USER_DEFAULTS("IS_PREMIUM") 僅供 UI 啟動時即時顯示用，每次啟動仍會被覆寫。
//

import Foundation
import StoreKit

final class StoreManager {

    static let shared = StoreManager()

    // 完整版商品 ID（須與 App Store Connect 一致）
    static let productID = "com.howcode.itsyou.full"
    // isPremium 變更時廣播，讓 UI 即時更新
    static let premiumChangedNotification = Notification.Name("ItsYouPremiumChanged")

    // ★★★ 測試開關：改成 true 即可免費解鎖所有付費功能（骰子 / 銅板 / 移除廣告）。
    //     上架前務必改回 false！ ★★★
    static var forcePremium = false

    private var _isPremium: Bool = false          // 只在主線程讀寫
    // 對外的購買狀態：測試開關開啟時一律視為已購買
    var isPremium: Bool { return StoreManager.forcePremium || _isPremium }

    private(set) var product: Product?            // 供升級頁顯示在地化價格

    private var updatesTask: Task<Void, Never>?

    private init() {
        // 先以快取顯示，稍後以 StoreKit 真實狀態覆寫
        _isPremium = USER_DEFAULTS.bool(forKey: "IS_PREMIUM")
    }

    // App 啟動時呼叫：監聽交易更新、載入商品、推導購買狀態
    func start() {
        if updatesTask == nil {
            updatesTask = listenForTransactions()
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    // 載入商品（取得在地化價格）
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            let first = products.first
            DispatchQueue.main.async { self.product = first }
        } catch {
            CLog("載入商品失敗：\(error.localizedDescription)")
        }
    }

    // 以 currentEntitlements 推導是否已購買完整版
    func refreshEntitlements() async {
        var premium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                premium = true
            }
        }
        setPremium(premium)
    }

    // 購買；回傳是否成功解鎖
    func purchase() async -> Bool {
        if product == nil { await loadProducts() }
        guard let product = product else { return false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return false }
                await transaction.finish()
                setPremium(true)
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            CLog("購買失敗：\(error.localizedDescription)")
            return false
        }
    }

    // 還原購買（跨裝置 / 重灌）
    func restore() async -> Bool {
        do {
            try await AppStore.sync()
        } catch {
            CLog("還原失敗：\(error.localizedDescription)")
        }
        await refreshEntitlements()
        return isPremium
    }

    // 常駐監看交易更新（退款、跨裝置、家庭共享）
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    // 更新狀態並快取，有變更時廣播（一律切回主線程）
    private func setPremium(_ value: Bool) {
        DispatchQueue.main.async {
            let changed = self._isPremium != value
            self._isPremium = value
            USER_DEFAULTS.set(value, forKey: "IS_PREMIUM")
            if changed {
                NotificationCenter.default.post(name: Self.premiumChangedNotification, object: nil)
            }
        }
    }
}
