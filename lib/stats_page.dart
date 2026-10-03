import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'data.dart';
import 'stats_data.dart';

const Color _kMute = Color(0xADF2F2F0);
const List<FontFeature> _kTab = [FontFeature.tabularFigures()];

/// Flat surface used across the Stats page (no blur, no glow: it is a data page).
BoxDecoration _surface({double radius = 24}) => BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    );

class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.store, required this.onOpenHabits});
  final AppStore store;
  final VoidCallback onOpenHabits;
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _period = 0; // 0 week, 1 month, 2 year
  static const _days = [7, 30, 365];
  static const _names = ['Week', 'Month', 'Year'];
  Timer? _tick;
  int _checkedVersion = -1;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _haptic() {
    if (widget.store.settings.hapticsEnabled) HapticFeedback.selectionClick();
  }

  void _checkAchievements(StatsSnapshot snap) {
    final store = widget.store;
    if (_checkedVersion == store.version) return;
    _checkedVersion = store.version;
    final earned = [for (final a in kAchievements) if (a.earnedIn(snap)) a.id];
    store.unlockEarned(earned);
    final unseen = store.achievements.keys.where((id) => !store.achievementsSeen.contains(id)).toList();
    if (unseen.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final id in unseen) {
        store.markAchievementSeen(id);
      }
      final defs = [for (final id in unseen) kAchievements.where((a) => a.id == id)].expand((e) => e).toList();
      if (defs.isEmpty) return;
      if (store.settings.hapticsEnabled) HapticFeedback.mediumImpact();
      showGlassSheet(context, _UnlockSheet(defs: defs, snap: snap));
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final empty = store.habits.isEmpty && store.blocks.isEmpty;
    return SafeArea(
      child: empty ? _empty() : _content(),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.insights_rounded, size: 44, color: Accent.color),
            const SizedBox(height: 18),
            const Text('Nothing to measure yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.text)),
            const SizedBox(height: 8),
            const Text('Add a habit and finish it once. Your streak starts there.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: _kMute)),
            const SizedBox(height: 22),
            PillButton(label: 'Add a habit', onTap: widget.onOpenHabits),
          ]),
        ),
      );

  Widget _content() {
    final store = widget.store;
    final snap = StatsEngine.of(store);
    _checkAchievements(snap);
    final n = _days[_period];
    final cur = snap.period(snap.today, n);
    final prev = snap.period(DateTime(snap.today.year, snap.today.month, snap.today.day - n), n);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Reveal(child: _header()),
        const SizedBox(height: 18),
        Reveal(delayMs: 60, child: _StreakHero(snap: snap, haptics: store.settings.hapticsEnabled)),
        const SizedBox(height: 16),
        Reveal(delayMs: 120, child: _StatStrip(cur: cur, prev: prev, snap: snap, label: _names[_period].toLowerCase())),
        const SizedBox(height: 22),
        Reveal(delayMs: 180, child: _Heatmap(snap: snap, store: store)),
        const SizedBox(height: 22),
        Reveal(delayMs: 240, child: _Shelf(snap: snap, store: store)),
      ],
    );
  }

  Widget _header() {
    return Row(children: [
      const Expanded(child: Text('Stats', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: C.text, letterSpacing: -0.5))),
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(22)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (int i = 0; i < 3; i++)
            Semantics(
              button: true,
              selected: _period == i,
              label: _names[i],
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_period != i) {
                    _haptic();
                    setState(() => _period = i);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minWidth: 52, minHeight: 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _period == i ? Accent.color.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(_names[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _period == i ? Accent.color : _kMute)),
                ),
              ),
            ),
        ]),
      ),
    ]);
  }
}

// ───────────────────────── press feedback ─────────────────────────

class _Press extends StatefulWidget {
  const _Press({required this.child, required this.onTap, this.label});
  final Widget child;
  final VoidCallback onTap;
  final String? label;
  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: _down ? 0.96 : 1, duration: const Duration(milliseconds: 110), curve: Curves.easeOut, child: widget.child),
      ),
    );
  }
}

// ───────────────────────── streak hero ─────────────────────────

class _StreakHero extends StatefulWidget {
  const _StreakHero({required this.snap, required this.haptics});
  final StatsSnapshot snap;
  final bool haptics;
  @override
  State<_StreakHero> createState() => _StreakHeroState();
}

