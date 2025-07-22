import Foundation
import GoogleMobileAds
import UIKit

// --- 광고 로직 관리자 (싱글턴 패턴) ---
// 앱의 어느 곳에서나 쉽게 접근하여 광고를 요청할 수 있도록 싱글턴으로 설계합니다.
class AdCoordinator: NSObject, GADFullScreenContentDelegate {
    // static let shared를 통해 AdCoordinator의 유일한 인스턴스를 생성합니다.
    static let shared = AdCoordinator()

    private var interstitial: GADInterstitialAd?
    // Google에서 제공하는 테스트용 광고 단위 ID입니다.
    // 앱 출시 전, AdMob에서 발급받은 실제 ID로 교체해야 합니다.
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910"

    // 외부에서 인스턴스를 직접 생성하는 것을 방지하기 위해 private init을 사용합니다.
    private override init() {
        super.init()
        // 앱이 시작될 때 첫 광고를 미리 로드하여 필요할 때 바로 보여줄 수 있도록 준비합니다.
        loadAd()
    }

    /// 전면 광고를 로드하는 함수
    func loadAd() {
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: adUnitID,
                               request: request) { [weak self] ad, error in
            if let error = error {
                print("😭 전면 광고 로드 실패: \(error.localizedDescription)")
                return
            }
            print("✅ 전면 광고 로드 성공")
            self?.interstitial = ad
            // GADFullScreenContentDelegate를 self로 설정하여 광고 이벤트 콜백을 수신합니다.
            self?.interstitial?.fullScreenContentDelegate = self
        }
    }

    /// 로드된 전면 광고를 표시하는 함수
    func presentAd() {
        guard let fullScreenAd = interstitial else {
            return print("⚠️ 광고가 준비되지 않았습니다. 다음 기회에...")
        }
        
        // rootViewController는 광고를 표시할 화면을 지정합니다.
        // 현재 활성화된 화면의 최상위 뷰 컨트롤러를 찾아 광고를 띄웁니다.
        guard let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })?
                .windows
                .first(where: { $0.isKeyWindow })?
                .rootViewController else {
            return
        }
        
        fullScreenAd.present(fromRootViewController: root)
    }

    // --- GADFullScreenContentDelegate 콜백 함수들 ---

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("📺 광고가 표시됩니다.")
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("😭 광고 표시 실패: \(error.localizedDescription)")
        // 실패했으므로 다음 광고를 미리 로드합니다.
        loadAd()
    }

    /// 사용자가 광고를 닫았을 때 호출됩니다.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("👋 광고가 닫혔습니다.")
        // GADInterstitialAd는 일회용 객체이므로, 다음 광고를 위해 새로 로드합니다.
        loadAd()
    }
}
