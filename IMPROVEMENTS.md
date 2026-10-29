# اقتراحات تحسينية

ملاحظات معروفة لم تُنفَّذ بعد. كل بند يذكر المشكلة، مكانها في الكود، والحل المقترح.

---

## التذكيرات

### 1. إضافة تذكير لحدث بدأ فعلاً — رسالة مضلِّلة
- **المشكلة:** في شاشة تذكيرات الحدث، إذا كان الحدث قد بدأ، كل قيمة تُرفض برسالة "وقت هذا التذكير قد مضى. اختر قيمة أقل" — مع أنه لا توجد قيمة تنجح.
- **المكان:** `lib/features/event/presentation/widgets/reminder_sheet.dart` (`_addCustomReminder`)، والتحقق في `ReminderEntity.validateCustom`.
- **الحل المقترح:** إذا كان `event.startDateTimeSafe` في الماضي: إخفاء زر "إضافة تذكير" أو إظهار رسالة "الحدث بدأ، لا يمكن إضافة تذكيرات".

### 2. التذكيرات الشخصية تصبح ماضية بصمت عند تغيير موعد الحدث
- **المشكلة:** عند تعديل موعد حدث، تُعاد حسابات أوقات التذكيرات الشخصية (من شاشة التذكيرات). إن صار وقت أحدها في الماضي ينتقل إلى "التذكيرات السابقة" ولا يرن، بدون أي تنبيه للمستخدم.
- **المكان:** `ReminderController.onEventUpdated` → `_buildSyncedRemindersForEvent` في `lib/features/event/presentation/controller/reminder_controller.dart`.
- **الحل المقترح:** بعد التحديث، إن وُجدت تذكيرات شخصية صارت ماضية، إظهار تنبيه للمستخدم مع خيار حذفها أو تعديلها.
- **ملاحظة:** تذكيرات الحدث نفسه (من شاشة تعديل الحدث) محمية: الحفظ يُمنع إن صار وقتها في الماضي.

### 3. منع تكرار المنبهات يحذف التذكير الشخصي نهائياً
- **المشكلة:** عند تطابق تذكير الحدث مع تذكير شخصي بنفس الوحدة والقيمة، يُبقى منبه واحد (تذكير الحدث) ويُحذف الشخصي من القائمة. إن حذف منشئ الحدث تذكيره لاحقاً، لا يعود تذكير المستخدم الشخصي.
- **المكان:** `_buildSyncedRemindersForEvent` (منطق `claim`) في `reminder_controller.dart`.
- **الحل المقترح:** إبقاء التذكير الشخصي محفوظاً لكن بدون جدولة منبه طالما يوجد تذكير حدث مطابق، وإعادة جدولته تلقائياً إذا أُزيل تذكير الحدث.

### 4. التذكيرات الافتراضية تُضاف لأحداث قريبة كتذكيرات منتهية
- **المشكلة:** عند تطبيق تذكير افتراضي (مثلاً "قبل يوم") على حدث يبدأ بعد ساعة، يُضاف للقائمة بوقت ماضٍ — لا يرن، ويظهر في "التذكيرات السابقة" كضجيج.
- **المكان:** `applySingleDefaultToAllEvents` و `_buildSyncedRemindersForEvent` في `reminder_controller.dart`.
- **الحل المقترح:** تجاهل التذكير الافتراضي لحدث معيّن إذا كان وقته المحسوب في الماضي.

### 5. حالات لم تُراجَع بعد
- التأجيل (snooze) وسلوكه مع تعديل التذكير أو الحدث.
- تغيير وقت الجهاز أو المنطقة الزمنية.
- إعادة تشغيل الجهاز (هل تُعاد جدولة المنبهات).
- سلوك المنبه على الآيفون.

