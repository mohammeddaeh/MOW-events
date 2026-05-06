import 'package:flutter/material.dart';

/// عُطّل: كان يعتمد على حزمة `alarm` (غير مضافة في المشروع).
///
/// المنبّه الإنتاجي يعرض عبر Android [FullScreenAlarmActivity] وواجهة Flutter
/// [AlarmScreen] مع قناة `alarm_ringing_channel`.
///
/// إذا احتجت لفّ التطبيق بهذا الـ host، استخدم هذا الـ widget كهوية فقط.
class AlarmRingingHost extends StatelessWidget {
  const AlarmRingingHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
