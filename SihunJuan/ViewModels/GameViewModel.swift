import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    // Game state
    @Published var score: Int = 0
    @Published var timeRemaining: Double = 10.0
    @Published var isGameOver: Bool = false
    @Published var dots: [Dot] = []
    @Published var particleSystem = ParticleSystem()
    @Published var combo: Int = 0
    @Published var maxCombo: Int = 0
    @Published var showComboEffect: Bool = false
    
    // Game settings
    let gameDuration: Double = 10.0
    private var timer: Timer?
    
    // --- 광고 관련 로직 추가 ---
    // UserDefaults를 사용하여 앱을 종료해도 플레이 횟수가 유지되도록 합니다.
    @Published var gamePlayCount: Int = UserDefaults.standard.integer(forKey: "gamePlayCount")

    init() {
        resetGame()
    }
    
    func startGame() {
        resetGame()
        isGameOver = false
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
        addDot()
    }

    func resetGame() {
        score = 0
        timeRemaining = gameDuration
        isGameOver = true
        dots.removeAll()
        maxCombo = 0
        combo = 0
        timer?.invalidate()
    }

    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 0.01
        } else {
            endGame()
        }
    }

    func dotTapped(dot: Dot) {
        if let index = dots.firstIndex(where: { $0.id == dot.id }) {
            score += 1
            combo += 1
            if combo > maxCombo {
                maxCombo = combo
            }
            if combo > 1 {
                showComboEffect = true
            }
            particleSystem.add(position: dot.position)
            dots.remove(at: index)
            addDot()
        }
    }

    private func addDot() {
        let newDot = Dot()
        dots.append(newDot)
    }
    
    func resetCombo() {
        combo = 0
    }

    private func endGame() {
        isGameOver = true
        timer?.invalidate()
        
        // --- 광고 호출 로직 ---
        // 게임이 끝났을 때, 플레이 횟수를 1 증가시킵니다.
        gamePlayCount += 1
        UserDefaults.standard.set(gamePlayCount, forKey: "gamePlayCount")
        print("🎮 게임 플레이 횟수: \(gamePlayCount)")

        // 플레이 횟수가 5의 배수일 때 광고를 표시합니다.
        if gamePlayCount % 5 == 0 {
            print("✨ 5회 플레이 완료! 광고를 표시합니다.")
            AdCoordinator.shared.presentAd()
        }
    }
}

struct Dot: Identifiable {
    let id = UUID()
    var position: CGPoint
    
    init() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Ensure dots appear within a reasonable area
        let inset: CGFloat = 50
        self.position = CGPoint(
            x: CGFloat.random(in: inset...(screenWidth - inset)),
            y: CGFloat.random(in: inset...(screenHeight - inset * 2))
        )
    }
}