### 6. التذكيرات على الآيفون لا تظهر ولا ترن (مُبلَّغ عنه من التجربة)
- **المشكلة:** على iPhone لا يظهر تذكير الحدث ولا يرن في موعده.
- **ملاحظات من الكود (لم تُتحقَّق على جهاز):**
  - جدولة كل تذكير على حدة تتم في `ReminderController.scheduleAlarmNative` عبر `MethodChannel('alarm_channel')` → `scheduleAlarm`. هذا الـ channel مُنفَّذ على Android فقط (`AlarmMethodChannel.kt`)، ولا يوجد له مقابل في `ios/Runner/AppDelegate.swift`. على iOS يرمي `MissingPluginException`، والكود يلتقط `PlatformException` فقط — فقد يفشل التعديل/الإضافة كاملاً ويظهر "حدث خطأ غير متوقع".
  - على iOS يوجد مسار منفصل في `EventAlarmService._syncFromEventsIos` (`lib/core/alarm/event_alarm_service.dart`) يجدول **منبّهاً واحداً لكل حدث** (`effectiveNativeAlarmTime`) عبر `IosEventAlarmNotifications` (`lib/core/alarm/ios_alarm_notifications.dart`)، وليس تذكيراً لكل عنصر في قائمة التذكيرات. أي أن التذكيرات المتعددة لنفس الحدث (قبل يوم، قبل ساعة...) لا تُجدول على iOS.
  - الجدولة بـ `zonedSchedule` تعتمد على أذونات الإشعارات وعلى `interruptionLevel: timeSensitive` الذي يحتاج تفعيل "Time Sensitive Notifications" في Xcode capabilities.
- **الحل المقترح:**
  1. على iOS، جعل `scheduleAlarmNative` و `cancelAlarmNative` يستخدمان `IosEventAlarmNotifications` (جدولة إشعار محلي لكل تذكير بـ `alarmId` كمعرّف) بدل `alarm_channel`.
  2. التقاط `MissingPluginException` (أو `catch (_)`) في استدعاءات الـ channel حتى لا يفشل حفظ التذكير.
  3. التحقق على جهاز: `pendingNotificationRequests()` بعد إضافة تذكير يجب أن يحوي إشعاراً لكل تذكير قادم.

### 7. لا يوجد صوت لإشعارات الآيفون (مُبلَّغ عنه من التجربة)
- **المشكلة:** الإشعارات تصل على iPhone بدون صوت.
- **ملاحظات من الكود (لم تُتحقَّق على جهاز):**
  - إشعارات FCM القادمة والتطبيق في الخلفية/مغلق يعرضها iOS نفسه، والصوت يُحدَّد من **الباك إند**: يجب أن تحوي الرسالة `apns.payload.aps.sound = "default"` (أو `notification.sound`). بدونها تصل صامتة.
  - الإشعارات المحلية التي يعرضها التطبيق والتطبيق مفتوح (`NotificationsController._showLocalNotification`) تمرّر تفاصيل Android فقط (`AndroidNotificationDetails`) بدون `DarwinNotificationDetails(presentSound: true)`.
  - منبّهات التذكير على iOS تستخدم الصوت الافتراضي للنظام (لا يوجد ملف صوت مخصّص `.caf` مضاف لمشروع Xcode — حسب تعليق في `ios_alarm_notifications.dart`).
- **الحل المقترح:**
  1. **الباك إند:** إضافة `sound: "default"` لكل رسالة FCM في جزء `apns.payload.aps` (و `notification.sound` لـ Android).
  2. **التطبيق:** إضافة `iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true)` في `_showLocalNotification`.
  3. التأكد أن المستخدم لم يُطفئ الصوت للتطبيق من إعدادات iOS ← الإشعارات، وأن وضع الصامت/التركيز لا يمنعه.

### 8. لا توجد اختبارات آلية للتذكيرات
- **الحل المقترح:** إضافة unit tests لـ `ReminderEntity.validateCustom` و `calculateTime` ومنطق `_buildSyncedRemindersForEvent` (منع التكرار، إعادة الحساب عند تغيير الموعد)، وقائمة حالات يدوية تُجرَّب على الجهاز قبل كل إصدار.
