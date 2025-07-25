import SwiftUI
import GoogleMobileAds // GoogleMobileAds 프레임워크를 import 합니다.

/// Google Mobile Ads SDK 초기화를 담당하는 AppDelegate 클래스입니다.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 1. Google Mobile Ads SDK를 시작합니다.
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // 2. 광고 관리자(AdCoordinator)를 초기화하여 첫 광고를 미리 로드합니다.
        AdCoordinator.shared.loadAd()
        
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
