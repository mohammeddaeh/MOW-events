import Flutter
import Foundation

#if canImport(AlarmKit)
import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
#endif

/// جسر منبّهات iOS عبر AlarmKit (iOS 26+): منبّه نظام حقيقي يظهر على شاشة القفل
/// ويرنّ حتى مع الوضع الصامت/التركيز. على الإصدارات الأقدم تُرجع القناة `false`
/// ويتولّى Dart الرجوع للإشعار المحلي المجدول.
///
/// القناة: `ios_alarmkit`
/// - `schedule` {requestCode, time(ms), title, location, eventStartTime(ms)} -> Bool
/// - `cancel` {requestCode} -> void
enum EventAlarmKitChannel {
  private static var channel: FlutterMethodChannel?

  /// يُرسل لـ Dart حمولة إشعار منبّه وصل والتطبيق في الواجهة كي تُفتح شاشة المنبّه.
  static func notifyAlarmPresented(payload: String) {
    channel?.invokeMethod("alarmPresented", arguments: payload)
  }

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "ios_alarmkit", binaryMessenger: messenger)
    self.channel = channel
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "schedule":
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
          Task {
            do {
              let ok = try await EventAlarmKit.scheduleFromArgs(args)
              result(ok)
            } catch {
              NSLog("[AlarmKit] schedule failed: \(error)")
              result(false)
            }
          }
          return
        }
        #endif
        result(false)
      case "cancel":
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *), let rc = (args["requestCode"] as? NSNumber)?.intValue {
          EventAlarmKit.cancel(requestCode: rc)
        }
        #endif
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

#if canImport(AlarmKit)

@available(iOS 26.0, *)
struct EventAlarmMetadata: AlarmMetadata {}

@available(iOS 26.0, *)
enum EventAlarmKit {
  /// مدة التأجيل ونفس شرط [AlarmSnoozePolicy] في Dart: التأجيل مسموح فقط إذا بقي
  /// على بداية الحدث 5 دقائق على الأقل.
  static let snoozeSeconds: TimeInterval = 5 * 60

  /// UUID ثابت مشتق من requestCode كي يُلغى بدون تخزين أي ربط.
  /// المنبّه الأصلي يبدأ بـ a، ومنبّه التأجيل بـ 5 (لا نعيد جدولة نفس المعرّف وهو يرنّ).
  static func alarmId(_ requestCode: Int, snooze: Bool) -> UUID {
    let hex = String(format: "%012llx", UInt64(UInt32(truncatingIfNeeded: requestCode)))
    return UUID(uuidString: "\(snooze ? "5" : "a")0000000-0000-4000-8000-\(hex)")!
  }

  static func ensureAuthorized() async -> Bool {
    let manager = AlarmManager.shared
    switch manager.authorizationState {
    case .authorized:
      return true
    case .denied:
      return false
    case .notDetermined:
      return (try? await manager.requestAuthorization()) == .authorized
    @unknown default:
      return false
    }
  }

  static func scheduleFromArgs(_ args: [String: Any]) async throws -> Bool {
    guard
      let rc = (args["requestCode"] as? NSNumber)?.intValue,
      let timeMs = (args["time"] as? NSNumber)?.doubleValue
    else { return false }
    guard await ensureAuthorized() else { return false }

    let eventStartMs = (args["eventStartTime"] as? NSNumber)?.doubleValue ?? 0
    try await schedule(
      requestCode: rc,
      at: Date(timeIntervalSince1970: timeMs / 1000),
      title: (args["title"] as? String) ?? "⏰ تذكير",
      eventStart: eventStartMs > 0 ? Date(timeIntervalSince1970: eventStartMs / 1000) : nil,
      snooze: false
    )
    return true
  }

  static func schedule(
    requestCode: Int,
    at date: Date,
    title: String,
    eventStart: Date?,
    snooze: Bool
  ) async throws {
    let id = alarmId(requestCode, snooze: snooze)
    // إعادة الجدولة لنفس الحدث تستبدل المنبّه السابق.
    try? AlarmManager.shared.cancel(id: id)

    let stopButton = AlarmButton(text: "إيقاف", textColor: .white, systemImageName: "stop.circle")
    let canSnooze = eventStart.map { $0.timeIntervalSince(date) >= snoozeSeconds } ?? false

    let alert: AlarmPresentation.Alert
    var secondaryIntent: SnoozeEventAlarmIntent?
    if canSnooze {
      alert = AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: title),
        stopButton: stopButton,
        secondaryButton: AlarmButton(text: "تأجيل 5 د", textColor: .white, systemImageName: "zzz"),
        secondaryButtonBehavior: .custom
      )
      secondaryIntent = SnoozeEventAlarmIntent(
        requestCode: requestCode,
        title: title,
        eventStartMs: Int((eventStart?.timeIntervalSince1970 ?? 0) * 1000),
        fromSnooze: snooze
      )
    } else {
      alert = AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: title),
        stopButton: stopButton
      )
    }

    let attributes = AlarmAttributes<EventAlarmMetadata>(
      presentation: AlarmPresentation(alert: alert),
      metadata: EventAlarmMetadata(),
      tintColor: .orange
    )

    let configuration = AlarmManager.AlarmConfiguration<EventAlarmMetadata>.alarm(
      schedule: .fixed(date),
      attributes: attributes,
      stopIntent: nil,
      secondaryIntent: secondaryIntent,
      sound: .named("event_alarm.caf")
    )

    _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    NSLog("[AlarmKit] scheduled rc=\(requestCode) snooze=\(snooze) at=\(date)")
  }

  static func cancel(requestCode: Int) {
    try? AlarmManager.shared.cancel(id: alarmId(requestCode, snooze: false))
    try? AlarmManager.shared.cancel(id: alarmId(requestCode, snooze: true))
    NSLog("[AlarmKit] cancelled rc=\(requestCode)")
  }
}

/// زر "تأجيل" على شاشة المنبّه: يوقف المنبّه الحالي ويجدول واحداً بعد 5 دقائق
/// (ينفّذ داخل عملية التطبيق بدون فتحه).
@available(iOS 26.0, *)
struct SnoozeEventAlarmIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Snooze event alarm"
  static var isDiscoverable: Bool = false

  @Parameter(title: "Request code") var requestCode: Int
  @Parameter(title: "Title") var alarmTitle: String
  @Parameter(title: "Event start (ms)") var eventStartMs: Int
  @Parameter(title: "From snooze") var fromSnooze: Bool

  init() {}

  init(requestCode: Int, title: String, eventStartMs: Int, fromSnooze: Bool) {
    self.requestCode = requestCode
    self.alarmTitle = title
    self.eventStartMs = eventStartMs
    self.fromSnooze = fromSnooze
  }

  func perform() async throws -> some IntentResult {
    try? AlarmManager.shared.stop(id: EventAlarmKit.alarmId(requestCode, snooze: fromSnooze))

    let eventStart = eventStartMs > 0
      ? Date(timeIntervalSince1970: TimeInterval(eventStartMs) / 1000) : nil
    let at = Date().addingTimeInterval(EventAlarmKit.snoozeSeconds)
    if let eventStart, eventStart.timeIntervalSince(Date()) >= EventAlarmKit.snoozeSeconds {
      // نبدّل المعرّف (أصلي <-> تأجيل) كي لا نعيد جدولة المنبّه الذي يرنّ الآن.
      try await EventAlarmKit.schedule(
        requestCode: requestCode,
        at: at,
        title: alarmTitle,
        eventStart: eventStart,
        snooze: !fromSnooze
      )
    }
    return .result()
  }
}

#endif
