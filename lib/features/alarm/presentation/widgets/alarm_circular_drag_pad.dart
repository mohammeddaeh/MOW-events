import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// زر دائري وسط الشاشة: سحب لليمين → إيقاف، لليسار → تأجيل 5 دقائق (إن وُجد).
class AlarmCircularDragPad extends StatefulWidget {
  const AlarmCircularDragPad({
    super.key,
    required this.snoozeAllowed,
    required this.onDismiss,
    required this.onSnooze,
    this.size = 196,
  });

  final bool snoozeAllowed;
  final VoidCallback onDismiss;
  final VoidCallback onSnooze;
  final double size;

  @override
  State<AlarmCircularDragPad> createState() => _AlarmCircularDragPadState();
}

class _AlarmCircularDragPadState extends State<AlarmCircularDragPad>
    with TickerProviderStateMixin {
  double _dragX = 0;

  late final AnimationController _snapCtrl;
  Animation<double>? _snapAnim;

  static const double _thresholdPx = 88;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380))
      ..addListener(() {
        final a = _snapAnim;
        if (a != null) {
          setState(() => _dragX = a.value);
        }
      });
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _snapBack() {
    final from = _dragX;
    _snapCtrl.stop();
    _snapCtrl.reset();
    _snapCtrl.duration = const Duration(milliseconds: 520);
    _snapAnim = Tween<double>(begin: from, end: 0).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut),
    );
    _snapCtrl.forward(from: 0);
  }

  void _onEnd() {
    if (_dragX >= _thresholdPx) {
      HapticFeedback.heavyImpact();
      widget.onDismiss();
      return;
    }
    if (widget.snoozeAllowed && _dragX <= -_thresholdPx) {
      HapticFeedback.heavyImpact();
      widget.onSnooze();
      return;
    }
    HapticFeedback.selectionClick();
    _snapBack();
  }

  double _clampDrag(double dx) {
    final maxR = widget.size * 0.62;
    if (!widget.snoozeAllowed && dx < 0) return 0;
    return dx.clamp(-maxR, maxR);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintBase = isDark ? Colors.white : Colors.black87;

    final dismissT = (_dragX / _thresholdPx).clamp(0.0, 1.0);
    final snoozeT = widget.snoozeAllowed
        ? ((-_dragX) / _thresholdPx).clamp(0.0, 1.0)
        : 0.0;

    const base = Color(0xFF1E2740);
    final dismissTint = Color.lerp(
      base,
      const Color(0xFF2E7D32),
      dismissT * 0.9,
    )!;
    final snoozeTint = Color.lerp(
      base,
      const Color(0xFF1565C0),
      snoozeT * 0.9,
    )!;
    final orbColor = Color.lerp(snoozeTint, dismissTint, dismissT)!;

    return RepaintBoundary(
      child: SizedBox(
      width: widget.size + 120,
      height: widget.size + 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.snoozeAllowed)
            Positioned(
              left: 4,
              child: Icon(
                Icons.snooze_rounded,
                color: hintBase.withValues(alpha: 0.32 + snoozeT * 0.48),
                size: 30,
              ),
            ),
          Positioned(
            right: 4,
            child: Icon(
              Icons.close_rounded,
              color: hintBase.withValues(alpha: 0.32 + dismissT * 0.48),
              size: 30,
            ),
          ),
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) {
                setState(() {
                  _dragX = _clampDrag(_dragX + d.delta.dx);
                });
              },
              onHorizontalDragEnd: (_) => _onEnd(),
              child: Transform.translate(
                offset: Offset(_dragX, 0),
                child: _BreathingOrb(
                  diameter: widget.size,
                  color: orbColor,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _BreathingOrb extends StatefulWidget {
  const _BreathingOrb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  State<_BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<_BreathingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final s = 1 + 0.04 * math.sin(_breath.value * math.pi * 2);
        return Transform.scale(scale: s, child: child);
      },
      child: Container(
        width: widget.diameter,
        height: widget.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.color.withValues(alpha: 0.96),
              widget.color.withValues(alpha: 0.52),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.42),
              blurRadius: 26,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          Icons.alarm_rounded,
          size: widget.diameter * 0.38,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.98),
        ),
      ),
    );
  }
}
