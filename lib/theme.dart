import 'dart:ui';
import 'package:flutter/material.dart';

class SuzopColors {
  static const ink = Color(0xFF12365C);
  static const muted = Color(0xFF5F7FA3);
  static const blue = Color(0xFF2E7CF6);
  static const green = Color(0xFF1FBF6B);
  static const amber = Color(0xFFE8A23C);
  static const red = Color(0xFFE2574C);
}

/// Небесный фон с плавными цветными пятнами (их «преломляет» стекло).
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key});
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8CC9F0), Color(0xFFB8E0FA), Color(0xFFE3F3FE)],
      ),
    ),
    child: Stack(children: [
      Positioned(top: -120, left: -90, child: _Blob(Color(0xFFFFD9A0), 300)),
      Positioned(top: 100, right: -140, child: _Blob(Color(0xFF9AD0FF), 340)),
      Positioned(bottom: 60, left: -130, child: _Blob(Color(0xFFB7F0D2), 300)),
      Positioned(bottom: -80, right: -60, child: _Blob(Color(0xFFE3C0FF), 260)),
    ]),
  );
}

class _Blob extends StatelessWidget {
  final Color c;
  final double d;
  const _Blob(this.c, this.d);
  @override
  Widget build(BuildContext context) => Container(
    width: d,
    height: d,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
    ),
  );
}

/// Карточка «жидкое стекло»: размытие фона + слоистый белый градиент.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const GlassCard({super.key, required this.child,
    this.padding = const EdgeInsets.all(14), this.radius = 20});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-1, -1),
            end: const Alignment(1, 1),
            colors: [
              Colors.white.withValues(alpha: .62),
              Colors.white.withValues(alpha: .18),
              Colors.white.withValues(alpha: .45),
            ],
            stops: const [0, .45, 1],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .75)),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF174880).withValues(alpha: .22),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}
