import SwiftUI
import Foundation

// MARK: - Effect Data Models
struct FloatingScoreData: Identifiable {
    let id = UUID()
    let score: Int
    let position: CGPoint
    let isBonus: Bool
}

struct RippleData: Identifiable {
    let id = UUID()
    let position: CGPoint
    let isBonus: Bool
}

struct ParticleEffectData: Identifiable {
    let id = UUID()
    let position: CGPoint
    let combo: Int
}

// MARK: - Game View Model
class GameViewModel: ObservableObject {
    // MARK: - Game State
    @Published var dotPosition = CGPoint(x: 150, y: 300)
    @Published var score = 0
    @Published var combo = 0
    @Published var timeRemaining: Double = 30.0
    @Published var showDot = true
    @Published var gameOver = false
    @Published var level = 1
    @Published var isBonusDot = false
    @Published var isPaused = false
    
    // MARK: - Reaction Speed Tracking
    @Published var averageReactionSpeed: Double = 0.0 // Average reaction speed (in seconds)
    
    // MARK: - UI State
    @Published var showStartScreen = true
    @Published var preGameCountdown: Int? = nil
    @Published var askToSaveScore = false
    @Published var playerName = ""
    @Published var showRestartConfirm = false
    
    // MARK: - Effects
    @Published var floatingScores: [FloatingScoreData] = []
    @Published var rippleEffects: [RippleData] = []
    @Published var particleEffects: [ParticleEffectData] = []
    
    // MARK: - Score Management
    @Published var highScores: [ScoreEntry] = []
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var dotTimer: Timer?
    private var lastTapTime: Date = Date()
    private let totalGameTime: Double = 30.0
    
    // MARK: - Reaction Speed Private Properties
    private var dotMoveTime: Date = Date() // Time when dot was last moved
    private var reactionTimes: [Double] = [] // Store individual reaction times
    
    // MARK: - Managers
    let gameCenterManager = GameCenterManager()
    
    // MARK: - Initialization
    init() {
        loadHighScores()
        setupGameCenter()
    }
    
    // MARK: - Game Center Setup
    private func setupGameCenter() {
        gameCenterManager.authenticateGameCenter()
        gameCenterManager.checkLoginStatus()
    }
    
