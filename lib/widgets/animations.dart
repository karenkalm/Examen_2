import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Aparece con un desvanecido y un pequeño deslizamiento hacia arriba.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.offsetY = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    final total = delay + duration;
    final start = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) {
        return Opacity(
          opacity: value < 0 ? 0 : (value > 1 ? 1 : value),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * offsetY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Sacude su contenido cada vez que cambia [trigger] (por ejemplo, cuando
/// el login falla).
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void didUpdateWidget(covariant Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 5) * 12 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
