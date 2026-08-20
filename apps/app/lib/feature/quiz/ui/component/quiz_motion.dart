import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// クイズ画面共通のモーション部品。
///
/// いずれも `MediaQuery.disableAnimations` を尊重し、OS 側でアニメーション
/// 抑制が指定されている場合は最終状態を即座に表示する。

/// アニメーションを再生してよいかどうか。
bool motionEnabled(BuildContext context) => !MediaQuery.disableAnimationsOf(context);

/// マウント時に 1 度だけ再生するフェード + スライドイン。
///
/// [delay] で開始を遅らせられるため、複数並べるとスタッガー演出になる。
class Entrance extends StatelessWidget {
  const Entrance({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.offset = const Offset(0, 0.15),
    this.scaleFrom,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// スライド開始位置（子のサイズ比）。`Offset.zero` でフェードのみ。
  final Offset offset;

  /// 指定するとスケールインも併用する（1.0 に向かって拡大）。
  final double? scaleFrom;

  @override
  Widget build(BuildContext context) {
    if (!motionEnabled(context)) {
      return child;
    }
    final total = delay + duration;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, t, child) {
        Widget result = Opacity(opacity: t, child: child);
        if (offset != Offset.zero) {
          result = FractionalTranslation(
            translation: Offset(offset.dx * (1 - t), offset.dy * (1 - t)),
            child: result,
          );
        }
        final scaleFrom = this.scaleFrom;
        if (scaleFrom != null) {
          result = Transform.scale(
            scale: scaleFrom + (1 - scaleFrom) * t,
            child: result,
          );
        }
        return result;
      },
    );
  }
}

/// ゆっくり脈動する強調表示。待機画面のアイコンなどに使う。
class Pulse extends HookWidget {
  const Pulse({
    required this.child,
    this.minScale = 1,
    this.maxScale = 1.08,
    this.duration = const Duration(milliseconds: 900),
    super.key,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);
    final enabled = motionEnabled(context);
    useEffect(() {
      if (enabled) {
        unawaited(controller.repeat(reverse: true));
      } else {
        controller.stop();
      }
      return null;
    }, [enabled]);
    if (!enabled) {
      return child;
    }
    return ScaleTransition(
      scale: Tween<double>(begin: minScale, end: maxScale).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
      child: child,
    );
  }
}

/// 数値をカウントアップ表示する。`value` の変化にも追従する。
class CountUpText extends HookWidget {
  const CountUpText(
    this.value, {
    required this.builder,
    this.duration = const Duration(milliseconds: 800),
    super.key,
  });

  final int value;
  final Duration duration;
  final Widget Function(BuildContext context, int value) builder;

  @override
  Widget build(BuildContext context) {
    if (!motionEnabled(context)) {
      return builder(context, value);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => builder(context, animated.round()),
    );
  }
}

/// 正解演出用の紙吹雪。マウント時に 1 度だけ舞い、自然に消える。
///
/// 画面全体を覆う `Stack` の最前面に `IgnorePointer` 付きで重ねて使う。
class ConfettiBurst extends HookWidget {
  const ConfettiBurst({this.particleCount = 90, super.key});

  final int particleCount;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1600),
    );
    final scheme = Theme.of(context).colorScheme;
    final particles = useMemoized(() {
      final random = math.Random();
      final colors = [
        scheme.primary,
        scheme.secondary,
        scheme.tertiary,
        scheme.primaryFixedDim,
        scheme.secondaryFixedDim,
        scheme.tertiaryFixedDim,
      ];
      return List.generate(particleCount, (index) {
        return _ConfettiParticle(
          origin: Offset(random.nextDouble(), -0.05 - random.nextDouble() * 0.1),
          velocity: Offset(
            (random.nextDouble() - 0.5) * 0.4,
            0.6 + random.nextDouble() * 0.8,
          ),
          size: 5 + random.nextDouble() * 5,
          rotationSpeed: (random.nextDouble() - 0.5) * 10,
          color: colors[index % colors.length],
        );
      });
    }, const []);
    final enabled = motionEnabled(context);
    useEffect(() {
      if (enabled) {
        unawaited(controller.forward());
      }
      return null;
    }, [enabled]);
    if (!enabled) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(particles: particles, progress: controller.value),
      ),
    );
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.origin,
    required this.velocity,
    required this.size,
    required this.rotationSpeed,
    required this.color,
  });

  final Offset origin;
  final Offset velocity;
  final double size;
  final double rotationSpeed;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.particles, required this.progress});

  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) {
      return;
    }
    // 終盤 30% でフェードアウトさせる。
    final opacity = progress > 0.7 ? (1 - progress) / 0.3 : 1.0;
    final paint = Paint();
    for (final particle in particles) {
      final dx = (particle.origin.dx + particle.velocity.dx * progress) * size.width;
      // 進行に対して二乗で落下させ、重力による加速を近似する。
      final dy = (particle.origin.dy + particle.velocity.dy * progress * (0.4 + progress)) * size.height;
      if (dy > size.height) {
        continue;
      }
      paint.color = particle.color.withValues(alpha: opacity);
      canvas
        ..save()
        ..translate(dx, dy)
        ..rotate(particle.rotationSpeed * progress)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.6),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
