//
//  DiceView.swift
//  ItsYou
//
//  骰子模式（完整版功能，與其他模式獨立）。
//  版面（上到下）：骰子顯示區 → 數量選擇(− 數字 +，1～6) → 擲骰鈕 → 記錄區 + 清除鈕。
//  整體避開頂部 44pt 與底部 40pt 廣告。
//

import UIKit

class DiceView: UIView, UITableViewDataSource, UITableViewDelegate {

    //MARK: - Property
    //------------------------------------------------------------------------------------------------------------------------------------------------
    var m_parentObj: UIViewController?

    var m_diceContainer: UIView!
    var m_dieViews: [DieView] = []
    var m_countLabel: UILabel!
    var m_rollButton: UIButton!
    var m_sumLabel: UILabel!
    var m_historyTable: UITableView!

    var m_isRolling: Bool = false
    var m_rollTimer: Timer?

    let m_colors: [String] = ["965454", "7b8b6f", "c2a878", "8d97a6"]

    //MARK: - 資料存取
    //------------------------------------------------------------------------------------------------------------------------------------------------
    var m_count: Int {
        get {
            let c = USER_DEFAULTS.integer(forKey: "DICE_COUNT")
            return (c < 1) ? 1 : min(c, 6)   // 1～6，預設 1
        }
        set { USER_DEFAULTS.set(min(max(newValue, 1), 6), forKey: "DICE_COUNT") }
    }

    var m_history: [[String: String]] {
        get { return USER_DEFAULTS.array(forKey: "DICE_HISTORY") as? [[String: String]] ?? [] }
        set { USER_DEFAULTS.set(newValue, forKey: "DICE_HISTORY") }
    }

    //MARK: - Init
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func refreshWithFrame(_ frame: CGRect) {
        self.frame = frame
        self.backgroundColor = UIColor.white
        self.layoutInit()
        SoundPlayer.shared.preload("dice_roll")
    }

