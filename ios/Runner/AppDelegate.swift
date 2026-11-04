import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ضروري لـ flutter_local_notifications و firebase_messaging: بدونه لا تظهر
    // الإشعارات والتطبيق مفتوح ولا يصل حدث الضغط على الإشعار.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate

    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "EventAlarmKit") {
      EventAlarmKitChannel.register(with: registrar.messenger())
    }
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // إشعار منبّه وصل والتطبيق مفتوح: نفتح شاشة المنبّه مباشرة (تكمل الرنين).
  // flutter_local_notifications يخزّن الحمولة تحت المفتاح "payload".
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if let payload = notification.request.content.userInfo["payload"] as? String,
       payload.contains("\"event_alarm\"") {
      EventAlarmKitChannel.notifyAlarmPresented(payload: payload)
      // الشاشة نفسها ترنّ؛ لا نعرض بانر/صوت فوقها.
      completionHandler([])
      return
    }
    super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
  }
}