class _StreakHeroState extends State<_StreakHero> with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  bool _started = false;

  bool get _todayDone => widget.snap.statOn(widget.snap.today).kind == DayKind.done;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (MediaQuery.of(context).disableAnimations) {
        _entry.value = 1;
      } else {
        _entry.forward();
      }
    }
  }

  @override
  void didUpdateWidget(covariant _StreakHero old) {
    super.didUpdateWidget(old);
    final was = old.snap.statOn(old.snap.today).kind == DayKind.done;
    if (!was && _todayDone) {
      if (widget.haptics) HapticFeedback.mediumImpact();
      if (!MediaQuery.of(context).disableAnimations) _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _pop.dispose();
    super.dispose();
  }

  int _nextMilestone(int streak) {
    for (final m in kStreakMilestones) {
      if (m > streak) return m;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snap;
    final now = DateTime.now();
    final streak = s.currentStreak;
    final monday = DateTime(s.today.year, s.today.month, s.today.day - (s.today.weekday - 1));
    final week = [for (int i = 0; i < 7; i++) s.statOn(DateTime(monday.year, monday.month, monday.day + i)).kind];
    final todayIdx = s.today.weekday - 1;
    final atRisk = streak > 0 && s.todayPending && now.hour >= kEveningCutoffHour;
    final tone = atRisk ? C.orange : Accent.color;

    String line;
    if (atRisk) {
      final left = DateTime(now.year, now.month, now.day + 1).difference(now);
      final h = left.inHours;
      final m = left.inMinutes % 60;
      line = '${h}h ${m}m left to keep $streak.';
    } else if (streak == 0 && s.bestStreak > 0) {
      line = 'Best ${s.bestStreak}. Start again today.';
    } else if (streak == 0) {
      line = 'Finish a habit to start your streak.';
    } else if (s.todayPending) {
      line = 'Finish one habit today to make it ${streak + 1}.';
    } else {
      line = 'Locked in for today.';
    }
    final next = _nextMilestone(streak);
    final nextLine = next == 0 ? 'Every milestone reached.' : '${next - streak} ${next - streak == 1 ? 'day' : 'days'} to the $next-day badge.';
    final milestone = kStreakMilestones.contains(streak);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: _surface(radius: 28),
      child: Semantics(
        label: 'Current streak $streak days. $line',
        child: Column(children: [
          SizedBox(
            width: 224,
            height: 224,
            child: Stack(alignment: Alignment.center, children: [
              AnimatedBuilder(
                animation: Listenable.merge([_entry, _pop]),
                builder: (_, __) => CustomPaint(
                  size: const Size(224, 224),
                  painter: _RingPainter(kinds: week, todayIdx: todayIdx, tone: tone, entry: _entry.value, pop: _pop.value, milestone: milestone),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: streak),
                  duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text('$v', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700, color: C.text, height: 1.0, fontFeatures: _kTab, letterSpacing: -1)),
                ),
                const SizedBox(height: 4),
                const Text('day streak', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kMute)),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (int i = 0; i < 7; i++)
              SizedBox(
                width: 28,
                child: Text(
                  const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: i == todayIdx ? FontWeight.w700 : FontWeight.w500, color: i == todayIdx ? C.text : _kMute),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          Text(line, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: atRisk ? C.orange : C.text, fontFeatures: _kTab)),
          const SizedBox(height: 4),
          Text(nextLine, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _kMute)),
        ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.kinds, required this.todayIdx, required this.tone, required this.entry, required this.pop, required this.milestone});
  final List<DayKind> kinds;
  final int todayIdx;
  final Color tone;
  final double entry, pop;
  final bool milestone;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const stroke = 16.0;
    final r = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: c, radius: r);
    const seg = 2 * math.pi / 7;
    const gap = 0.16;
    for (int i = 0; i < 7; i++) {
      final start = -math.pi / 2 + i * seg + gap / 2;
      final sweep = seg - gap;
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.09);
      canvas.drawArc(rect, start, sweep, false, track);

      final kind = kinds[i];
      final p = (((entry * 1100) - i * 40) / 500).clamp(0.0, 1.0).toDouble();
      final eased = Curves.easeOutCubic.transform(p);
      final isToday = i == todayIdx;
      double w = stroke;
      if (isToday && pop > 0 && pop < 1) w += math.sin(pop * math.pi) * 5;
      if (kind == DayKind.done) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w
          ..color = tone;
        canvas.drawArc(rect, start, sweep * eased, false, paint);
      } else if (isToday && kind == DayKind.pending) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3
          ..color = tone.withValues(alpha: 0.55 * eased);
        canvas.drawArc(rect, start, sweep, false, paint);
      }
    }
    if (milestone) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = tone.withValues(alpha: 0.4 * entry);
      canvas.drawCircle(c, r + stroke / 2 + 4 + 4 * entry, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) =>
      o.entry != entry || o.pop != pop || o.tone != tone || o.todayIdx != todayIdx || o.milestone != milestone || !_same(o.kinds, kinds);

  bool _same(List<DayKind> a, List<DayKind> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ───────────────────────── stat strip ─────────────────────────

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.cur, required this.prev, required this.snap, required this.label});
  final PeriodStats cur, prev;
  final StatsSnapshot snap;
  final String label;

  String _focus(int secs) {
    final m = secs ~/ 60;
    return m == 0 ? '0m' : fmtDurationShort(m);
  }

  Widget _delta(String? text, bool up) {
    if (text == null) return const SizedBox(height: 16);
    return SizedBox(
      height: 16,
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: up ? Accent.color : _kMute, fontFeatures: _kTab)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = (cur.rate * 100).round();
    String? dPct;
    bool upPct = true;
    if (cur.hasData && prev.hasData) {
      final d = pct - (prev.rate * 100).round();
      upPct = d >= 0;
      dPct = d == 0 ? '±0' : (d > 0 ? '+$d' : '$d');
    }
    String? dFocus;
    bool upFocus = true;
    if (prev.focusSeconds > 0) {
      final d = ((cur.focusSeconds - prev.focusSeconds) / 60).round();
      upFocus = d >= 0;
      dFocus = d == 0 ? '±0' : (d > 0 ? '+${fmtDurationShort(d)}' : '-${fmtDurationShort(-d)}');
    }

    Widget cell(String value, String name, Widget delta) => Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: 30,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: C.text, fontFeatures: _kTab)),
              ),
            ),
            const SizedBox(height: 2),
            Text(name, style: const TextStyle(fontSize: 11, color: _kMute)),
            const SizedBox(height: 4),
            delta,
          ]),
        );
    Widget divider() => Container(width: 1, height: 52, color: Colors.white.withValues(alpha: 0.08));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
      decoration: _surface(),
      child: Semantics(
        label: 'Last $label. Completion $pct percent, focus ${_focus(cur.focusSeconds)}, best streak ${snap.bestStreak}, perfect days ${cur.perfectDays}.',
        child: Row(children: [
          cell(cur.hasData ? '$pct%' : '–', 'Done', _delta(dPct, upPct)),
          divider(),
          cell(_focus(cur.focusSeconds), 'Focus', _delta(dFocus, upFocus)),
          divider(),
          cell('${snap.bestStreak}', 'Best streak', _delta(null, true)),
          divider(),
          cell('${cur.perfectDays}', 'Perfect', _delta(null, true)),
        ]),
      ),
    );
  }
}