    // MARK: - High Scores Management
    private func loadHighScores() {
        if let data = UserDefaults.standard.string(forKey: "highScores")?.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            highScores = decoded
        }
    }
    
    func saveScore() {
        let newEntry = ScoreEntry(name: playerName.isEmpty ? "Player" : playerName, score: score)
        highScores.append(newEntry)
        highScores.sort { $0.score > $1.score }
        highScores = Array(highScores.prefix(5))
        
        if let encoded = try? JSONEncoder().encode(highScores),
           let jsonString = String(data: encoded, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: "highScores")
        }
    }
    
    // MARK: - Game Control
    func startPreGameCountdown() {
        preGameCountdown = 3
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if let current = self.preGameCountdown {
                if current > 1 {
                    self.preGameCountdown = current - 1
                } else {
                    timer.invalidate()
                    self.preGameCountdown = nil
                    self.startGame()
                }
            } else {
                timer.invalidate()
            }
        }
    }
    
    func startGame() {
        resetGameState()
        startGameTimers()
    }
    
    private func resetGameState() {
        score = 0
        combo = 0
        timeRemaining = totalGameTime
        showDot = true
        gameOver = false
        level = 1
        isPaused = false
        showStartScreen = false
        averageReactionSpeed = 0.0
        reactionTimes.removeAll()
        clearEffects()
        moveDot()
    }
    
    private func startGameTimers() {
        // Main game timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if self.timeRemaining > 0 && !self.isPaused {
                self.timeRemaining -= 0.1
            } else if self.timeRemaining <= 0 {
                self.endGame()
            }
        }
        
        // Dot movement timer
        startDotTimer()
    }
    
    private func startDotTimer() {
        dotTimer?.invalidate()
        dotTimer = Timer.scheduledTimer(withTimeInterval: dotInterval(), repeats: true) { _ in
            if self.timeRemaining > 0 && !self.isPaused {
                self.moveDot()
                self.checkComboTimeout()
                self.updateLevel()
            }
        }
    }
    
    private func resetDotTimer() {
        startDotTimer()
    }
    
    private func endGame() {
        showDot = false
        timer?.invalidate()
        dotTimer?.invalidate()
        gameOver = true
        askToSaveScore = true
        gameCenterManager.reportScore(score: score, leaderboardID: "ranking")
    }
    
    func pauseGame() {
        isPaused = true
    }
    
    func resumeGame() {
        isPaused = false
    }
    
    func confirmRestart() {
        showRestartConfirm = true
        pauseGame()
    }
    
    func restartGame() {
        showRestartConfirm = false
        timer?.invalidate()
        dotTimer?.invalidate()
        resetGameState()
        startPreGameCountdown()
    }
    
    func cancelRestart() {
        showRestartConfirm = false
        resumeGame()
    }
    
    func returnToMainScreen() {
        timer?.invalidate()
        dotTimer?.invalidate()
        showStartScreen = true
        gameOver = false
        isPaused = false
        showRestartConfirm = false
        clearEffects()
    }
    
    // MARK: - Game Logic
    func handleDotTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Store current dot position (for animation)
        let currentDotPosition = dotPosition
        
        // Calculate and record reaction speed
        calculateReactionSpeed()
        
        updateCombo()
        updateScore()
        addEffects(at: currentDotPosition) // Execute effects at current position
        checkBonusRewards()
        moveDot()
        
        // Reset timer after touch to prevent duplicate movements
        resetDotTimer()
    }
    
    func handleBackgroundTap() {
        combo = 0
    }
    
    private func updateCombo() {
        let now = Date()
        if now.timeIntervalSince(lastTapTime) <= 1.5 {
            combo += 1
        } else {
            combo = 1
        }
        lastTapTime = now
    }
    
    private func updateScore() {
        let scoreToAdd = isBonusDot ? (combo + 5) : combo
        score += scoreToAdd
    }
    
    private func addEffects(at position: CGPoint) {
        let scoreToAdd = isBonusDot ? (combo + 5) : combo
        addFloatingScore(scoreToAdd, at: position, isBonus: isBonusDot)
        addRippleEffect(at: position, isBonus: isBonusDot)
        
        if combo >= 3 {
            addParticleEffect(at: position, combo: combo)
        }
    }
    
    private func checkBonusRewards() {
        if score == 50 || score == 100 {
            timeRemaining += 5
        }
    }
    
    private func checkComboTimeout() {
        if Date().timeIntervalSince(lastTapTime) > 2 {
            combo = 0
        }
    }
    
    // MARK: - Dot Management
    func moveDot() {
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        // Calculate padding considering dot size
        let dotRadius: CGFloat = isBonusDot ? 35 : 25 // Dot radius
        let minPadding: CGFloat = 50 // Minimum margin
        let totalPadding = dotRadius + minPadding
        
        let safeTop: CGFloat = 120 + totalPadding
        let safeBottom: CGFloat = 40 + totalPadding
        
        // Calculate safe range considering screen boundaries
        let minX = totalPadding
        let maxX = screenWidth - totalPadding
        let minY = safeTop
        let maxY = screenHeight - safeBottom
        
        // Valid range check
        guard minX < maxX && minY < maxY else {
            // Use default center position if range is invalid
            dotPosition = CGPoint(x: screenWidth / 2, y: screenHeight / 2)
            dotMoveTime = Date() // Record dot movement time
            return
        }
        
        let newX = CGFloat.random(in: minX...maxX)
        let newY = CGFloat.random(in: minY...maxY)
        
        withAnimation(.easeInOut(duration: 0.15)) {
            dotPosition = CGPoint(x: newX, y: newY)
        }
        
        // Record the time when dot moved
        dotMoveTime = Date()
        
        isBonusDot = Int.random(in: 1...100) <= 15 // 15% probability
    }
    
    private func updateLevel() {
        // Progressive level increase using square root
        // Level 1: 0-24 points, Level 2: 25-99 points, Level 3: 100-224 points, Level 4: 225-399 points, etc.
        level = max(1, Int(sqrt(Double(score) / 25)) + 1)
    }
    
    private func dotInterval() -> TimeInterval {
        let baseInterval: Double = 1.5
        let speedMultiplier = pow(0.9, Double(level))
        return max(0.3, baseInterval * speedMultiplier)
    }
    
    // MARK: - Effects Management
    private func addFloatingScore(_ scoreValue: Int, at position: CGPoint, isBonus: Bool) {
        let floatingScore = FloatingScoreData(
            score: scoreValue,
            position: position,
            isBonus: isBonus
        )
        floatingScores.append(floatingScore)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.floatingScores.removeAll { $0.id == floatingScore.id }
        }
    }
    
    private func addRippleEffect(at position: CGPoint, isBonus: Bool) {
        let ripple = RippleData(
            position: position,
            isBonus: isBonus
        )
        rippleEffects.append(ripple)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.rippleEffects.removeAll { $0.id == ripple.id }
        }
    }
    
    private func addParticleEffect(at position: CGPoint, combo: Int) {
        let particle = ParticleEffectData(
            position: position,
            combo: combo
        )
        particleEffects.append(particle)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.particleEffects.removeAll { $0.id == particle.id }
        }
    }
    
    private func clearEffects() {
        floatingScores.removeAll()
        rippleEffects.removeAll()
        particleEffects.removeAll()
    }
    
    // MARK: - Reaction Speed Calculation
    private func calculateReactionSpeed() {
        let reactionTime = Date().timeIntervalSince(dotMoveTime)
        
        // Exclude reaction times that are too fast or slow (0.1s ~ 5s)
        if reactionTime >= 0.1 && reactionTime <= 5.0 {
            reactionTimes.append(reactionTime)
            
            // Keep only the latest 10 reaction times for average calculation
            if reactionTimes.count > 10 {
                reactionTimes.removeFirst()
            }
            
            // Calculate average reaction speed
            averageReactionSpeed = reactionTimes.reduce(0, +) / Double(reactionTimes.count)
        }
    }
    
    // MARK: - Computed Properties
    func comboColor() -> Color {
        switch combo {
        case 5...9:
            return DesignSystem.accentColor
        case 10...19:
            return Color.pink
        case 20...29:
            return Color.purple
        case 30...:
            return DesignSystem.secondaryColor
        case 2...4:
            return DesignSystem.successColor.opacity(0.8)
        default:
            return DesignSystem.textSecondary
        }
    }
    
    func backgroundView() -> some View {
        switch level {
        case 0:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.backgroundColor,
                    DesignSystem.spaceDeep
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        case 1:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.backgroundColor,
                    DesignSystem.spaceDeep,
                    DesignSystem.primaryColor.opacity(0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        case 2:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.backgroundColor,
                    DesignSystem.spaceDeep,
                    DesignSystem.secondaryColor.opacity(0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        case 3:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.backgroundColor,
                    DesignSystem.spaceDeep,
                    Color.purple.opacity(0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        case 4:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.backgroundColor,
                    DesignSystem.spaceDeep,
                    DesignSystem.accentColor.opacity(0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        case 5:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.backgroundColor,
                    DesignSystem.spaceDeep,
                    DesignSystem.successColor.opacity(0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.backgroundColor,
                    DesignSystem.spaceDeep,
                    Color.indigo.opacity(0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
} 
