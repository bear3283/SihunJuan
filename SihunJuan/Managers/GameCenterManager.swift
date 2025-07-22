import Foundation
import GameKit
import UIKit

final class GameCenterManager: NSObject, GKGameCenterControllerDelegate, ObservableObject {
    func checkLoginStatus() {
        print("🔍 Game Center isAuthenticated:", GKLocalPlayer.local.isAuthenticated)
        print("🔍 player alias:", GKLocalPlayer.local.alias)
        print("🔍 player ID:", GKLocalPlayer.local.gamePlayerID)
    }
    
    func authenticateGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let viewController = viewController {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(viewController, animated: true)
                }
            } else if GKLocalPlayer.local.isAuthenticated {
                print("✅ Game Center authentication successful")
            } else {
                print("❌ Game Center authentication failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func presentGameCenter() {
        let vc = GKGameCenterViewController(state: .leaderboards)
        vc.gameCenterDelegate = self
        presentGameCenterViewController(vc)
    }
    
    private func presentGameCenterViewController(_ viewController: UIViewController) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(viewController, animated: true)
        } else {
            print("🚨 Unable to find RootViewController.")
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func reportScore(score: Int, leaderboardID: String) {
        let player = GKLocalPlayer.local
        let leaderboardIDs = [leaderboardID]
        
        GKLeaderboard.submitScore(score, context: 0, player: player, leaderboardIDs: leaderboardIDs) { error in
            if let error = error {
                print("❌ Score upload failed: \(error.localizedDescription)")
            } else {
                print("✅ Score upload successful")
            }
        }
    }
} 