//
//  CoinView.swift
//  ItsYou
//
//  銅板模式（完整版功能，與其他模式獨立）。
//  版面（上到下）：銅板顯示區 → 翻鈕 → 記錄區 + 清除鈕。
//  兩面文字可自訂（預設 正 / 反），CATransform3D 繞 Y 軸 + 透視翻轉。
//

import UIKit

class CoinView: UIView, UITableViewDataSource, UITableViewDelegate {

    //MARK: - Property
    //------------------------------------------------------------------------------------------------------------------------------------------------
    var m_parentObj: UIViewController?

    var m_coin: UIView!
    var m_faceLabel: UILabel!
    var m_flipButton: UIButton!
    var m_editButton: UIButton!
    var m_historyTable: UITableView!

    var m_isFlipping: Bool = false
    var m_diameter: CGFloat = 0

    let m_frontColor = "c2a878"   // 正面：暖駝
    let m_backColor  = "8d97a6"   // 反面：藍灰

    //MARK: - 資料存取
    //------------------------------------------------------------------------------------------------------------------------------------------------
    var m_front: String {
        get { return USER_DEFAULTS.string(forKey: "COIN_FRONT") ?? "CoinFront".localized }
        set { USER_DEFAULTS.set(newValue, forKey: "COIN_FRONT") }
    }
    var m_back: String {
        get { return USER_DEFAULTS.string(forKey: "COIN_BACK") ?? "CoinBack".localized }
        set { USER_DEFAULTS.set(newValue, forKey: "COIN_BACK") }
    }
    var m_history: [[String: String]] {
        get { return USER_DEFAULTS.array(forKey: "COIN_HISTORY") as? [[String: String]] ?? [] }
        set { USER_DEFAULTS.set(newValue, forKey: "COIN_HISTORY") }
    }

    //MARK: - Init
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func refreshWithFrame(_ frame: CGRect) {
        self.frame = frame
        self.backgroundColor = UIColor.white
        self.layoutInit()
        SoundPlayer.shared.preload("coin_flip")
    }

