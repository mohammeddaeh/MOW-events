import 'package:audioplayers/audioplayers.dart';

/// تشغيل صوت المنبّه بشكل متكرر داخل [AlarmScreen] على iOS (تعويض عن عدم
/// إمكانية تشغيل نغمة مستمرة عبر إشعار النظام وحده).
class IosAlarmSoundPlayer {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> start() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/alarm_sound.mp3'));
  }

  static Future<void> stop() async {
    await _player.stop();
  }
}
