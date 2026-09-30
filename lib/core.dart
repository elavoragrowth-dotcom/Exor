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

enum GlassStyle { frosted, clear }

class GlassConfig {
  static double blur = 24;
  static double auroraIntensity = 1.0;
  static GlassStyle style = GlassStyle.frosted;
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

String habitTypeLabel(String type) {
  switch (type) {
    case 'avoid':
      return 'Avoid';
    case 'amount':
      return 'Amount';
    default:
      return 'Normal';
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

/// FIX 2: a single continuous 1px border on every side (no mixed per-side
/// colours, which is what caused the border to look like it broke near the
/// corners). The "glassy" top sheen is now a separate 1px gradient line
/// drawn *inside* the border, not part of the border itself.
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
    final clear = GlassConfig.style == GlassStyle.clear;
    final blurAmt = clear ? (GlassConfig.blur * 0.4).clamp(4.0, 40.0) : GlassConfig.blur;
    final baseAlpha = clear ? tint * 0.4 : tint;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmt, sigmaY: blurAmt),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: br,
              color: Colors.white.withValues(alpha: 0.01 + baseAlpha * 0.25),
              border: Border.all(color: Colors.transparent, width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: clear ? 0.18 : 0.35), blurRadius: 26, offset: const Offset(0, 12)),
                if (glow) BoxShadow(color: accent.withValues(alpha: 0.10), blurRadius: 36),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                ),
                Positioned(
                  left: -1,
                  right: -1,
                  top: -1,
                  bottom: -1,
                  child: IgnorePointer(child: CustomPaint(painter: LiquidBorderPainter(radius))),
                ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Liquid-glass ring: a 1.4px stroke with a vertical gradient that is bright
/// at the top and bottom edges and fades to nothing through the middle.
class LiquidBorderPainter extends CustomPainter {
  const LiquidBorderPainter(this.radius);
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 1.4;
    final rect = Rect.fromLTWH(w / 2, w / 2, size.width - w, size.height - w);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular((radius - w / 2).clamp(0.0, double.infinity)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromRGBO(255, 255, 255, 0.5),
          Color.fromRGBO(255, 255, 255, 0.2),
          Color.fromRGBO(255, 255, 255, 0),
          Color.fromRGBO(255, 255, 255, 0),
          Color.fromRGBO(255, 255, 255, 0.2),
          Color.fromRGBO(255, 255, 255, 0.5),
        ],
        stops: [0, 0.2, 0.4, 0.6, 0.8, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(LiquidBorderPainter old) => old.radius != radius;
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
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

/// FIX 1 + FIX 3: one shared strip with a single sliding highlight.
/// Because there is only ever one highlight shape (a fixed 42x42 circle that
/// slides between positions with AnimatedPositioned), it's structurally
/// impossible for two pills to be lit at once, and impossible for the glow
/// to render as anything but a perfect circle.
class SlidingDayStrip extends StatelessWidget {
  const SlidingDayStrip({super.key, required this.days, required this.selectedIndex, this.onSelect, this.highlightColor});
  final List<DateTime> days;
  final int selectedIndex;
  final ValueChanged<int>? onSelect;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final color = highlightColor ?? Accent.color;
    return Glass(
      radius: 30,
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, cons) {
          final n = days.length;
          final cellWidth = cons.maxWidth / n;
          return SizedBox(
            height: 64,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: cellWidth * selectedIndex,
                  top: 0,
                  width: cellWidth,
                  height: 64,
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(n, (i) {
                    final d = days[i];
                    final on = i == selectedIndex;
                    return SizedBox(
                      width: cellWidth,
                      height: 64,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onSelect == null
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onSelect!(i);
                              },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(weekdayShort(d.weekday).substring(0, 1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: on ? color : C.mute)),
                            const SizedBox(height: 6),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: on ? C.base : C.text),
                              child: Text('${d.day}'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// FIX 4: one shared completion burst, used by habits, planner blocks, and
/// anything else that gets marked done. Reused instead of a per-screen copy.
class CompletionBurst extends StatefulWidget {
  const CompletionBurst({super.key, required this.center, required this.color, required this.onDone});
  final Offset center;
  final Color color;
  final VoidCallback onDone;
  @override
  State<CompletionBurst> createState() => _CompletionBurstState();
}

class _CompletionBurstState extends State<CompletionBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final List<double> _angles = List.generate(12, (i) => (i / 12) * 2 * math.pi + math.Random(i).nextDouble() * 0.3);

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = Curves.easeOut.transform(_c.value);
          return Stack(
            children: _angles.map((a) {
              final dist = 44 * t;
              final dx = widget.center.dx + math.cos(a) * dist;
              final dy = widget.center.dy + math.sin(a) * dist;
              final size = 6 * (1 - t) + 2;
              return Positioned(
                left: dx - size / 2,
                top: dy - size / 2,
                child: Opacity(
                  opacity: (1 - t).clamp(0, 1).toDouble(),
                  child: Container(width: size, height: size, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

void fireCompletionBurst(BuildContext context, GlobalKey anchorKey, Color color) {
  final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) return;
  final pos = box.localToGlobal(box.size.center(Offset.zero));
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => CompletionBurst(center: pos, color: color, onDone: () => entry.remove()));
  overlay.insert(entry);
}

/// FIX 6 (day-complete celebration): a short glass banner, not a full
/// takeover — stays out of the way of quickly finishing several items.
void showDayCompleteBanner(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: MediaQuery.of(ctx).padding.top + 12,
      left: 20,
      right: 20,
      child: _FadeInOut(
        child: Glass(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: C.lime, size: 22),
              const SizedBox(width: 12),
              const Expanded(child: Text('All habits done today ✦', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text))),
            ],
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2200), () => entry.remove());
}

class _FadeInOut extends StatefulWidget {
  const _FadeInOut({required this.child});
  final Widget child;
  @override
  State<_FadeInOut> createState() => _FadeInOutState();
}

class _FadeInOutState extends State<_FadeInOut> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _c,
        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic)), child: widget.child),
      );
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
            child: Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161C).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.transparent),
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
                Positioned.fill(
                  child: IgnorePointer(child: CustomPaint(painter: const LiquidBorderPainter(32))),
                ),
              ],
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
