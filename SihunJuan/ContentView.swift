import SwiftUI

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
    
    @State private var timer: Timer?
    @State private var dotTimer: Timer?
    @State private var isBonusDot = false
    
    @AppStorage("highScores") private var highScoresData: String = ""
    @State private var highScores: [ScoreEntry] = []
    
    @State private var playerName: String = ""
    @State private var showNamePrompt = true
    @State private var showStartScreen = true
    @State private var askToSaveScore = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.yellow.opacity(1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                if showStartScreen {
                    VStack {
                        Text("Tap The Dot!")
                            .font(.largeTitle)
                            .padding()
                        Button("Start Game") {
                            showStartScreen = false
                            startGame()
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        Text("🏆 Top Scores")
                            .font(.headline)
                            .padding(.top)
                        ForEach(highScores.indices, id: \.self) { i in
                            Text("\(i + 1). \(highScores[i].name): \(highScores[i].score)점")
                        }
                    }
                } else {
                    HStack {
                        Text("Score: \(score)")
                            .font(.title2)
                        Spacer()
                        Text("Combo: \(combo)x")
                            .foregroundColor(combo >= 2 ? .orange : .gray)
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
                                .font(.largeTitle)
                            Text("💯 Final Score: \(score)")
                                .font(.title2)
                                .padding(.top)
                        }
                        .transition(.opacity)
                    }
                }
                
                if gameOver {
                    VStack(spacing: 12) {
                        Button("🔄 Restart") {
                            startGame()
                        }
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.scale)
                        
                        Text("🏆 Top Scores")
                            .font(.headline)
                        ForEach(highScores.indices, id: \.self) { i in
                            Text("\(i + 1). \(highScores[i].name): \(highScores[i].score)점")
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
            }
        }
    }

    func moveDot() {
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        let padding: CGFloat = 80

        let safeTop: CGFloat = 100
        let safeBottom: CGFloat = 150

        let newX = CGFloat.random(in: padding...(screenWidth - padding))
        let newY = CGFloat.random(in: safeTop...(screenHeight - safeBottom))
        withAnimation(.linear(duration: 0.2)) {
            dotPosition = CGPoint(x: newX, y: newY)
        }
        isBonusDot = Int.random(in: 1...100) <= 15 // 15% 확률로 등장
    }
    
    func dotInterval() -> TimeInterval {
        let baseInterval: Double = 1.5
        let level = score / 100
        let speedMultiplier = pow(0.9, Double(level)) // 10% 빨라짐
        return max(0.3, baseInterval * speedMultiplier)
    }
}

#Preview {
    TapTheDotGameView()
}
