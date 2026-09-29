import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class C {
  static const base = Color(0xFF0B0B10);
  static const lime = Color(0xFFD4F25C);
  static const violet = Color(0xFF7B5CFF);
  static const teal = Color(0xFF00D9C0);
  static const orange = Color(0xFFF59E4B);
  static const coral = Color(0xFFFF6B6B);
  static const text = Color(0xFFF2F2F0);
  static const mute = Color(0xFF9A9AA2);
}

class GlassConfig {
  static double blur = 24;
  static double auroraIntensity = 1.0;
}

const List<IconData> habitIcons = [
  Icons.menu_book_rounded,
  Icons.fitness_center_rounded,
  Icons.self_improvement_rounded,
  Icons.water_drop_rounded,
  Icons.bedtime_rounded,
  Icons.local_fire_department_rounded,
  Icons.code_rounded,
  Icons.brush_rounded,
  Icons.language_rounded,
  Icons.music_note_rounded,
  Icons.restaurant_rounded,
  Icons.directions_run_rounded,
];

const List<String> categories = ['Study', 'Work', 'Personal', 'Other'];

Color categoryColor(String category) {
  switch (category) {
    case 'Study':
      return C.teal;
    case 'Work':
      return C.violet;
    case 'Personal':
      return C.orange;
    default:
      return C.lime;
  }
}

const TextStyle h1Light = TextStyle(fontSize: 34, height: 1.15, fontWeight: FontWeight.w300, color: C.text);
const TextStyle h1Bold = TextStyle(fontSize: 34, height: 1.15, fontWeight: FontWeight.w700, color: C.lime);
const TextStyle subStyle = TextStyle(fontSize: 15, height: 1.55, fontWeight: FontWeight.w400, color: C.mute);
const EdgeInsets pagePad = EdgeInsets.fromLTRB(24, 24, 24, 140);

String fmtHour(int i) {
  final h = i % 12 == 0 ? 12 : i % 12;
  return '$h:00 ${i < 12 ? 'AM' : 'PM'}';
}

String fmtMinutes(int minutesSinceMidnight) {
  final h = (minutesSinceMidnight ~/ 60) % 24;
  final m = minutesSinceMidnight % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final mm = m.toString().padLeft(2, '0');
  return '$h12:$mm ${h < 12 ? 'AM' : 'PM'}';
}

String fmtDurationShort(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

String dateLabel(DateTime d) {
  const wd = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
  const mo = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  return '${wd[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]}';
}

String weekdayShort(int weekday) {
  const wd = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return wd[weekday - 1];
}

String dayKey(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class _Blob {
  const _Blob(this.color, this.alpha, this.cx, this.cy, this.r, this.sx, this.sy, this.phase);
  final Color color;
  final double alpha, cx, cy, r, phase;
  final int sx, sy;
}

class _Star {
  const _Star(this.x, this.y, this.r, this.phase, this.k);
  final double x, y, r, phase;
  final int k;
}

class AuroraPainter extends CustomPainter {
  AuroraPainter(this.t);
  final double t;

  static const _blobs = [
    _Blob(C.violet, .55, .25, .20, .85, 1, 2, 0.0),
    _Blob(C.teal, .36, .85, .45, .75, 2, 1, 2.1),
    _Blob(C.lime, .15, .15, .80, .70, 1, 1, 4.0),
    _Blob(C.orange, .20, .90, .95, .70, 2, 3, 5.2),
  ];

  static final List<_Star> _stars = () {
    final r = math.Random(11);
    return List.generate(
      40,
      (i) => _Star(r.nextDouble(), r.nextDouble(), .5 + r.nextDouble() * 1.1, r.nextDouble() * 6.28, 3 + r.nextInt(6)),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = C.base);
    const tau = 2 * math.pi;
    final k = GlassConfig.auroraIntensity;
    for (final b in _blobs) {
      final c = Offset(
        size.width * (b.cx + 0.20 * math.sin(tau * t * b.sx + b.phase)),
        size.height * (b.cy + 0.12 * math.cos(tau * t * b.sy + b.phase)),
      );
      final radius = size.longestSide * b.r * 0.55 * (1 + 0.08 * math.sin(tau * t * 2 + b.phase));
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [b.color.withValues(alpha: (b.alpha * k).clamp(0, 1).toDouble()), b.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawCircle(c, radius, paint);
    }
    for (final s in _stars) {
      final a = (0.10 + 0.40 * (0.5 + 0.5 * math.sin(tau * t * s.k + s.phase))) * k;
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        Paint()..color = Colors.white.withValues(alpha: a.clamp(0, 1).toDouble()),
      );
    }
  }

  @override
  bool shouldRepaint(AuroraPainter old) => true;
}

class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});
  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 48))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(painter: AuroraPainter(_c.value), size: Size.infinite),
      ),
    );
  }
}

class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color = C.lime});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: 12, letterSpacing: 2.4, fontWeight: FontWeight.w500, color: color),
      );
}

class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.radius = 28, this.tint = 0.08});
  final Widget child;
  final EdgeInsets padding;
  final double radius, tint;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: GlassConfig.blur, sigmaY: GlassConfig.blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: tint + 0.05), Colors.white.withValues(alpha: tint * 0.5)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: child,
        ),
      ),
    );
  }
}

class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  late final Animation<Offset> _s = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(_a);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _a, child: SlideTransition(position: _s, child: widget.child));
}

class PillButton extends StatefulWidget {
  const PillButton({super.key, required this.label, required this.onTap, this.enabled = true, this.filled = true, this.color = C.lime});
  final String label;
  final VoidCallback onTap;
  final bool enabled, filled;
  final Color color;
  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    return GestureDetector(
      onTapDown: on ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: on
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: !on ? Colors.white.withValues(alpha: 0.10) : (widget.filled ? widget.color : Colors.transparent),
            borderRadius: BorderRadius.circular(40),
            border: (!widget.filled && on) ? Border.all(color: widget.color.withValues(alpha: 0.6)) : null,
            boxShadow: (on && widget.filled)
                ? [BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 26, offset: const Offset(0, 8))]
                : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15.5,
              color: !on ? C.mute : (widget.filled ? C.base : widget.color),
            ),
          ),
        ),
      ),
    );
  }
}

class Chip2 extends StatelessWidget {
  const Chip2(this.text, {super.key, this.color = C.lime, this.selected = true});
  final String text;
  final Color color;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.14)),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? color : C.mute)),
      );
}

class GlassSheet extends StatelessWidget {
  const GlassSheet({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16161C).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  child,
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showGlassSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => GlassSheet(child: child),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.mute, letterSpacing: 0.5)),
      );
}