// ───────────────────────── heatmap ─────────────────────────

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.snap, required this.store});
  final StatsSnapshot snap;
  final AppStore store;

  static const weeks = 13;
  static const gap = 4.0;
  static const leftLabel = 18.0;
  static const topLabel = 16.0;

  DateTime get _gridStart {
    final monday = DateTime(snap.today.year, snap.today.month, snap.today.day - (snap.today.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day - 7 * (weeks - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _surface(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Last 13 weeks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, cons) {
          final cell = ((cons.maxWidth - leftLabel - gap * (weeks - 1)) / weeks).floorToDouble();
          final h = topLabel + cell * 7 + gap * 6;
          final start = _gridStart;
          return Semantics(
            label: 'Activity heatmap for the last 13 weeks. Tap a day for details.',
            child: GestureDetector(
              onTapUp: (d) {
                final x = d.localPosition.dx - leftLabel;
                final y = d.localPosition.dy - topLabel;
                if (x < 0 || y < 0) return;
                final col = (x / (cell + gap)).floor();
                final row = (y / (cell + gap)).floor();
                if (col < 0 || col >= weeks || row < 0 || row > 6) return;
                final date = DateTime(start.year, start.month, start.day + col * 7 + row);
                if (date.isAfter(snap.today)) return;
                if (store.settings.hapticsEnabled) HapticFeedback.selectionClick();
                showGlassSheet(context, _DaySheet(date: date, snap: snap, store: store));
              },
              child: SizedBox(
                width: cons.maxWidth,
                height: h,
                child: CustomPaint(painter: _HeatPainter(snap: snap, start: start, cell: cell, accent: Accent.color)),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text('Less', style: TextStyle(fontSize: 11, color: _kMute)),
          const SizedBox(width: 6),
          for (final a in const [0.0, 0.3, 0.5, 0.75, 1.0])
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: a == 0 ? Colors.white.withValues(alpha: 0.07) : Accent.color.withValues(alpha: a),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          const SizedBox(width: 3),
          const Text('More', style: TextStyle(fontSize: 11, color: _kMute)),
        ]),
      ]),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter({required this.snap, required this.start, required this.cell, required this.accent});
  final StatsSnapshot snap;
  final DateTime start;
  final double cell;
  final Color accent;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  void _text(Canvas canvas, String t, Offset o) {
    final tp = TextPainter(text: TextSpan(text: t, style: const TextStyle(fontSize: 10, color: _kMute)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = _Heatmap.leftLabel;
    const top = _Heatmap.topLabel;
    const gap = _Heatmap.gap;
    int lastMonth = -1;
    for (int w = 0; w < _Heatmap.weeks; w++) {
      final weekStart = DateTime(start.year, start.month, start.day + w * 7);
      if (weekStart.month != lastMonth) {
        lastMonth = weekStart.month;
        _text(canvas, _months[weekStart.month - 1], Offset(left + w * (cell + gap), 0));
      }
      for (int d = 0; d < 7; d++) {
        final date = DateTime(start.year, start.month, start.day + w * 7 + d);
        if (date.isAfter(snap.today)) continue;
        final st = snap.statOn(date);
        double a = 0;
        if (st.kind == DayKind.done) {
          if (st.due > 0 && st.ratio >= 1) {
            a = 1.0;
          } else if (st.due > 0 && st.ratio >= 0.75) {
            a = 0.75;
          } else if (st.due > 0 && st.ratio >= 0.5) {
            a = 0.5;
          } else {
            a = 0.3;
          }
        }
        final rect = Rect.fromLTWH(left + w * (cell + gap), top + d * (cell + gap), cell, cell);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(4));
        canvas.drawRRect(rr, Paint()..color = a == 0 ? Colors.white.withValues(alpha: 0.07) : accent.withValues(alpha: a));
        if (date == snap.today) {
          canvas.drawRRect(rr.deflate(0.75), Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = C.text);
        }
      }
    }
    _text(canvas, 'M', const Offset(0, top + 1));
    _text(canvas, 'W', Offset(0, top + 2 * (cell + gap) + 1));
    _text(canvas, 'F', Offset(0, top + 4 * (cell + gap) + 1));
  }

  @override
  bool shouldRepaint(covariant _HeatPainter o) => o.snap != snap || o.accent != accent || o.cell != cell;
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.date, required this.snap, required this.store});
  final DateTime date;
  final StatsSnapshot snap;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final st = snap.statOn(date);
    final key = dayKey(date);
    final rows = <Widget>[];
    for (final h in store.habits) {
      if (h.type == 'avoid') continue;
      if (date.isBefore(dateOnly(h.createdAt))) continue;
      HabitLog? log;
      for (final l in store.logs) {
        if (l.habitId == h.id && l.date == key) {
          log = l;
          break;
        }
      }
      final ok = log != null && (h.type == 'amount' ? log.amount >= h.amountGoal : log.done);
      if (!ok && !(h.repeatType != 'timesPerWeek' && store.isDue(h, date))) continue;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 20, color: ok ? Accent.color : _kMute),
          const SizedBox(width: 12),
          Expanded(child: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, color: ok ? C.text : _kMute))),
        ]),
      ));
    }
    final parts = <String>[
      if (st.due > 0) '${st.done} of ${st.due} done',
      if (st.focusSeconds >= 60) '${fmtDurationShort(st.focusSeconds ~/ 60)} focus',
      if (st.blocksDone > 0) '${st.blocksDone} planner ${st.blocksDone == 1 ? 'block' : 'blocks'}',
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(dateLabel(date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMute, letterSpacing: 0.6)),
      const SizedBox(height: 6),
      Text(parts.isEmpty ? 'Rest day' : parts.join('  ·  '), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.text, fontFeatures: _kTab)),
      const SizedBox(height: 14),
      if (rows.isEmpty) const Text('Nothing was due.', style: TextStyle(fontSize: 14, color: _kMute)) else ...rows,
    ]);
  }
}

