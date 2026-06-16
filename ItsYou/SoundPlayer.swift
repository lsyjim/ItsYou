//
//  SoundPlayer.swift
//  ItsYou
//
//  統一的音效工具：預載並播放各 .wav。
//  音訊類別用 .ambient（跟靜音鍵走、不中斷使用者音樂）。
//  找不到音效檔時安全略過、不崩潰（方便尚未加入素材時仍可編譯執行）。
//

import Foundation
import AVFoundation

final class SoundPlayer {

    static let shared = SoundPlayer()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        // 設定音訊類別一次即可
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            CLog("音訊類別設定失敗：\(error.localizedDescription)")
        }
    }

    // 預載（可選）。name 不含副檔名，預設 wav。
    func preload(_ name: String, ext: String = "wav") {
        _ = player(for: name, ext: ext)
    }

    // 從頭播放指定音效；檔案不存在則略過
    func play(_ name: String, ext: String = "wav") {
        guard let p = player(for: name, ext: ext) else {
            CLog("找不到音效檔：\(name).\(ext)（請加入專案並勾選 Copy Bundle Resources）")
            return
        }
        p.currentTime = 0
        p.play()
    }

    private func player(for name: String, ext: String) -> AVAudioPlayer? {
        if let cached = players[name] { return cached }
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            players[name] = p
            return p
        } catch {
            CLog("音效載入失敗 \(name)：\(error.localizedDescription)")
            return nil
        }
    }
}
