# Posty — iOS (Compose Multiplatform)

Posty가 **Compose Multiplatform**로 전환되어 Android와 iOS가 **하나의 UI/로직 코드**를 공유합니다.

## 모듈 구조

```
Posty/
├─ shared/        KMP + Compose Multiplatform 라이브러리 (UI·뷰모델·도메인 전부)
│   ├─ commonMain  BoardScreen·DeckLineBoard·StickyNoteCard·CompletedScreen·EditTaskScreen,
│   │              PostyViewModel·TaskRepository·Task, 테마, 날짜 포맷, PostyApp/PostyRoot
│   ├─ androidMain AndroidPostyStore(DataStore), randomUuid/currentTimeMillis(actual),
│   │              setPostyContent(Activity 진입), PlatformBackHandler(actual)
│   └─ iosMain     IosPostyStore(App Group), MainViewController(), IosReminders(알림), actual들
├─ app/           Android 앱(com.android.application): MainActivity·알림·위젯·리소스 → :shared 의존
├─ iosApp/        iOS 앱(SwiftUI 호스트) — shared 프레임워크의 MainViewController() 표시
│   ├─ project.yml      XcodeGen 정의(.xcodeproj 를 손으로 관리하지 않음)
│   ├─ iosApp/          iOSApp.swift, ContentView.swift, Assets(아이콘·런치색), 엔타이틀먼트
│   └─ PostyWidget/     WidgetKit 위젯(Swift) + 엔타이틀먼트
└─ .github/workflows/ios.yml   macOS 러너에서 iOS 빌드 검증
```

핵심 버전: Kotlin 2.3.20 · Compose Multiplatform 1.11.1 · AGP 9.2.1 · Gradle 9.4.1.
(CMP 1.11.1 의 iOS klib 이 Kotlin 2.3.20 으로 빌드돼 있어 컴파일러도 2.3.20 으로 맞춤)

## Android 빌드 (Windows/any)

```
./gradlew :app:assembleDebug      # 기존과 동일하게 동작 (검증 완료)
```

## iOS 빌드 (반드시 macOS + Xcode 필요)

Windows에서는 iOS 네이티브 컴파일이 불가합니다. macOS에서:

```
brew install xcodegen
cd iosApp && xcodegen generate      # iosApp.xcodeproj 생성
open iosApp.xcodeproj                # Xcode 에서 실행(시뮬레이터/기기)
```

Xcode 빌드 시 `project.yml`의 pre-build 스크립트가 자동으로
`./gradlew :shared:embedAndSignAppleFrameworkForXcode` 를 호출해 Kotlin(Compose) 프레임워크를 컴파일·임베드합니다.

순수 프레임워크 컴파일만 확인하려면:
```
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
```

## CI

`.github/workflows/ios.yml` — **저장소 루트 기준**으로 동작합니다.
- 이 저장소의 루트가 곧 Posty 프로젝트(루트에 `gradlew`)라면 그대로 동작합니다.
- Posty가 하위 폴더라면 워크플로 파일을 실제 repo 루트의 `.github/workflows/` 로 옮기고
  `working-directory` 를 (예) `Posty`, `Posty/iosApp` 로 맞추세요.

러너는 `macos-15`(Xcode 16). CI는 ① 최신 Xcode 고정 → ② iOS 프레임워크 링크 →
③ XcodeGen 으로 프로젝트 생성 → ④ 시뮬레이터(arm64)용 앱+위젯 빌드를 수행합니다.
(`~/.konan` 캐시로 반복 빌드를 가속)

## 구현된 iOS 기능

- ✅ 보드/덱·라인/자유 배치, 카드 편집, 완료 캘린더 — Android 와 동일 UI(공유)
- ✅ 로컬 저장(NSUserDefaults, App Group suite)
- ✅ **마감 알림**(`UNUserNotificationCenter`) — 마감일 당일 로컬 오전 9시
- ✅ **앱 아이콘 + 런치 배경(크림)**
- ✅ **홈 위젯**(WidgetKit) — 우선순위 최상위 할 일 + 마감 D-day + "외 N장 더"

## CI(macOS) 검증 완료

- ✅ Kotlin/Compose iOS 프레임워크 네이티브 링크
- ✅ Swift 앱 + 위젯 익스텐션 시뮬레이터 빌드(서명 없이 `CODE_SIGNING_ALLOWED=NO`)

## App Group (앱 ↔ 위젯 데이터 공유)

위젯이 앱의 할 일을 읽으려면 **App Group** 이 필요합니다.
그룹 ID: `group.com.bimatrix.posty` (앱·위젯 엔타이틀먼트에 이미 포함).

- 시뮬레이터/로컬 실행: Xcode 가 자동 서명으로 그룹 컨테이너를 만들어 줍니다.
- 실기기: Apple 개발자 계정에서 App Group 을 등록하고, Xcode 에서 `iosApp` 과 `PostyWidget`
  두 타깃 모두 **Signing & Capabilities → App Groups** 에 `group.com.bimatrix.posty` 를 켜세요.
- 엔타이틀먼트가 없으면 앱은 표준 저장소로 폴백해 **단독 동작**(위젯만 데이터를 못 읽음)합니다.

## 실기기 빌드/배포 (코드 서명)

CI 는 서명 없이 '빌드 검증'만 합니다. 실기기 설치는 Mac/Xcode 에서:

1. `cd iosApp && xcodegen generate && open iosApp.xcodeproj`
2. `iosApp`·`PostyWidget` 타깃의 **Signing & Capabilities** 에서 본인 **Team** 선택
   (자동 서명 권장) — 번들 ID 가 이미 쓰였다면 고유하게 변경.
3. 두 타깃에 **App Groups** 켜고 동일 그룹 ID 지정.
4. 기기 연결 후 Run.

## 남은 선택 작업

- 실기기 배포 자동화(서명 인증서/프로파일 → fastlane match, TestFlight 업로드)
- 위젯 systemLarge 패밀리/여러 카드 표시
- iOS 화면 내 뒤로가기(현재 시스템 스와이프에 의존)
