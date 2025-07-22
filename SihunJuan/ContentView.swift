import SwiftUI

struct TapTheDotGameView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            viewModel.backgroundView()
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.handleBackgroundTap()
                }
            
            // Touch effects
            ForEach(viewModel.floatingScores) { floatingScore in
                FloatingScore(
                    score: floatingScore.score,
                    position: floatingScore.position,
                    isBonus: floatingScore.isBonus
                )
            }
            .ignoresSafeArea()
            
            ForEach(viewModel.rippleEffects) { ripple in
                RippleEffect(
                    position: ripple.position,
                    isBonus: ripple.isBonus
                )
            }
            .ignoresSafeArea()
            
            ForEach(viewModel.particleEffects) { particle in
                ParticleEffect(
                    position: particle.position,
                    combo: particle.combo
                )
            }
            .ignoresSafeArea()
            
            // Game dot - using same coordinate system as animations
            if viewModel.showDot && !viewModel.gameOver && !viewModel.showStartScreen && viewModel.preGameCountdown == nil {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                viewModel.isBonusDot ? Color.blue : Color.red,
                                (viewModel.isBonusDot ? Color.blue : Color.red).opacity(0.7)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 30
                        )
                    )
                    .frame(width: viewModel.isBonusDot ? 70 : 50, height: viewModel.isBonusDot ? 70 : 50)
                    .scaleEffect(1.1)
                    .shadow(
                        color: (viewModel.isBonusDot ? Color.blue : Color.red).opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 3
                    )
                    .position(viewModel.dotPosition)
                    .onTapGesture {
                        viewModel.handleDotTap()
                    }
                    .animation(.easeInOut(duration: 0.15), value: viewModel.dotPosition)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                if viewModel.showStartScreen {
                    VStack(spacing: 32) {
                        Spacer()
                        
                        // Logo area
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.red.opacity(0.5), radius: 10)
                                    .padding(.leading, 45)
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.blue.opacity(0.5), radius: 10)
                                    .padding(.leading, -45)
                            }
                            
                            Text("Dot! Dot!")
                                .font(DesignSystem.titleFont)
                                .foregroundColor(DesignSystem.textPrimary)
                        }
                        
                        // Start game button
                        StyledButton("Start Game", icon: "play.fill", color: DesignSystem.successColor) {
                            viewModel.showStartScreen = false
                            viewModel.startPreGameCountdown()
                        }
                        
                        // Leaderboard
                        if !viewModel.highScores.isEmpty {
                            StyledCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "trophy.fill")
                                            .foregroundColor(DesignSystem.accentColor)
                                        Text("High Score")
                                            .font(DesignSystem.headlineFont)
                                            .foregroundColor(DesignSystem.textPrimary)
                                        Spacer()
                                    }
                                    
                                    ForEach(viewModel.highScores.indices, id: \.self) { i in
                                        HStack {
                                            Text("\(i + 1)")
                                                .font(DesignSystem.captionFont)
                                                .foregroundColor(DesignSystem.textSecondary)
                                                .frame(width: 20)
                                            Text(viewModel.highScores[i].name)
                                                .font(DesignSystem.bodyFont)
                                                .foregroundColor(DesignSystem.textPrimary)
                                            Spacer()
                                            Text("\(viewModel.highScores[i].score)")
                                                .font(DesignSystem.bodyFont)
                                                .fontWeight(.semibold)
                                                .foregroundColor(DesignSystem.accentColor)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Global ranking button
                        StyledButton("Global Ranking", icon: "globe", color: DesignSystem.primaryColor) {
                            viewModel.gameCenterManager.presentGameCenter()
                        }
                    }
                    .padding(DesignSystem.padding)
                } else {
                    if let countdown = viewModel.preGameCountdown {
                        Spacer()
                        VStack(spacing: 16) {
                            Text("Game Starting")
                                .font(DesignSystem.headlineFont)
                                .foregroundColor(DesignSystem.textSecondary)
                            Text("\(countdown)")
                                .font(.system(size: 80, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.textPrimary)
                        }
                        Spacer()
                    } else {
                        // Game UI
                        VStack(spacing: 16) {
                            // Top score and control area
                            HStack {
                                // Left: score, combo, level
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 20) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Score")
                                                .font(DesignSystem.captionFont)
                                                .foregroundColor(DesignSystem.textSecondary)
                                            Text("\(viewModel.score)")
                                                .font(DesignSystem.headlineFont)
                                                .foregroundColor(DesignSystem.textPrimary)
                                        }
                                        .frame(minWidth: 60, alignment: .leading)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Combo")
                                                .font(DesignSystem.captionFont)
                                                .foregroundColor(DesignSystem.textSecondary)
                                            Text("\(viewModel.combo)x")
                                                .font(DesignSystem.headlineFont)
                                                .foregroundColor(viewModel.comboColor())
                                                .fontWeight(viewModel.combo >= 2 ? .bold : .regular)
                                        }
                                        .frame(minWidth: 50, alignment: .leading)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Reaction")
                                                .font(DesignSystem.captionFont)
                                                .foregroundColor(DesignSystem.textSecondary)
                                            Text(viewModel.averageReactionSpeed > 0 ? String(format: "%.2fs", viewModel.averageReactionSpeed) : "-")
                                                .font(DesignSystem.headlineFont)
                                                .foregroundColor(DesignSystem.accentColor)
                                        }
                                        .frame(minWidth: 55, alignment: .leading)
                                    }
                                }
                                
                                Spacer()
                                
                                // Right: game control buttons
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if viewModel.isPaused {
                                            viewModel.resumeGame()
                                        } else {
                                            viewModel.pauseGame()
                                        }
                                    }) {
                                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(DesignSystem.textPrimary)
                                            .frame(width: 44, height: 44)
                                            .background(DesignSystem.cardColor)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(DesignSystem.primaryColor.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                    
                                    Button(action: {
                                        viewModel.confirmRestart()
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(DesignSystem.textPrimary)
                                            .frame(width: 44, height: 44)
                                            .background(DesignSystem.cardColor)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(DesignSystem.successColor.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, DesignSystem.padding)
                            .padding(.top, 8)
                            
                            TimeProgressBar(timeRemaining: viewModel.timeRemaining, totalTime: 30.0)
                        }

                        Spacer()

                        Spacer()

                        if viewModel.timeRemaining <= 0 {
                            StyledCard {
                                VStack(spacing: 16) {
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(DesignSystem.primaryColor)
                                    
                                    Text("Game Over")
                                        .font(DesignSystem.titleFont)
                                        .foregroundColor(DesignSystem.textPrimary)
                                    
                                    Text("Final Score: \(viewModel.score)")
                                        .font(DesignSystem.headlineFont)
                                        .foregroundColor(DesignSystem.accentColor)
                                }
                            }
                            .padding(.horizontal, DesignSystem.padding)
                        }
                    }
                }
                
                if viewModel.gameOver {
                    VStack(spacing: 24) {
                        if !viewModel.highScores.isEmpty {
                            StyledCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "trophy.fill")
                                            .foregroundColor(DesignSystem.accentColor)
                                        Text("High Score")
                                            .font(DesignSystem.headlineFont)
                                            .foregroundColor(DesignSystem.textPrimary)
                                        Spacer()
                                    }
                                    
                                    ForEach(viewModel.highScores.indices, id: \.self) { i in
                                        HStack {
                                            Text("\(i + 1)")
                                                .font(DesignSystem.captionFont)
                                                .foregroundColor(DesignSystem.textSecondary)
                                                .frame(width: 20)
                                            Text(viewModel.highScores[i].name)
                                                .font(DesignSystem.bodyFont)
                                                .foregroundColor(DesignSystem.textPrimary)
                                            Spacer()
                                            Text("\(viewModel.highScores[i].score)")
                                                .font(DesignSystem.bodyFont)
                                                .fontWeight(.semibold)
                                                .foregroundColor(DesignSystem.accentColor)
                                        }
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: 16) {
                            StyledButton("Restart", icon: "arrow.clockwise", color: DesignSystem.successColor) {
                                viewModel.restartGame()
                            }
                            
                            StyledButton("Global Ranking", icon: "globe", color: DesignSystem.primaryColor) {
                                viewModel.gameCenterManager.presentGameCenter()
                            }
                        }
                    }
                    .padding(DesignSystem.padding)
                }
            }
            
            // Pause Overlay
            if viewModel.isPaused && !viewModel.gameOver && !viewModel.showStartScreen && viewModel.preGameCountdown == nil && !viewModel.showRestartConfirm {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(DesignSystem.primaryColor)
                    
                    Text("Paused")
                        .font(DesignSystem.titleFont)
                        .foregroundColor(DesignSystem.textPrimary)
                    
                    Text("Resume game or return to main screen")
                        .font(DesignSystem.bodyFont)
                        .foregroundColor(DesignSystem.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 16) {
                        StyledButton("Resume", icon: "play.fill", color: DesignSystem.primaryColor) {
                            viewModel.resumeGame()
                        }
                        
                        StyledButton("Main Menu", icon: "house.fill", color: DesignSystem.secondaryColor) {
                            viewModel.returnToMainScreen()
                        }
                    }
                }
                .padding(DesignSystem.padding)
            }
            
            // Restart Confirmation Overlay
            if viewModel.showRestartConfirm && !viewModel.gameOver && !viewModel.showStartScreen && viewModel.preGameCountdown == nil {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(DesignSystem.successColor)
                    
                    Text("Restart Game")
                        .font(DesignSystem.titleFont)
                        .foregroundColor(DesignSystem.textPrimary)
                    
                    Text("Are you sure you want to restart the game?\nYour current score will be reset.")
                        .font(DesignSystem.bodyFont)
                        .foregroundColor(DesignSystem.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        StyledButton("Cancel", icon: "xmark", color: DesignSystem.primaryColor) {
                            viewModel.cancelRestart()
                        }
                        
                        StyledButton("Restart", icon: "arrow.clockwise", color: DesignSystem.successColor) {
                            viewModel.restartGame()
                        }
                    }
                }
                .padding(DesignSystem.padding)
            }
        }
        .alert("Do you want to save your score?", isPresented: $viewModel.askToSaveScore, actions: {
            TextField("Name", text: $viewModel.playerName)
            Button("Save") {
                viewModel.saveScore()
            }
            Button("Cancel", role: .cancel) {}
        })
    }
}

#Preview {
    TapTheDotGameView()
} 