    func layoutInit() {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let topSafe: CGFloat = 54
        let bottomSafe: CGFloat = SCREEN_HEIGHT - 40

        // 標題
        let titleLabel = UILabel(frame: CGRect(x: 44, y: 12, width: SCREEN_WIDTH - 88, height: 30))
        titleLabel.text = "ModeCoin".localized
        titleLabel.textAlignment = .center
        titleLabel.textColor = CTransform.getColorWithHex("656565")
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        self.addSubview(titleLabel)

        // 銅板顯示區
        m_diameter = min(SCREEN_WIDTH - (isPad ? 200 : 120), isPad ? 240 : 170)
        let coinTop = topSafe + 24
        let coinContainer = UIView(frame: CGRect(x: 0, y: coinTop, width: SCREEN_WIDTH, height: m_diameter))
        // 透視（讓 Y 軸翻轉有立體感）
        var persp = CATransform3DIdentity
        persp.m34 = -1.0 / 500.0
        coinContainer.layer.sublayerTransform = persp
        self.addSubview(coinContainer)

        m_coin = UIView(frame: CGRect(x: 0, y: 0, width: m_diameter, height: m_diameter))
        m_coin.center = CGPoint(x: SCREEN_WIDTH / 2, y: m_diameter / 2)
        m_coin.backgroundColor = CTransform.getColorWithHex(m_frontColor)
        m_coin.layer.cornerRadius = m_diameter / 2
        m_coin.layer.borderWidth = 3
        m_coin.layer.borderColor = CTransform.getColorWithHex("656565").cgColor
        coinContainer.addSubview(m_coin)

        m_faceLabel = UILabel(frame: m_coin.bounds)
        m_faceLabel.textAlignment = .center
        m_faceLabel.textColor = UIColor.white
        m_faceLabel.adjustsFontSizeToFitWidth = true
        m_faceLabel.minimumScaleFactor = 0.3
        m_faceLabel.font = UIFont.systemFont(ofSize: m_diameter * 0.32, weight: .bold)
        m_faceLabel.text = m_front
        m_coin.addSubview(m_faceLabel)

        // 翻鈕（圓鈕）
        let btnW: CGFloat = isPad ? 96 : 72
        m_flipButton = UIButton(frame: CGRect(x: 0, y: 0, width: btnW, height: btnW))
        m_flipButton.center = CGPoint(x: SCREEN_WIDTH / 2, y: coinTop + m_diameter + 20 + btnW / 2)
        m_flipButton.setTitle("CoinFlip".localized, for: .normal)
        m_flipButton.titleLabel?.font = UIFont(name: "Arial Rounded MT Bold", size: isPad ? 24 : 20)
        m_flipButton.setTitleColor(UIColor.black, for: .highlighted)
        m_flipButton.backgroundColor = CTransform.getColorWithHex("7b8b6f")
        m_flipButton.layer.cornerRadius = btnW / 2
        m_flipButton.layer.masksToBounds = true
        m_flipButton.layer.borderWidth = 2
        m_flipButton.layer.borderColor = CTransform.getColorWithHex("656565").cgColor
        m_flipButton.addTarget(self, action: #selector(CoinView.onFlipAction), for: .touchUpInside)
        self.addSubview(m_flipButton)

        // 編輯兩面文字鈕
        let editW: CGFloat = isPad ? 96 : 80
        let editH: CGFloat = isPad ? 44 : 38
        m_editButton = UIButton(frame: CGRect(x: SCREEN_WIDTH - editW - 16, y: m_flipButton.center.y - editH / 2, width: editW, height: editH))
        m_editButton.setTitle("WheelEdit".localized, for: .normal)
        m_editButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        m_editButton.setTitleColor(CTransform.getColorWithHex("656565"), for: .normal)
        m_editButton.layer.cornerRadius = 6
        m_editButton.layer.borderWidth = 2
        m_editButton.layer.borderColor = CTransform.getColorWithHex("656565").cgColor
        m_editButton.addTarget(self, action: #selector(CoinView.onEditFacesAction), for: .touchUpInside)
        self.addSubview(m_editButton)

        // 記錄區標題 + 清除
        let historyTop = m_flipButton.frame.maxY + 14
        let headerH: CGFloat = 30
        let historyLabel = UILabel(frame: CGRect(x: 12, y: historyTop, width: SCREEN_WIDTH / 2, height: headerH))
        historyLabel.text = "WheelHistory".localized
        historyLabel.textColor = CTransform.getColorWithHex("656565")
        historyLabel.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(historyLabel)

        let clearButton = UIButton(frame: CGRect(x: SCREEN_WIDTH - 16 - 70, y: historyTop, width: 70, height: headerH))
        clearButton.setTitle("WheelClear".localized, for: .normal)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        clearButton.setTitleColor(CTransform.getColorWithHex("965454"), for: .normal)
        clearButton.contentHorizontalAlignment = .right
        clearButton.addTarget(self, action: #selector(CoinView.onClearAction), for: .touchUpInside)
        self.addSubview(clearButton)

        let tableY = historyTop + headerH + 4
        m_historyTable = UITableView(frame: CGRect(x: 0, y: tableY, width: SCREEN_WIDTH, height: max(0, bottomSafe - tableY - 6)))
        m_historyTable.backgroundColor = CTransform.getColorWithHex("f0eff5")
        m_historyTable.dataSource = self
        m_historyTable.delegate = self
        m_historyTable.rowHeight = 40
        m_historyTable.register(UITableViewCell.self, forCellReuseIdentifier: "coinCell")
        self.addSubview(m_historyTable)

        let line = UIView(frame: CGRect(x: 0, y: tableY - 1, width: SCREEN_WIDTH, height: 1))
        line.backgroundColor = COLOR_LINE_GREY
        self.addSubview(line)
    }

    //MARK: - 翻面
    //------------------------------------------------------------------------------------------------------------------------------------------------
    @objc func onFlipAction() {
        if m_isFlipping { return }
        m_isFlipping = true
        m_flipButton.isEnabled = false
        m_editButton.isEnabled = false

        SoundPlayer.shared.play("coin_flip")

        // 先亂數決定結果
        let isFront = (arc4random_uniform(2) == 0)
        let resultText = isFront ? m_front : m_back
        let resultColor = isFront ? m_frontColor : m_backColor

        // 共 5 次換面，約 0.7 秒（每次 = 兩個 1/4 轉，於邊緣換字避免鏡像）
        self.performFlip(changesLeft: 5, resultText: resultText, resultColor: resultColor) { [weak self] in
            guard let self = self else { return }
            self.finishFlip(resultText)
        }
    }

    // 遞迴半翻：每次先轉到邊緣（看不見）換字，再轉回正面，文字永不鏡像
    private func performFlip(changesLeft: Int, resultText: String, resultColor: String, completion: @escaping () -> Void) {
        if changesLeft == 0 {
            completion()
            return
        }
        let isLast = (changesLeft == 1)
        let nextText = isLast ? resultText : (m_faceLabel.text == m_front ? m_back : m_front)
        let nextColor = isLast ? resultColor : (m_faceLabel.text == m_front ? m_backColor : m_frontColor)
        let q: CFTimeInterval = 0.07

        // 1/4：0 → π/2（轉到邊緣）
        animateRotationY(from: 0, to: .pi / 2, duration: q) { [weak self] in
            guard let self = self else { return }
            // 邊緣換字換色，並瞬間跳到 -π/2（同樣邊緣，避免背面鏡像）
            self.m_faceLabel.text = nextText
            self.m_coin.backgroundColor = CTransform.getColorWithHex(nextColor)
            self.setRotationYInstant(-.pi / 2)
            // 1/4：-π/2 → 0（轉回正面）
            self.animateRotationY(from: -.pi / 2, to: 0, duration: q) {
                self.performFlip(changesLeft: changesLeft - 1, resultText: resultText, resultColor: resultColor, completion: completion)
            }
        }
    }

    private func animateRotationY(from: CGFloat, to: CGFloat, duration: CFTimeInterval, completion: @escaping () -> Void) {
        let anim = CABasicAnimation(keyPath: "transform.rotation.y")
        anim.fromValue = from
        anim.toValue = to
        anim.duration = duration
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self else { return }
            self.m_coin.layer.transform = CATransform3DMakeRotation(to, 0, 1, 0)
            self.m_coin.layer.removeAnimation(forKey: "flip")
            completion()
        }
        m_coin.layer.add(anim, forKey: "flip")
        CATransaction.commit()
    }

    private func setRotationYInstant(_ angle: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        m_coin.layer.transform = CATransform3DMakeRotation(angle, 0, 1, 0)
        CATransaction.commit()
    }

    func finishFlip(_ resultText: String) {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd HH:mm"
        var history = m_history
        history.insert(["time": fmt.string(from: Date()), "result": resultText], at: 0)
        m_history = history
        m_historyTable.reloadData()

        CLog("銅板結果：\(resultText)")
        m_isFlipping = false
        m_flipButton.isEnabled = true
        m_editButton.isEnabled = true
    }

    //MARK: - 編輯兩面文字
    //------------------------------------------------------------------------------------------------------------------------------------------------
    @objc func onEditFacesAction() {
        if m_isFlipping { return }
        let alert = UIAlertController(title: "CoinEditTitle".localized, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = self.m_front
            tf.placeholder = "CoinFront".localized
        }
        alert.addTextField { tf in
            tf.text = self.m_back
            tf.placeholder = "CoinBack".localized
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let f = alert?.textFields?.first?.text ?? ""
            let b = alert?.textFields?.last?.text ?? ""
            if !f.isEmpty { self.m_front = f }
            if !b.isEmpty { self.m_back = b }
            // 目前顯示面同步更新文字
            self.m_faceLabel.text = (self.m_coin.backgroundColor == CTransform.getColorWithHex(self.m_backColor)) ? self.m_back : self.m_front
        })
        m_parentObj?.present(alert, animated: true)
    }

    @objc func onClearAction() {
        if m_history.isEmpty { return }
        let alert = UIAlertController(title: "WheelClearConfirm".localized, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "OK", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.m_history = []
            self.m_historyTable.reloadData()
        })
        m_parentObj?.present(alert, animated: true)
    }

    //MARK: - UITableView
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return m_history.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "coinCell", for: indexPath)
        let item = m_history[indexPath.row]
        cell.textLabel?.text = "\(item["time"] ?? "")   \(item["result"] ?? "")"
        cell.textLabel?.textColor = CTransform.getColorWithHex("656565")
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.backgroundColor = CTransform.getColorWithHex("f0eff5")
        cell.selectionStyle = .none
        return cell
    }
}
