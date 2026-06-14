//
//  WheelView.swift
//  ItsYou
//
//  轉盤抽籤模組（完全獨立於數字抽籤邏輯）
//  版面由上到下：指針 → 轉盤本體 → 開始 / 編輯鈕 → 記錄區
//  整體避開頂部 44pt 按鈕列與底部 40pt 廣告列
//

import UIKit

class WheelView: UIView, UITableViewDataSource, UITableViewDelegate {

    //MARK: - Property
    //------------------------------------------------------------------------------------------------------------------------------------------------
    var m_parentObj: UIViewController?           // 老爸（用來 present alert）
    var m_onEditToggle: ((Bool) -> Void)?        // 編輯介面開 / 關回呼（讓老爸隱藏頂部按鈕）
    var m_onWantAd: (() -> Void)?                // 請老爸開插頁廣告（轉盤結束 1/20 機率）

    // 轉盤本體（旋轉的容器，含扇形與文字）
    var m_wheelContainer: UIView!
    var m_pointer: UIView!
    var m_startButton: UIButton!
    var m_editButton: UIButton!

    // 記錄區
    var m_historyTable: UITableView!
    var m_clearButton: UIButton!

    // 編輯介面（滑入式覆蓋層）
    var m_editOverlay: UIView!
    var m_editTable: UITableView!

    // 標題列（顯示當前主題名稱）
    var m_navBar: UINavigationBar!
    var m_navItem: UINavigationItem!

    var m_diameter: CGFloat = 0                  // 轉盤直徑
    var m_currentRotation: Double = 0            // 目前累積旋轉角度（弧度）
    var m_isSpinning: Bool = false               // 轉動中鎖定，避免重複觸發

    // 莫蘭迪四色（沿用 Draw / Reset 兩色，另補兩色）
    let m_colors: [String] = ["965454", "7b8b6f", "c2a878", "8d97a6"]

    //MARK: - 資料存取（持久化到 USER_DEFAULTS）
    //------------------------------------------------------------------------------------------------------------------------------------------------
    // 轉盤項目 = 當前主題的內容
    var m_items: [String] {
        get {
            let themes = wheelThemes()
            let idx = wheelCurrentIndex()
            if idx < themes.count { return themes[idx]["items"] as? [String] ?? [] }
            return []
        }
        set {
            var themes = wheelThemes()
            let idx = wheelCurrentIndex()
            if idx < themes.count {
                themes[idx]["items"] = newValue
                setWheelThemes(themes)
            }
        }
    }

    var m_history: [[String: String]] {
        get { return USER_DEFAULTS.array(forKey: "WHEEL_HISTORY") as? [[String: String]] ?? [] }
        set { USER_DEFAULTS.set(newValue, forKey: "WHEEL_HISTORY") }
    }

    //MARK: - Init
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func refreshWithFrame(_ frame: CGRect) {
        self.frame = frame
        self.backgroundColor = UIColor.white

        // 首次啟動 / 舊版升級：確保至少有一個主題
        ensureWheelThemesInited()

        self.layoutInit()
    }