// ───────────────────────── achievements ─────────────────────────

IconData _achIcon(AchievementDef a) {
  if (a.id == 'perfect_week') return Icons.star_rounded;
  if (a.id == 'comeback') return Icons.replay_rounded;
  switch (a.kind) {
    case AchKind.streak:
      return Icons.local_fire_department_rounded;
    case AchKind.volume:
      return Icons.check_rounded;
    case AchKind.focus:
      return Icons.timer_rounded;
    case AchKind.behavior:
      return Icons.star_rounded;
  }
}

String _achProgress(AchievementDef a, StatsSnapshot s) {
  final v = a.valueIn(s);
  if (a.kind == AchKind.focus) return '${v.floor()}/${a.target}h';
  return '${math.min(v.floor(), a.target)}/${a.target}';
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.snap, required this.store});
  final StatsSnapshot snap;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final defs = [...kAchievements];
    defs.sort((a, b) {
      final ea = a.earnedIn(snap) ? 1 : 0;
      final eb = b.earnedIn(snap) ? 1 : 0;
      if (ea != eb) return eb - ea;
      return b.fractionIn(snap).compareTo(a.fractionIn(snap));
    });
    final got = defs.where((d) => d.earnedIn(snap)).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Achievements', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.text))),
        Text('$got of ${defs.length}', style: const TextStyle(fontSize: 13, color: _kMute, fontFeatures: _kTab)),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        height: 128,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: defs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final a = defs[i];
            final earned = a.earnedIn(snap);
            return _Press(
              label: '${a.title}, ${earned ? 'unlocked' : _achProgress(a, snap)}',
              onTap: () {
                if (store.settings.hapticsEnabled) HapticFeedback.selectionClick();
                showGlassSheet(context, _AchDetail(def: a, snap: snap, unlockedOn: store.achievements[a.id]));
              },
              child: Container(
                width: 96,
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                decoration: _surface(radius: 22),
                child: Column(children: [
                  _Badge(def: a, snap: snap, size: 58, animate: false),
                  const SizedBox(height: 8),
                  Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: earned ? C.text : _kMute)),
                  const SizedBox(height: 2),
                  Text(earned ? 'Unlocked' : _achProgress(a, snap), style: TextStyle(fontSize: 11, color: earned ? Accent.color : _kMute, fontFeatures: _kTab)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.def, required this.snap, required this.size, required this.animate});
  final AchievementDef def;
  final StatsSnapshot snap;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final earned = def.earnedIn(snap);
    final target = earned ? 1.0 : def.fractionIn(snap);
    final reduce = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: animate && !reduce ? 0 : target, end: target),
      duration: animate && !reduce ? const Duration(milliseconds: 900) : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BadgePainter(progress: v, earned: earned, accent: Accent.color),
          child: Center(child: Icon(_achIcon(def), size: size * 0.42, color: earned ? Accent.color : Colors.white.withValues(alpha: 0.35))),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  _BadgePainter({required this.progress, required this.earned, required this.accent});
  final double progress;
  final bool earned;
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 3;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withValues(alpha: 0.1);
    canvas.drawCircle(c, r, track);
    if (progress > 0) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..color = earned ? accent : accent.withValues(alpha: 0.55);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * progress, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _BadgePainter o) => o.progress != progress || o.earned != earned || o.accent != accent;
}