    func layoutInit() {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let topSafe: CGFloat = 54
        let bottomSafe: CGFloat = SCREEN_HEIGHT - 40

        // 標題
        let titleLabel = UILabel(frame: CGRect(x: 44, y: 12, width: SCREEN_WIDTH - 88, height: 30))
        titleLabel.text = "ModeDice".localized
        titleLabel.textAlignment = .center
        titleLabel.textColor = CTransform.getColorWithHex("656565")
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        self.addSubview(titleLabel)

        // 骰子顯示區
        let diceAreaTop: CGFloat = topSafe + 10
        let diceAreaH: CGFloat = isPad ? 220 : 150
        m_diceContainer = UIView(frame: CGRect(x: 0, y: diceAreaTop, width: SCREEN_WIDTH, height: diceAreaH))
        self.addSubview(m_diceContainer)

        // 總和標籤
        m_sumLabel = UILabel(frame: CGRect(x: 0, y: diceAreaTop + diceAreaH, width: SCREEN_WIDTH, height: 30))
        m_sumLabel.textAlignment = .center
        m_sumLabel.textColor = CTransform.getColorWithHex("656565")
        m_sumLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        self.addSubview(m_sumLabel)

        // 數量選擇（− 數字 +）
        let selectorY = m_sumLabel.frame.maxY + 10
        let selBtnW: CGFloat = 44
        let minusButton = UIButton(frame: CGRect(x: SCREEN_WIDTH/2 - 80, y: selectorY, width: selBtnW, height: selBtnW))
        minusButton.setTitle("−", for: .normal)
        minusButton.titleLabel?.font = UIFont.systemFont(ofSize: 28)
        minusButton.setTitleColor(CTransform.getColorWithHex("656565"), for: .normal)
        minusButton.layer.borderColor = CTransform.getColorWithHex("656565").cgColor
        minusButton.layer.borderWidth = 2
        minusButton.layer.cornerRadius = 8
        minusButton.addTarget(self, action: #selector(DiceView.onMinusAction), for: .touchUpInside)
        self.addSubview(minusButton)

        m_countLabel = UILabel(frame: CGRect(x: SCREEN_WIDTH/2 - 30, y: selectorY, width: 60, height: selBtnW))
        m_countLabel.textAlignment = .center
        m_countLabel.textColor = CTransform.getColorWithHex("656565")
        m_countLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        m_countLabel.text = "\(m_count)"
        self.addSubview(m_countLabel)

        let plusButton = UIButton(frame: CGRect(x: SCREEN_WIDTH/2 + 36, y: selectorY, width: selBtnW, height: selBtnW))
        plusButton.setTitle("+", for: .normal)
        plusButton.titleLabel?.font = UIFont.systemFont(ofSize: 26)
        plusButton.setTitleColor(CTransform.getColorWithHex("656565"), for: .normal)
        plusButton.layer.borderColor = CTransform.getColorWithHex("656565").cgColor
        plusButton.layer.borderWidth = 2
        plusButton.layer.cornerRadius = 8
        plusButton.addTarget(self, action: #selector(DiceView.onPlusAction), for: .touchUpInside)
        self.addSubview(plusButton)

        // 擲骰鈕（沿用圓鈕風格）
        let btnW: CGFloat = isPad ? 96 : 72
        m_rollButton = UIButton(frame: CGRect(x: 0, y: 0, width: btnW, height: btnW))
        m_rollButton.center = CGPoint(x: SCREEN_WIDTH/2, y: selectorY + selBtnW + 12 + btnW/2)
        m_rollButton.setTitle("DiceRoll".localized, for: .normal)
        m_rollButton.titleLabel?.font = UIFont(name: "Arial Rounded MT Bold", size: isPad ? 22 : 18)
        m_rollButton.setTitleColor(UIColor.black, for: .highlighted)
        m_rollButton.backgroundColor = CTransform.getColorWithHex("965454")
        m_rollButton.layer.cornerRadius = btnW/2
        m_rollButton.layer.masksToBounds = true
        m_rollButton.layer.borderWidth = 2
        m_rollButton.layer.borderColor = CTransform.getColorWithHex("656565").cgColor
        m_rollButton.addTarget(self, action: #selector(DiceView.onRollAction), for: .touchUpInside)
        self.addSubview(m_rollButton)

        // 記錄區標題 + 清除
        let historyTop = m_rollButton.frame.maxY + 14
        let headerH: CGFloat = 30
        let historyLabel = UILabel(frame: CGRect(x: 12, y: historyTop, width: SCREEN_WIDTH/2, height: headerH))
        historyLabel.text = "WheelHistory".localized
        historyLabel.textColor = CTransform.getColorWithHex("656565")
        historyLabel.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(historyLabel)

        let clearButton = UIButton(frame: CGRect(x: SCREEN_WIDTH - 16 - 70, y: historyTop, width: 70, height: headerH))
        clearButton.setTitle("WheelClear".localized, for: .normal)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        clearButton.setTitleColor(CTransform.getColorWithHex("965454"), for: .normal)
        clearButton.contentHorizontalAlignment = .right
        clearButton.addTarget(self, action: #selector(DiceView.onClearAction), for: .touchUpInside)
        self.addSubview(clearButton)

        let tableY = historyTop + headerH + 4
        m_historyTable = UITableView(frame: CGRect(x: 0, y: tableY, width: SCREEN_WIDTH, height: max(0, bottomSafe - tableY - 6)))
        m_historyTable.backgroundColor = CTransform.getColorWithHex("f0eff5")
        m_historyTable.dataSource = self
        m_historyTable.delegate = self
        m_historyTable.rowHeight = 40
        m_historyTable.register(UITableViewCell.self, forCellReuseIdentifier: "diceCell")
        self.addSubview(m_historyTable)

        let line = UIView(frame: CGRect(x: 0, y: tableY - 1, width: SCREEN_WIDTH, height: 1))
        line.backgroundColor = COLOR_LINE_GREY
        self.addSubview(line)

        self.rebuildDice(values: Array(repeating: 1, count: m_count))
    }

    //MARK: - 骰子排列與繪製
    //------------------------------------------------------------------------------------------------------------------------------------------------
    func rebuildDice(values: [Int]) {
        for v in m_dieViews { v.removeFromSuperview() }
        m_dieViews.removeAll()

        let count = values.count
        let spacing: CGFloat = 12
        let areaW = m_diceContainer.frame.width - spacing * CGFloat(count + 1)
        let maxDie = m_diceContainer.frame.height
        let dieSize = min(maxDie, areaW / CGFloat(count))
        let totalW = dieSize * CGFloat(count) + spacing * CGFloat(count - 1)
        var x = (m_diceContainer.frame.width - totalW) / 2
        let y = (m_diceContainer.frame.height - dieSize) / 2

        for i in 0..<count {
            let die = DieView(frame: CGRect(x: x, y: y, width: dieSize, height: dieSize))
            die.pipColor = CTransform.getColorWithHex(m_colors[i % m_colors.count])
            die.value = values[i]
            m_diceContainer.addSubview(die)
            m_dieViews.append(die)
            x += dieSize + spacing
        }
    }

    func setDiceValues(_ values: [Int]) {
        for (i, v) in values.enumerated() where i < m_dieViews.count {
            m_dieViews[i].value = v
        }
    }

    //MARK: - Actions
    //------------------------------------------------------------------------------------------------------------------------------------------------
    @objc func onMinusAction() {
        if m_isRolling { return }
        if m_count > 1 {
            m_count -= 1
            m_countLabel.text = "\(m_count)"
            m_sumLabel.text = ""
            rebuildDice(values: Array(repeating: 1, count: m_count))
        }
    }

    @objc func onPlusAction() {
        if m_isRolling { return }
        if m_count < 6 {
            m_count += 1
            m_countLabel.text = "\(m_count)"
            m_sumLabel.text = ""
            rebuildDice(values: Array(repeating: 1, count: m_count))
        }
    }

    @objc func onRollAction() {
        if m_isRolling { return }
        m_isRolling = true
        m_rollButton.isEnabled = false
        m_sumLabel.text = ""

        SoundPlayer.shared.play("dice_roll")

        let count = m_count
        // 先決定最終點數
        let finalValues = (0..<count).map { _ in Int(arc4random_uniform(6)) + 1 }

        var elapsed: TimeInterval = 0
        let interval: TimeInterval = 0.05
        let duration: TimeInterval = 0.6
        m_rollTimer?.invalidate()
        m_rollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            elapsed += interval
            if elapsed >= duration {
                t.invalidate()
                self.m_rollTimer = nil
                self.setDiceValues(finalValues)
                self.bounceDice()
                self.finishRoll(finalValues)
            } else {
                // 快速亂跳
                let temp = (0..<count).map { _ in Int(arc4random_uniform(6)) + 1 }
                self.setDiceValues(temp)
            }
        }
    }

    // 落定時輕微縮放回彈，增加手感
    func bounceDice() {
        for die in m_dieViews {
            die.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.6, options: []) {
                die.transform = .identity
            }
        }
    }

    func finishRoll(_ values: [Int]) {
        let sum = values.reduce(0, +)
        m_sumLabel.text = "= \(sum)"

        // 記錄格式：🎲 [4][2] = 6
        let faces = values.map { "[\($0)]" }.joined()
        let resultStr = "🎲 \(faces) = \(sum)"
        let fmt = DateFormatter()
        fmt.dateFormat = "MM/dd HH:mm"
        var history = m_history
        history.insert(["time": fmt.string(from: Date()), "result": resultStr], at: 0)
        m_history = history
        m_historyTable.reloadData()

        CLog("骰子結果：\(resultStr)")
        m_isRolling = false
        m_rollButton.isEnabled = true
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "diceCell", for: indexPath)
        let item = m_history[indexPath.row]
        cell.textLabel?.text = "\(item["time"] ?? "")   \(item["result"] ?? "")"
        cell.textLabel?.textColor = CTransform.getColorWithHex("656565")
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.backgroundColor = CTransform.getColorWithHex("f0eff5")
        cell.selectionStyle = .none
        return cell
    }
}

//MARK: - 單顆骰面（CoreGraphics 畫圓點）
//------------------------------------------------------------------------------------------------------------------------------------------------
class DieView: UIView {
    var value: Int = 1 { didSet { setNeedsDisplay() } }
    var pipColor: UIColor = UIColor.darkGray

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let inset: CGFloat = 2
        let body = bounds.insetBy(dx: inset, dy: inset)
        let path = UIBezierPath(roundedRect: body, cornerRadius: body.width * 0.18)
        UIColor.white.setFill()
        path.fill()
        ctx.setStrokeColor(CTransform.getColorWithHex("656565").cgColor)
        ctx.setLineWidth(2)
        path.stroke()

        let r = body.width * 0.10
        let cols: [CGFloat] = [body.minX + body.width * 0.28, body.midX, body.maxX - body.width * 0.28]
        let rows: [CGFloat] = [body.minY + body.height * 0.28, body.midY, body.maxY - body.height * 0.28]

        // (col, row) 對照
        let layout: [Int: [(Int, Int)]] = [
            1: [(1, 1)],
            2: [(0, 0), (2, 2)],
            3: [(0, 0), (1, 1), (2, 2)],
            4: [(0, 0), (2, 0), (0, 2), (2, 2)],
            5: [(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)],
            6: [(0, 0), (0, 1), (0, 2), (2, 0), (2, 1), (2, 2)]
        ]
        pipColor.setFill()
        for (c, rr) in layout[value] ?? [] {
            let pip = UIBezierPath(ovalIn: CGRect(x: cols[c] - r, y: rows[rr] - r, width: 2 * r, height: 2 * r))
            pip.fill()
        }
    }
}
