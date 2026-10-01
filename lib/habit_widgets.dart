import 'package:flutter/material.dart';
import 'core.dart';

/// A heavy, animated progress line used for habit consistency.
/// - The fill eases to its value (and re-eases whenever the value changes).
/// - A soft sheen drifts across the fill; it is skipped when the system
///   "remove animations" setting is on.
class ConsistencyLine extends StatefulWidget {
  const ConsistencyLine({super.key, required this.value, this.color, this.height = 14});
  final double value;
  final Color? color;
  final double height;
  @override
  State<ConsistencyLine> createState() => _ConsistencyLineState();
}

class _ConsistencyLineState extends State<ConsistencyLine> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _sheen.stop();
    } else if (!_sheen.isAnimating) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? Accent.color;
    final target = widget.value.isNaN ? 0.0 : widget.value.clamp(0.0, 1.0).toDouble();
    final r = BorderRadius.circular(widget.height);
    return Semantics(
      label: 'Consistency',
      value: '${(target * 100).round()} percent',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: target),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, cons) {
              final w = cons.maxWidth;
              // never narrower than a full pill so the rounded end never looks cut
              final fillW = v <= 0 ? 0.0 : (w * v).clamp(widget.height, w).toDouble();
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: r))),
                  if (fillW > 0)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: fillW,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: r,
                          gradient: LinearGradient(colors: [c, Color.lerp(c, Colors.white, 0.28) ?? c]),
                          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 12)],
                        ),
                        child: ClipRRect(
                          borderRadius: r,
                          child: AnimatedBuilder(
                            animation: _sheen,
                            builder: (_, __) => Transform.translate(
                              offset: Offset((fillW + 70) * _sheen.value - 70, 0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.32), Colors.white.withValues(alpha: 0)]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
