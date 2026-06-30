import WidgetKit
import SwiftUI

// Kotlin 앱이 App Group 공유 UserDefaults 에 저장한 tasks_json 을 읽어 보여준다.
private let appGroup = "group.com.bimatrix.posty"
private let cream = Color(red: 1.0, green: 0.992, blue: 0.969)
private let mintDark = Color(red: 0.169, green: 0.702, blue: 0.667)
private let ink = Color(red: 0.227, green: 0.227, blue: 0.227)

// kotlinx.serialization(encodeDefaults=false) 출력 — 기본값 필드는 생략되므로 모두 옵셔널.
private struct TaskDTO: Decodable {
    let id: String
    let text: String
    let dueDate: Int64?
    let completedAt: Int64?
    let order: Int?
    let colorIndex: Int?
    let pinned: Bool?
}

struct PostyEntry: TimelineEntry {
    let date: Date
    let topText: String
    let due: String?
    let remaining: Int
    let empty: Bool
}

private func loadEntry() -> PostyEntry {
    let json = UserDefaults(suiteName: appGroup)?.string(forKey: "tasks_json") ?? "[]"
    let tasks = (try? JSONDecoder().decode([TaskDTO].self, from: Data(json.utf8))) ?? []
    let active = tasks
        .filter { $0.completedAt == nil }
        .sorted { a, b in
            let pa = a.pinned ?? false, pb = b.pinned ?? false
            if pa != pb { return pa }            // 고정(pinned) 우선
            return (a.order ?? 0) < (b.order ?? 0)
        }
    guard let top = active.first else {
        return PostyEntry(date: Date(), topText: "할 일이 없어요 :)", due: nil, remaining: 0, empty: true)
    }
    return PostyEntry(
        date: Date(),
        topText: top.text,
        due: dueLabel(top.dueDate),
        remaining: active.count - 1,
        empty: false
    )
}

/** 마감 D-day 라벨(Kotlin dueLabel 과 동일 규칙). dueDate 는 UTC 자정 millis. */
private func dueLabel(_ millis: Int64?) -> String? {
    guard let millis = millis else { return nil }
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(secondsFromGMT: 0)!
    let date = Date(timeIntervalSince1970: Double(millis) / 1000.0)
    let c = utc.dateComponents([.year, .month, .day], from: date)
    let local = Calendar(identifier: .gregorian)
    guard let dueLocal = local.date(from: DateComponents(year: c.year, month: c.month, day: c.day)) else { return nil }
    let today = local.startOfDay(for: Date())
    let days = local.dateComponents([.day], from: today, to: local.startOfDay(for: dueLocal)).day ?? 0
    switch days {
    case 0: return "오늘 마감"
    case 1: return "내일 마감"
    case let d where d > 1: return "D-\(d)"
    case -1: return "어제 지남"
    default: return "\(-days)일 지남"
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PostyEntry {
        PostyEntry(date: Date(), topText: "오늘의 할 일", due: nil, remaining: 2, empty: false)
    }
    func getSnapshot(in context: Context, completion: @escaping (PostyEntry) -> Void) {
        completion(loadEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PostyEntry>) -> Void) {
        let entry = loadEntry()
        // D-day 가 날짜 경과로 바뀔 수 있어 1시간마다 갱신(앱 변경 시엔 즉시 reload).
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct PostyWidgetEntryView: View {
    var entry: PostyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill").foregroundColor(mintDark).font(.caption2)
                Text("Posty").font(.caption2).foregroundColor(.secondary)
            }
            Spacer(minLength: 2)
            Text(entry.topText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ink)
                .lineLimit(3)
            if let due = entry.due {
                Text(due).font(.caption).foregroundColor(mintDark)
            }
            Spacer(minLength: 2)
            if entry.remaining > 0 {
                Text("외 \(entry.remaining)장 더").font(.caption2).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .widgetCream()
    }
}

private extension View {
    // iOS 17+ 는 containerBackground 필수, 이전은 background 로 폴백.
    @ViewBuilder
    func widgetCream() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(cream, for: .widget)
        } else {
            self.background(cream)
        }
    }
}

@main
struct PostyWidget: Widget {
    let kind = "PostyWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PostyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Posty")
        .description("우선순위 가장 높은 할 일을 한눈에")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
