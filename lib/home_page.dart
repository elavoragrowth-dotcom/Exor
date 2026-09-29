import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'data.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final h = now.hour;
    final part = (h >= 21 || h < 4) ? 3 : (h < 12 ? 0 : (h < 17 ? 1 : 2));
    const greet = ['Good morning,', 'Good afternoon,', 'Good evening,', 'Still up,'];
    const lines = [
      'A clean page. Fill it gently.',
      'Halfway through. Keep the thread.',
      'Softly now. Finish what matters.',
      'The quiet hours. Rest is part of the plan.',
    ];
    final nowMinutes = now.hour * 60 + now.minute;
    final blocksToday = store.blocksOn(now);
    final current = blocksToday.where((b) => nowMinutes >= b.startMinutes && nowMinutes < b.startMinutes + b.durationMinutes).toList();
    final upcoming = blocksToday.where((b) => b.startMinutes > nowMinutes).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final justDone = blocksToday.where((b) => b.startMinutes + b.durationMinutes <= nowMinutes).toList();

    final dueHabits = store.habits.where((hb) => store.isDue(hb, now) && !store.isDoneOn(hb, now)).toList();

    return ListView(
      padding: pagePad,
      children: [
        Reveal(child: Kicker(dateLabel(now))),
        const SizedBox(height: 14),
        Reveal(delayMs: 120, child: Text(greet[part], style: h1Light)),
        Reveal(delayMs: 240, child: Text('${store.settings.name}.', maxLines: 2, overflow: TextOverflow.ellipsis, style: h1Bold)),
        const SizedBox(height: 10),
        Reveal(delayMs: 380, child: Text(lines[part], style: subStyle)),
        const SizedBox(height: 28),
        Reveal(
          delayMs: 520,
          child: Glass(
            child: Row(
              children: [
                Ripple(color: store.settings.accent),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Kicker('RIGHT NOW'),
                      const SizedBox(height: 6),
                      if (current.isNotEmpty) ...[
                        Text(current.first.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: C.text)),
                        const SizedBox(height: 6),
                        Text(
                          '${fmtMinutes(current.first.startMinutes)} – ${fmtMinutes(current.first.startMinutes + current.first.durationMinutes)}',
                          style: const TextStyle(fontSize: 13, color: C.mute),
                        ),
                      ] else if (upcoming.isNotEmpty) ...[
                        Text('Free until ${fmtMinutes(upcoming.first.startMinutes)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.text)),
                        const SizedBox(height: 6),
                        Text('Next: ${upcoming.first.title}', style: const TextStyle(fontSize: 13, color: C.mute)),
                      ] else ...[
                        const Text('Nothing planned yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: C.text)),
                        const SizedBox(height: 6),
                        const Text('Open Planner to shape your day.', style: TextStyle(fontSize: 13, height: 1.45, color: C.mute)),
                      ],
                    ],
                  ),
                ),
                if (current.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      store.toggleBlock(current.first);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: store.settings.accent, shape: BoxShape.circle),
                      child: Icon(current.first.done ? Icons.check_rounded : Icons.play_arrow_rounded, color: C.base),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (justDone.isNotEmpty) ...[
          const SizedBox(height: 14),
          Reveal(
            delayMs: 600,
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: C.mute),
                const SizedBox(width: 8),
                Expanded(child: Text('Just finished: ${justDone.last.title}', style: const TextStyle(fontSize: 12.5, color: C.mute))),
              ],
            ),
          ),
        ],
        if (dueHabits.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Reveal(delayMs: 620, child: SectionLabel("TODAY'S HABITS")),
          Reveal(
            delayMs: 680,
            child: SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dueHabits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final hb = dueHabits[i];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      store.toggleHabit(hb, now);
                    },
                    child: Glass(
                      radius: 22,
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 78,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(hb.icon, color: hb.color, size: 26),
                            const SizedBox(height: 8),
                            Text(hb.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: C.text)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Reveal(
          delayMs: 760,
          child: Glass(
            child: Row(
              children: [
                const Icon(Icons.wb_twilight_rounded, color: C.lime, size: 28),
                const SizedBox(width: 16),
                const Expanded(child: Text('Your day begins', style: TextStyle(fontSize: 15, color: C.mute))),
                Text(fmtHour(store.settings.dayStartHour), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.text)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class Ripple extends StatefulWidget {
  const Ripple({super.key, this.color = C.lime});
  final Color color;
  @override
  State<Ripple> createState() => _RippleState();
}

class _RippleState extends State<Ripple> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 88,
        height: 88,
        child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _RipplePainter(_c.value, widget.color))),
      );
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    for (int i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final r = 8 + (maxR - 8) * Curves.easeOut.transform(p);
      canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = color.withValues(alpha: 0.55 * (1 - p)));
    }
    canvas.drawCircle(c, 14, Paint()..color = color.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(c, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t || old.color != color;
}