    func layoutInit() {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        let topSafe: CGFloat = 54                       // 避開頂部 44pt 按鈕列（y:10 高 44）
        let bottomSafe: CGFloat = SCREEN_HEIGHT - 40    // 避開底部 40pt 廣告列
        let avail = bottomSafe - topSafe

        // 標題列：顯示當前主題名稱（置於頂部，左右仍露出 ☰ / ⚙）
        m_navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: topSafe))
        m_navBar.isTranslucent = false
        m_navBar.barTintColor = UIColor.white
        m_navBar.titleTextAttributes = [.foregroundColor: CTransform.getColorWithHex("656565")]
        m_navItem = UINavigationItem(title: wheelCurrentThemeName())
        m_navBar.items = [m_navItem]
        self.addSubview(m_navBar)

        // 指針
        let pointerH: CGFloat = isPad ? 28 : 20
        let pointerW: CGFloat = pointerH

        // 轉盤直徑：取螢幕寬與可用高的較小者，避免過大
        m_diameter = min(SCREEN_WIDTH - (isPad ? 160 : 70), avail * 0.5)
        let wheelTop = topSafe + 10 + pointerH
        let wheelCenterX = SCREEN_WIDTH / 2
        let wheelCenterY = wheelTop + m_diameter / 2

        // 轉盤容器（旋轉用）
        m_wheelContainer = UIView(frame: CGRect(x: 0, y: 0, width: m_diameter, height: m_diameter))
        m_wheelContainer.center = CGPoint(x: wheelCenterX, y: wheelCenterY)
        self.addSubview(m_wheelContainer)

        // 點轉盤中心也能觸發
        let tap = UITapGestureRecognizer(target: self, action: #selector(WheelView.onStartAction))
        m_wheelContainer.addGestureRecognizer(tap)

        // 頂部朝下的三角指針
        m_pointer = UIView(frame: CGRect(x: wheelCenterX - pointerW / 2,
                                         y: wheelTop - pointerH + 4,
                                         width: pointerW, height: pointerH))
        m_pointer.backgroundColor = UIColor.clear
        let triangle = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: pointerW, y: 0))
        path.addLine(to: CGPoint(x: pointerW / 2, y: pointerH))
        path.close()
        triangle.path = path.cgPath
        triangle.fillColor = CTransform.getColorWithHex("656565").cgColor
        m_pointer.layer.addSublayer(triangle)
        self.addSubview(m_pointer)

        // 開始鈕（沿用既有圓鈕風格）
        let btnW: CGFloat = isPad ? 96 : 72
        let startCenterY = wheelTop + m_diameter + 12 + btnW / 2
        m_startButton = UIButton(frame: CGRect(x: 0, y: 0, width: btnW, height: btnW))
        m_startButton.center = CGPoint(x: wheelCenterX, y: startCenterY)
        m_startButton.setTitle("WheelStart".localized, for: UIControl.State())
        m_startButton.titleLabel?.font = UIFont(name: "Arial Rounded MT Bold", size: isPad ? 24 : 20)
        m_startButton.setTitleColor(UIColor.black, for: .highlighted)
        m_startButton.backgroundColor = CTransform.getColorWithHex("c2a878")
        m_startButton.layer.cornerRadius = btnW / 2
        m_startButton.layer.masksToBounds = true
        m_startButton.layer.borderWidth = 2
        m_startButton.layer.borderColor = CTransform.getColorWithHex("656565").cgColor
        m_startButton.addTarget(self, action: #selector(WheelView.onStartAction), for: .touchUpInside)
        self.addSubview(m_startButton)

        // 編輯鈕（圓角邊框小鈕，置於開始鈕右側）
        let editW: CGFloat = isPad ? 96 : 80
        let editH: CGFloat = isPad ? 44 : 38
        m_editButton = UIButton(frame: CGRect(x: SCREEN_WIDTH - editW - 16,
                                              y: startCenterY - editH / 2,
                                              width: editW, height: editH))
        m_editButton.setTitle("WheelEdit".localized, for: UIControl.State())
        m_editButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        m_editButton.setTitleColor(CTransform.getColorWithHex("656565"), for: UIControl.State())
        m_editButton.layer.cornerRadius = 6
        m_editButton.layer.borderWidth = 2
        m_editButton.layer.borderColor = CTransform.getColorWithHex("656565").cgColor
        m_editButton.addTarget(self, action: #selector(WheelView.onEditAction), for: .touchUpInside)
        self.addSubview(m_editButton)

        // 記錄區標題列：標題 + 清除鈕
        let historyTop = startCenterY + btnW / 2 + 12
        let headerH: CGFloat = 30
        let historyLabel = UILabel(frame: CGRect(x: 12, y: historyTop, width: SCREEN_WIDTH / 2, height: headerH))
        historyLabel.text = "WheelHistory".localized
        historyLabel.textColor = CTransform.getColorWithHex("656565")
        historyLabel.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(historyLabel)

        m_clearButton = UIButton(frame: CGRect(x: SCREEN_WIDTH - 16 - 70, y: historyTop, width: 70, height: headerH))
        m_clearButton.setTitle("WheelClear".localized, for: UIControl.State())
        m_clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        m_clearButton.setTitleColor(CTransform.getColorWithHex("965454"), for: UIControl.State())
        m_clearButton.contentHorizontalAlignment = .right
        m_clearButton.addTarget(self, action: #selector(WheelView.onClearAction), for: .touchUpInside)
        self.addSubview(m_clearButton)

        // 記錄區捲動清單
        let tableY = historyTop + headerH + 4
        let tableH = bottomSafe - tableY - 6
        m_historyTable = UITableView(frame: CGRect(x: 0, y: tableY, width: SCREEN_WIDTH, height: max(0, tableH)))
        m_historyTable.backgroundColor = CTransform.getColorWithHex("f0eff5")
        m_historyTable.dataSource = self
        m_historyTable.delegate = self
        m_historyTable.separatorStyle = .singleLine
        m_historyTable.rowHeight = 40
        m_historyTable.register(UITableViewCell.self, forCellReuseIdentifier: "historyCell")
        self.addSubview(m_historyTable)

        // 分隔線（與記錄區上緣對齊，沿用既有風格）
        let line = UIView(frame: CGRect(x: 0, y: tableY - 1, width: SCREEN_WIDTH, height: 1))
        line.backgroundColor = COLOR_LINE_GREY
        self.addSubview(line)

        // 編輯覆蓋層（預設隱藏於畫面外）
        self.buildEditOverlay()

        // 繪製轉盤
        self.drawWheel()
    }

    // 主題變更後刷新：更新標題與重繪轉盤
    func refreshTheme() {
        m_navItem.title = wheelCurrentThemeName()
        self.drawWheel()
    }

    //MARK: - 轉盤繪製
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func drawWheel() {
        // 清掉舊的扇形與文字
        m_wheelContainer.layer.sublayers?.removeAll()
        for sub in m_wheelContainer.subviews { sub.removeFromSuperview() }

        let items = m_items
        let n = items.count
        let center = CGPoint(x: m_diameter / 2, y: m_diameter / 2)
        let radius = m_diameter / 2

        // 項目不足時畫個空圈提示
        if n == 0 {
            let circle = CAShapeLayer()
            circle.path = UIBezierPath(ovalIn: m_wheelContainer.bounds).cgPath
            circle.fillColor = CTransform.getColorWithHex("f0eff5").cgColor
            circle.strokeColor = CTransform.getColorWithHex("656565").cgColor
            circle.lineWidth = 1
            m_wheelContainer.layer.addSublayer(circle)
            return
        }

        let baseStart = -Double.pi / 2          // 從正上方（指針處）開始切
        let sector = 2 * Double.pi / Double(n)

        for i in 0..<n {
            let a0 = baseStart + Double(i) * sector
            let a1 = a0 + sector

            // 扇形
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center, radius: radius,
                        startAngle: CGFloat(a0), endAngle: CGFloat(a1), clockwise: true)
            path.close()

            let shape = CAShapeLayer()
            shape.path = path.cgPath
            shape.fillColor = CTransform.getColorWithHex(m_colors[i % m_colors.count]).cgColor
            shape.strokeColor = UIColor.white.cgColor      // 白色細分隔線 1pt
            shape.lineWidth = 1
            m_wheelContainer.layer.addSublayer(shape)

            // 文字（沿用 656565 文字色，每格置中）
            let mid = a0 + sector / 2
            let labelRadius = radius * 0.58
            let lw = m_diameter * 0.4
            let lh: CGFloat = 24
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: lw, height: lh))
            label.text = items[i]
            label.textColor = UIColor.white        // 白色字，與莫蘭迪底色對比更強
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 14)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.4
            label.center = CGPoint(x: center.x + labelRadius * CGFloat(cos(mid)),
                                   y: center.y + labelRadius * CGFloat(sin(mid)))
            label.transform = CGAffineTransform(rotationAngle: CGFloat(mid))
            m_wheelContainer.addSubview(label)
        }
    }

    //MARK: - Actions
    //------------------------------------------------------------------------------------------------------------------------------------------------
    @objc func onStartAction() {
        if m_isSpinning { return }                       // 轉動中鎖定

        let items = m_items
        if items.count < 2 {
            self.showAlert("WheelNeedTwo".localized)     // 少於 2 項提示
            return
        }

        m_isSpinning = true
        m_startButton.isEnabled = false
        m_editButton.isEnabled = false

        let n = items.count
        let sector = 2 * Double.pi / Double(n)

        // 先以亂數決定中獎格，再反推最終角度讓指針停在該格
        let win = Int(arc4random_uniform(UInt32(n)))
        let baseStart = -Double.pi / 2
        let mid = baseStart + (Double(win) + 0.5) * sector
        // 在格內加入少許亂數抖動，避免每次都停在正中央，但仍落在該格內
        let jitter = Double.random(in: -sector * 0.3...sector * 0.3)
        let target = mid + jitter

        // 指針在正上方（-π/2）；旋轉後要讓 target 落到 -π/2
        let desired = -Double.pi / 2 - target
        let base = m_currentRotation + 2 * Double.pi * 5     // 至少多轉 5 圈
        var delta = (desired - base).truncatingRemainder(dividingBy: 2 * Double.pi)
        if delta < 0 { delta += 2 * Double.pi }
        let final = base + delta

        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.fromValue = m_currentRotation
        anim.toValue = final
        anim.duration = 4.0
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)   // ease-out 緩停
        anim.isRemovedOnCompletion = false
        anim.fillMode = .forwards

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            guard let self = self else { return }
            // 固定到最終角度並移除動畫，避免閃跳
            self.m_wheelContainer.transform = CGAffineTransform(rotationAngle: CGFloat(final))
            self.m_wheelContainer.layer.removeAnimation(forKey: "spin")
            self.m_currentRotation = final
            self.m_isSpinning = false
            self.m_startButton.isEnabled = true
            self.m_editButton.isEnabled = true
            self.didFinishSpin(result: items[win])
        }
        m_wheelContainer.layer.add(anim, forKey: "spin")
        CATransaction.commit()
    }

    // 轉動結束：顯示結果並寫入記錄
    func didFinishSpin(result: String) {
        CLog("轉盤結果：\(result)")

        // 寫入記錄（最新置頂）
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd HH:mm"
        var history = m_history
        history.insert(["time": fmt.string(from: Date()), "result": result], at: 0)
        m_history = history
        m_historyTable.reloadData()

        // 轉盤結束是用戶主動觸發的自然斷點，沿用數字抽籤的 1/20 機率彈出插頁廣告
        let shouldAd = (arc4random() % 20 == 0)

        // 彈出中獎項目；按 OK 後再開廣告，避免與結果彈窗同時 present 造成衝突
        let alert = UIAlertController(title: "\("WheelResult".localized)\(result)", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if shouldAd { self?.m_onWantAd?() }
        })
        m_parentObj?.present(alert, animated: true)
    }

    @objc func onEditAction() {
        m_editTable.reloadData()
        m_onEditToggle?(true)        // 隱藏頂部按鈕，避免誤觸
        UIView.animate(withDuration: 0.25) {
            self.m_editOverlay.frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        }
    }

    @objc func onEditDoneAction() {
        m_onEditToggle?(false)       // 還原頂部按鈕
        UIView.animate(withDuration: 0.25, animations: {
            self.m_editOverlay.frame = CGRect(x: SCREEN_WIDTH, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        }, completion: { _ in
            // 關閉編輯後重繪轉盤
            self.drawWheel()
        })
    }

    @objc func onAddAction() {
        let alert = UIAlertController(title: "WheelEditTitle".localized, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "WheelInputPlaceholder".localized
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let text = alert?.textFields?.first?.text ?? ""
            if text.isEmpty { return }
            var items = self.m_items
            items.append(text)
            self.m_items = items
            self.m_editTable.reloadData()
        })
        m_parentObj?.present(alert, animated: true)
    }

    @objc func onClearAction() {
        if m_history.isEmpty { return }
        // 二次確認
        let alert = UIAlertController(title: "WheelClearConfirm".localized, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "OK", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.m_history = []
            self.m_historyTable.reloadData()
        })
        m_parentObj?.present(alert, animated: true)
    }

    // 點擊清單項目 → 修改文字
    func renameItem(at index: Int) {
        let items = m_items
        if index >= items.count { return }
        let alert = UIAlertController(title: "WheelEditTitle".localized, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = items[index]
            tf.placeholder = "WheelInputPlaceholder".localized
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let text = alert?.textFields?.first?.text ?? ""
            if text.isEmpty { return }
            var items = self.m_items
            items[index] = text
            self.m_items = items
            self.m_editTable.reloadData()
        })
        m_parentObj?.present(alert, animated: true)
    }

    //MARK: - 編輯覆蓋層
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func buildEditOverlay() {
        m_editOverlay = UIView(frame: CGRect(x: SCREEN_WIDTH, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        m_editOverlay.backgroundColor = CTransform.getColorWithHex("f0eff5")
        self.addSubview(m_editOverlay)

        let barH: CGFloat = 50
        let topPad: CGFloat = 20
        // 完成鈕（左）
        let doneButton = UIButton(frame: CGRect(x: 8, y: topPad, width: 80, height: barH))
        doneButton.setTitle("WheelDone".localized, for: UIControl.State())
        doneButton.setTitleColor(COLOR_MENU_LIST, for: UIControl.State())
        doneButton.contentHorizontalAlignment = .left
        doneButton.addTarget(self, action: #selector(WheelView.onEditDoneAction), for: .touchUpInside)
        m_editOverlay.addSubview(doneButton)

        // 標題（中）
        let titleLabel = UILabel(frame: CGRect(x: 88, y: topPad, width: SCREEN_WIDTH - 176, height: barH))
        titleLabel.text = "WheelEditTitle".localized
        titleLabel.textAlignment = .center
        titleLabel.textColor = CTransform.getColorWithHex("656565")
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        m_editOverlay.addSubview(titleLabel)

        // 新增鈕（右）
        let addButton = UIButton(frame: CGRect(x: SCREEN_WIDTH - 88, y: topPad, width: 80, height: barH))
        addButton.setTitle("WheelAdd".localized, for: UIControl.State())
        addButton.setTitleColor(COLOR_MENU_LIST, for: UIControl.State())
        addButton.contentHorizontalAlignment = .right
        addButton.addTarget(self, action: #selector(WheelView.onAddAction), for: .touchUpInside)
        m_editOverlay.addSubview(addButton)

        let editTableY = topPad + barH
        m_editTable = UITableView(frame: CGRect(x: 0, y: editTableY, width: SCREEN_WIDTH,
                                                height: SCREEN_HEIGHT - editTableY))
        m_editTable.backgroundColor = CTransform.getColorWithHex("f0eff5")
        m_editTable.dataSource = self
        m_editTable.delegate = self
        m_editTable.rowHeight = 48
        m_editTable.register(UITableViewCell.self, forCellReuseIdentifier: "editCell")
        m_editOverlay.addSubview(m_editTable)
    }

    //MARK: - UITableView DataSource / Delegate
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == m_editTable {
            return m_items.count
        }
        return m_history.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == m_editTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "editCell", for: indexPath)
            cell.textLabel?.text = m_items[indexPath.row]
            cell.textLabel?.textColor = CTransform.getColorWithHex("656565")
            cell.backgroundColor = UIColor.white
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath)
        let item = m_history[indexPath.row]
        cell.textLabel?.text = "\(item["time"] ?? "")   \(item["result"] ?? "")"
        cell.textLabel?.textColor = CTransform.getColorWithHex("656565")
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.backgroundColor = CTransform.getColorWithHex("f0eff5")
        cell.selectionStyle = .none
        return cell
    }

    // 點擊（僅編輯清單）→ 修改文字
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == m_editTable {
            self.renameItem(at: indexPath.row)
        }
    }

    // 左滑刪除（僅編輯清單）
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return tableView == m_editTable
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if tableView == m_editTable && editingStyle == .delete {
            var items = m_items
            items.remove(at: indexPath.row)
            m_items = items
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    //MARK: - Normal Function
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        m_parentObj?.present(alert, animated: true)
    }
}
