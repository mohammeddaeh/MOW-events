import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mow_events/features/alarm/presentation/controllers/alarm_ringing_controller.dart';
import 'package:mow_events/features/alarm/presentation/widgets/alarm_circular_drag_pad.dart';

/// واجهة منبّه ملء الشاشة (أسلوب قريب من Samsung): خلفية داكنة متكيّفة، وقت كبير، سحب دائري.
class AlarmScreen extends GetView<AlarmRingingController> {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLight = brightness == Brightness.light;
    final bgTop = isLight ? const Color(0xFFE8EAEF) : const Color(0xFF0A0C12);
    final bgMid = isLight ? const Color(0xFFD8DCE6) : const Color(0xFF05060A);
    final bgBot = isLight ? const Color(0xFFCED4E0) : const Color(0xFF030408);
    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        brightness: isLight ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: bgMid,
        colorScheme: isLight
            ? ColorScheme.light(
                primary: const Color(0xFF3949AB),
                primaryContainer: const Color(0xFFDDE1F5),
                surface: const Color(0xFFF5F6FA),
              )
            : ColorScheme.dark(
                primary: const Color(0xFF5C6BC0),
                primaryContainer: const Color(0xFF1E2740),
                surface: const Color(0xFF0E1118),
              ),
      ),
      child: Scaffold(
        backgroundColor: bgMid,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bgTop, bgMid, bgBot],
                ),
              ),
            ),
            Positioned(
              top: -90,
              left: -60,
              child: _AmbientGlow(
                color: isLight ? const Color(0xFF8AA0FF) : const Color(0xFF4E63B6),
              ),
            ),
            Positioned(
              top: 70,
              right: -70,
              child: _AmbientGlow(
                color: isLight ? const Color(0xFFA5B4FC) : const Color(0xFF2A335B),
                size: 220,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 34),
                    _AlarmClockText(controller: controller),
                    const SizedBox(height: 28),
                    _AlarmEventBlock(controller: controller),
                    const Spacer(),
                    _AlarmDragBlock(controller: controller),
                    const SizedBox(height: 12),
                    _HintRow(controller: controller),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color, this.size = 260});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.32),
              color.withValues(alpha: 0.12),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _AlarmClockText extends StatelessWidget {
  const _AlarmClockText({required this.controller});

  final AlarmRingingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Colors.white.withValues(alpha: 0.96)
        : Colors.black87;

    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          controller.clockLabel.value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 78,
            fontWeight: FontWeight.w200,
            letterSpacing: 2.2,
            color: color,
            height: 1.03,
            shadows: [
              Shadow(
                blurRadius: 24,
                offset: const Offset(0, 10),
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlarmEventBlock extends StatelessWidget {
  const _AlarmEventBlock({required this.controller});

  final AlarmRingingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.white : Colors.black87;
    final secondary = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black54;
    final tertiary = isDark
        ? Colors.white.withValues(alpha: 0.42)
        : Colors.black45;

    return Obx(() {
      controller.payload.value;
      final title = controller.title;
      final loc = controller.location;
      final startLbl = controller.startTimeLabel;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: primary,
              ),
            ),
            if (loc.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                loc,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: secondary),
              ),
            ],
            if (startLbl.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                startLbl,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: tertiary),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _AlarmDragBlock extends StatelessWidget {
  const _AlarmDragBlock({required this.controller});

  final AlarmRingingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.policyTick.value;
      final allowSnooze = controller.snoozeAllowed;

      return Center(
        child: AlarmCircularDragPad(
          snoozeAllowed: allowSnooze,
          onDismiss: () => controller.dismiss(),
          onSnooze: () => controller.snoozeFiveMinutes(),
        ),
      );
    });
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.controller});

  final AlarmRingingController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black45;

    return Obx(() {
      controller.policyTick.value;
      final showSnooze = controller.snoozeAllowed;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSnooze) ...[
            Icon(Icons.west_rounded, size: 16, color: muted),
            const SizedBox(width: 6),
            Text(
              'تأجيل ٥ د',
              style: TextStyle(
                fontSize: 13,
                color: muted.withValues(alpha: 0.9),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '|',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black26,
                ),
              ),
            ),
          ],
          Icon(Icons.east_rounded, size: 16, color: muted),
          const SizedBox(width: 6),
          Text(
            'إيقاف',
            style: TextStyle(fontSize: 13, color: muted.withValues(alpha: 0.9)),
          ),
        ],
      );
    });
  }
}
