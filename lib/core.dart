import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class C {
  static const base = Color(0xFF000000);
  static const lime = Color(0xFFD4F25C);
  static const violet = Color(0xFF7B5CFF);
  static const teal = Color(0xFF00D9C0);
  static const orange = Color(0xFFF59E4B);
  static const coral = Color(0xFFFF6B6B);
  static const red = Color(0xFFFF4757);
  static const yellow = Color(0xFFFFD166);
  static const blue = Color(0xFF4C8DF6);
  static const text = Color(0xFFF2F2F0);
  static const mute = Color(0xFF9A9AA2);
}

class Accent {
  static Color color = C.lime;
  static const List<Color> presets = [C.lime, C.violet, C.teal, C.orange, C.coral, C.blue];
  static const List<String> names = ['Lime', 'Violet', 'Teal', 'Orange', 'Coral', 'Blue'];
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

Color priorityColor(String priority) {
  switch (priority) {
    case 'high':
      return C.red;
    case 'low':
      return C.blue;
    default:
      return C.yellow;
  }
}

String priorityLabel(String priority) {
  switch (priority) {
    case 'high':
      return 'High';
    case 'low':
      return 'Low';
    default:
      return 'Medium';
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

class Quote {
  const Quote(this.text, this.author);
  final String text, author;
}

const List<Quote> quotes = [
  Quote('You have power over your mind, not outside events.', 'Marcus Aurelius'),
  Quote('Waste no more time arguing about a good man; be one.', 'Marcus Aurelius'),
  Quote('The impediment to action advances action.', 'Marcus Aurelius'),
  Quote('Price is what you pay, value is what you get.', 'Warren Buffett'),
  Quote('Risk comes from not knowing what you are doing.', 'Warren Buffett'),
  Quote('It takes 20 years to build a reputation, 5 minutes to ruin it.', 'Warren Buffett'),
  Quote('We suffer more in imagination than in reality.', 'Seneca'),
  Quote('Luck is what happens when preparation meets opportunity.', 'Seneca'),
  Quote('No man is free who is not master of himself.', 'Epictetus'),
  Quote('First say to yourself what you would be, then do what you must.', 'Epictetus'),
  Quote('We waste a lot of the little time we have.', 'Seneca'),
  Quote('The best time to plant a tree was years ago. The next best time is now.', 'Proverb'),
  Quote('Simplicity is the ultimate sophistication.', 'Leonardo da Vinci'),
  Quote('An investment in knowledge pays the best interest.', 'Benjamin Franklin'),
  Quote('Discipline is choosing what you want most over what you want now.', 'Abraham Lincoln'),
];

int _dayOfYear(DateTime d) => d.difference(DateTime(d.year, 1, 1)).inDays;

Quote quoteForToday() => quotes[_dayOfYear(DateTime.now()) % quotes.length];

class _Blob {
  const _Blob(this.color, this.alpha, this.cx, this.cy, this.r, this.sx, this.sy, this.phase);
  final Color color;
  final double alpha, cx, cy, r, phase;
  final int sx, sy;
}

class AuroraPainter extends CustomPainter {
  AuroraPainter(this.t);
  final double t;

  static const _blobs = [
    _Blob(C.violet, .55, .28, .22, .95, 1, 2, 0.0),
    _Blob(C.teal, .45, .78, .72, .95, 2, 1, 3.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = C.base);
    const tau = 2 * math.pi;
    final k = GlassConfig.auroraIntensity;
    for (final b in _blobs) {
      final c = Offset(
        size.width * (b.cx + 0.22 * math.sin(tau * t * b.sx + b.phase)),
        size.height * (b.cy + 0.14 * math.cos(tau * t * b.sy + b.phase)),
      );
      final radius = size.longestSide * b.r * 0.6 * (1 + 0.08 * math.sin(tau * t * 2 + b.phase));
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [b.color.withValues(alpha: (b.alpha * k).clamp(0, 1).toDouble()), b.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawCircle(c, radius, paint);
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
  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.radius = 28, this.tint = 0.08, this.glow = true});
  final Widget child;
  final EdgeInsets padding;
  final double radius, tint;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final accent = Accent.color;
    return RepaintBoundary(
      child: ClipRRect(
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
                colors: [Colors.white.withValues(alpha: tint + 0.06), Colors.white.withValues(alpha: tint * 0.45)],
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.34), width: 1),
                left: BorderSide(color: Colors.white.withValues(alpha: 0.14), width: 1),
                right: BorderSide(color: Colors.white.withValues(alpha: 0.14), width: 1),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.14), width: 1),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 26, offset: const Offset(0, 12)),
                if (glow) BoxShadow(color: accent.withValues(alpha: 0.10), blurRadius: 36),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SolidCard extends StatelessWidget {
  const SolidCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.radius = 28, this.color});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Accent.color;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.32) ?? base],
        ),
        boxShadow: [BoxShadow(color: base.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: child,
    );
  }
}

class NoGlowScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
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
  const PillButton({super.key, required this.label, required this.onTap, this.enabled = true, this.filled = true, this.color});
  final String label;
  final VoidCallback onTap;
  final bool enabled, filled;
  final Color? color;
  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    final col = widget.color ?? Accent.color;
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
            color: !on ? Colors.white.withValues(alpha: 0.10) : (widget.filled ? col : Colors.transparent),
            borderRadius: BorderRadius.circular(40),
            border: (!widget.filled && on) ? Border.all(color: col.withValues(alpha: 0.6)) : null,
            boxShadow: (on && widget.filled)
                ? [BoxShadow(color: col.withValues(alpha: 0.35), blurRadius: 26, offset: const Offset(0, 8))]
                : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5, color: !on ? C.mute : (widget.filled ? C.base : col)),
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
