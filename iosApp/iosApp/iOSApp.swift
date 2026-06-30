import SwiftUI
import WidgetKit

@main
struct iOSApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Compose 가 시스템 인셋(상태바/홈바)을 직접 처리한다.
                .ignoresSafeArea(.all)
                .preferredColorScheme(.light)
        }
        .onChange(of: scenePhase) { phase in
            // 앱을 떠날 때 위젯 타임라인 갱신(공유 저장소의 최신 할 일 반영).
            if phase != .active {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