class _AchDetail extends StatelessWidget {
  const _AchDetail({required this.def, required this.snap, required this.unlockedOn});
  final AchievementDef def;
  final StatsSnapshot snap;
  final String? unlockedOn;
  @override
  Widget build(BuildContext context) {
    final earned = def.earnedIn(snap);
    return Column(children: [
      const SizedBox(height: 6),
      _Badge(def: def, snap: snap, size: 96, animate: true),
      const SizedBox(height: 16),
      Text(def.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.text)),
      const SizedBox(height: 6),
      Text(def.blurb, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.4, color: _kMute)),
      const SizedBox(height: 14),
      Text(
        earned ? (unlockedOn == null ? 'Unlocked' : 'Unlocked $unlockedOn') : _achProgress(def, snap),
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: earned ? Accent.color : C.text, fontFeatures: _kTab),
      ),
      const SizedBox(height: 8),
    ]);
  }
}

class _UnlockSheet extends StatelessWidget {
  const _UnlockSheet({required this.defs, required this.snap});
  final List<AchievementDef> defs;
  final StatsSnapshot snap;
  @override
  Widget build(BuildContext context) {
    final first = defs.first;
    return Column(children: [
      const SizedBox(height: 6),
      Text(defs.length > 1 ? 'NEW BADGES' : 'NEW BADGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Accent.color, letterSpacing: 1.2)),
      const SizedBox(height: 16),
      _Badge(def: first, snap: snap, size: 104, animate: true),
      const SizedBox(height: 16),
      Text(first.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: C.text)),
      const SizedBox(height: 6),
      Text(first.blurb, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.4, color: _kMute)),
      if (defs.length > 1) ...[
        const SizedBox(height: 10),
        Text('+${defs.length - 1} more on your shelf', style: const TextStyle(fontSize: 13, color: _kMute)),
      ],
      const SizedBox(height: 20),
      PillButton(label: 'Nice', onTap: () => Navigator.of(context).pop()),
      const SizedBox(height: 4),
    ]);
  }
}
