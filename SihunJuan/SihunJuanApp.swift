import SwiftUI
import GoogleMobileAds // GoogleMobileAds 프레임워크를 import 합니다.

// --- AppDelegate 클래스 추가 ---
// Google Mobile Ads SDK 초기화를 위해 AppDelegate를 사용합니다.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Google Mobile Ads SDK를 시작합니다. 이 과정은 앱 생명주기에서 한 번만 호출하면 됩니다.
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // AdCoordinator의 첫 광고 로드를 트리거합니다.
        _ = AdCoordinator.shared
        
        return true
    }
}

@main
struct SihunJuanApp: App {
    // @UIApplicationDelegateAdaptor를 사용하여 AppDelegate를 SwiftUI 앱 생명주기에 연결합니다.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var gameCenterManager = GameCenterManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameViewModel)
                .environmentObject(gameCenterManager)
                .onAppear {
                    gameCenterManager.authenticateUser()
                }
        }
    }
}
