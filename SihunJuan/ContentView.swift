import SwiftUI
import GameKit

final class GameCenterManager: NSObject, GKGameCenterControllerDelegate, ObservableObject {
  
  func presentGameCenter() {
    let vc = GKGameCenterViewController(state: .default)
    vc.gameCenterDelegate = self
    self.presentGameCenterViewController(vc)
  }
  
  // TODO: - pause 기능을 구현해야함. -- 추가됨
  /// SwiftUI에서 Game Center ViewController를 present하는 메서드
  private func presentGameCenterViewController(_ viewController: UIViewController) {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
      if let rootViewController = windowScene.windows.first?.rootViewController {
        rootViewController.present(viewController, animated: true)
      } else {
        print("🚨 RootViewController를 찾을 수 없습니다.")
      }
    }
  }
  
  // GKGameCenterControllerDelegate 프로토콜 준수하려면 구현 필요
  func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    gameCenterViewController.dismiss(animated: true, completion: nil)
  }
}

struct ScoreEntry: Codable, Identifiable {
    let id = UUID()
    let name: String
    let score: Int
}

struct TapTheDotGameView: View {
    @State private var dotPosition = CGPoint(x: 150, y: 300)
    @State private var score = 0
    @State private var combo = 0
    @State private var timeRemaining = 30
    @State private var showDot = true
    @State private var lastTapTime: Date = Date()
    @State private var gameOver = false
    @State private var level = 0
    
    @State private var timer: Timer?
    @State private var dotTimer: Timer?
    @State private var isBonusDot = false
    
    @AppStorage("highScores") private var highScoresData: String = ""
    @State private var highScores: [ScoreEntry] = []
    
    @State private var playerName: String = ""
    @State private var showNamePrompt = true
    @State private var showStartScreen = true
    @State private var askToSaveScore = false
    @StateObject private var gameCenterManager = GameCenterManager()
    
