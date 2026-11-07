import 'dart:ui';
import 'package:flutter/material.dart';

/// Глобальный флаг тёмной темы — синхронизируется из AppState.
class SuzopTheme {
  static bool dark = false;
}

/// Цвета приложения: подстраиваются под светлую/тёмную тему.
class SuzopColors {
  static Color get ink =>
      SuzopTheme.dark ? const Color(0xFFEAF4FF) : const Color(0xFF12365C);
  static Color get muted =>
      SuzopTheme.dark ? const Color(0xFF8FA9C6) : const Color(0xFF5F7FA3);
  static const blue = Color(0xFF2E7CF6);
  static const green = Color(0xFF1FBF6B);
  static const amber = Color(0xFFE8A23C);
  static const red = Color(0xFFE2574C);
}

/// Небесный фон с плавными цветными пятнами (ночью — тёмное небо).
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: SuzopTheme.dark
                ? const [
                    Color(0xFF0B1E33),
                    Color(0xFF10294A),
                    Color(0xFF18395F)
                  ]
                : const [
                    Color(0xFF8CC9F0),
                    Color(0xFFB8E0FA),
                    Color(0xFFE3F3FE)
                  ],
          ),
        ),
        child: const Stack(children: [
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
  Widget build(BuildContext context) => Opacity(
        // В тёмной теме пятна становятся еле заметным свечением.
        opacity: SuzopTheme.dark ? 0.10 : 1,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
          ),
        ),
      );
}

/// Карточка «жидкое стекло»: размытие фона + слоистый градиент.
/// В тёмной теме — тёмное «ночное» стекло, как в iOS.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const GlassCard({super.key, required this.child,
    this.padding = const EdgeInsets.all(14), this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final dark = SuzopTheme.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-1, -1),
              end: const Alignment(1, 1),
              colors: dark
                  ? [
                      Colors.white.withValues(alpha: .12),
                      Colors.white.withValues(alpha: .04),
                      Colors.white.withValues(alpha: .09),
                    ]
                  : [
                      Colors.white.withValues(alpha: .62),
                      Colors.white.withValues(alpha: .18),
                      Colors.white.withValues(alpha: .45),
                    ],
              stops: const [0, .45, 1],
            ),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: .20)
                  : Colors.white.withValues(alpha: .75),
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: .45)
                    : const Color(0xFF174880).withValues(alpha: .22),
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
}