    var body: some View {
        ZStack {
            backgroundView()
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    combo = 0 // ❗️dot 외 터치 시 콤보 끊김
                }
            VStack {
                if showStartScreen {
                    VStack {
                        Spacer()
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 120, height: 120)
                                .offset(x: 100)
                            
                            Circle()
                                .fill(Color.red)
                                .frame(width: 120, height: 120)
                                .offset(x: -100)
                        }
                        
                        Text("Dot! Dot!")
                            .font(.system(size: 50))
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .padding()
                        Button("Start Game") {
                            showStartScreen = false
                            startGame()
                        }
                        .font(.largeTitle)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        Text("🏆 Top Scores")
                            .font(.title)
                            .padding(.top)
                        ForEach(highScores.indices, id: \.self) { i in
                            Text("\(i + 1). \(highScores[i].name): \(highScores[i].score)점")
                        }
                        Spacer()
                        Button {
                            gameCenterManager.presentGameCenter()
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text("World Scores")
                            }
                            .font(.title3)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.2))
                            .foregroundStyle(Color.black)
                            .cornerRadius(8)
                        }
                    }
                } else {
                    HStack {
                        Text("Score: \(score)")
                            .font(.title2)
                        Spacer()
                        Text("COMBO: \(combo)x")
                            .foregroundColor(comboColor())
                            .fontWeight(combo >= 2 ? .bold : .regular)
                        Spacer()
                        Text("Time: \(timeRemaining)")
                            .font(.title2)
                    }
                    .padding()
                    
                    Spacer()
                    
                    if showDot {
                        Circle()
                            .fill(isBonusDot ? Color.blue : Color.red)
                            .frame(width: isBonusDot ? 80 : 60, height: isBonusDot ? 80 : 60)
                            .scaleEffect(1.2)
                            .shadow(color: isBonusDot ? .blue.opacity(0.5) : .red.opacity(0.5), radius: 10)
                            .position(dotPosition)
                            .onTapGesture {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                let now = Date()
                                if now.timeIntervalSince(lastTapTime) <= 1.5 {
                                    combo += 1
                                } else {
                                    combo = 1
                                }
                                lastTapTime = now
                                
                                if isBonusDot {
                                    score += 5
                                } else {
                                    score += combo
                                }
                                
                                if score == 50 || score == 100 {
                                    timeRemaining += 5
                                }
                                
                                moveDot()
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dotPosition)
                    }
                    
                    Spacer()
                    
                    if timeRemaining <= 0 {
                        VStack {
                            Text("🎮 Game Over")
                                .font(.system(size: 50, weight: .bold, design: .default))
                            Text("🎉 Final Score: \(score)")
                                .font(.system(size: 30, weight: .bold, design: .default))
                                .padding(.top)
                        }
                        .transition(.opacity)
                        
                        Spacer().frame(height: 50)
                    }
                }
                
                if gameOver {
                    VStack(spacing: 16) {
                        Text("🏆 Top Scores")
                            .font(.title2)
                        ForEach(highScores.indices, id: \.self) { i in
                            Text("\(i + 1). \(highScores[i].name): \(highScores[i].score)점")
                        }
                        
                        Button("Restart") {
                            startGame()
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .transition(.scale)
                        .padding(.top)
                        
                        Button {
                            gameCenterManager.presentGameCenter()
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text("World Scores")
                            }
                            .font(.title3)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.2))
                            .foregroundStyle(Color.black)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .alert("Save your score?", isPresented: $askToSaveScore, actions: {
            TextField("Name", text: $playerName)
            Button("Save") {
                let newEntry = ScoreEntry(name: playerName.isEmpty ? "Player" : playerName, score: score)
                highScores.append(newEntry)
                highScores.sort { $0.score > $1.score }
                highScores = Array(highScores.prefix(5))
                if let encoded = try? JSONEncoder().encode(highScores) {
                    highScoresData = String(data: encoded, encoding: .utf8) ?? ""
                }
            }
            Button("Cancel", role: .cancel) {}
        })
        .onAppear {
            if let data = highScoresData.data(using: .utf8),
               let decoded = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
                highScores = decoded
            }
        }
    }
    
    func startGame() {
        score = 0
        combo = 0
        timeRemaining = 30
        showDot = true
        gameOver = false
        level = 0
        moveDot()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                showDot = false
                timer?.invalidate()
                dotTimer?.invalidate()
                gameOver = true
                askToSaveScore = true
            }
        }
        
        dotTimer?.invalidate()
        dotTimer = Timer.scheduledTimer(withTimeInterval: dotInterval(), repeats: true) { _ in
            if timeRemaining > 0 {
                moveDot()
                // 1.5초마다 dot 바뀔 때 콤보 타이머 체크
                if Date().timeIntervalSince(lastTapTime) > 1.5 {
                    combo = 0
                }
                updateLevel()
            }
        }
    }
    
    func moveDot() {
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        let padding: CGFloat = 100
        
        let safeTop: CGFloat = 120
        let safeBottom: CGFloat = 170
        
        let newX = CGFloat.random(in: padding...(screenWidth - padding))
        let newY = CGFloat.random(in: safeTop...(screenHeight - safeBottom))
        withAnimation(.linear(duration: 0.2)) {
            dotPosition = CGPoint(x: newX, y: newY)
        }
        isBonusDot = Int.random(in: 1...100) <= 15 // 15% 확률로 등장
    }
    
    func updateLevel() {
        level = score / 100
    }
    
    func dotInterval() -> TimeInterval {
        let baseInterval: Double = 1.5
        let speedMultiplier = pow(0.9, Double(level)) // 10% 빨라짐
        return max(0.3, baseInterval * speedMultiplier)
    }
    
    func comboColor() -> Color {
        switch combo {
        case 5...9:
            return .orange
        case 10...19:
            return .pink
        case 20...29:
            return .purple
        case 30...:
            return .red
        case 2...5:
            return .orange.opacity(0.7)
        default:
            return .gray
        }
    }
    
    func backgroundView() -> some View {
        switch level {
        case 0:
            return LinearGradient(gradient: Gradient(colors: [Color.white, Color.yellow.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
        case 1:
            return LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
        case 2:
            return LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
        case 3:
            return LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.4), Color.purple.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
        case 4:
            return LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
        case 5:
            return LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.green.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.5), Color.indigo.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
        }
    }
}


#Preview {
    TapTheDotGameView()
}
