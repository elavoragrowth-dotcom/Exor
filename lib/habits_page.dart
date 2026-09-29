import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'data.dart';

Route _route(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, a, __) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key, required this.store});
  final AppStore store;
  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final now = DateTime.now();
    final total = store.habits.where((h) => store.isDue(h, now)).length;
    final done = store.habits.where((h) => store.isDue(h, now) && store.isDoneOn(h, now)).length;
    final cats = ['All', ...{for (final h in store.habits) h.category}];
    var list = store.habits;
    if (_filter != 'All') list = list.where((h) => h.category == _filter).toList();

    return Stack(
      children: [
        ListView(
          padding: pagePad,
          children: [
            Reveal(child: Kicker(dateLabel(now))),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: Reveal(delayMs: 120, child: Text('Small things,', style: h1Light))),
                Reveal(delayMs: 120, child: Text('$done/$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.lime))),
              ],
            ),
            const Reveal(delayMs: 240, child: Text('done daily.', style: h1Bold)),
            const SizedBox(height: 22),
            Reveal(
              delayMs: 360,
              child: Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Kicker('TODAY'),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0.0 : done / total,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation(C.lime),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _statMini('${store.habits.isEmpty ? 0 : store.habits.map(store.currentStreak).reduce(math.max)}', 'Best current', Icons.local_fire_department_rounded, C.orange),
                        _statMini('${store.habits.isEmpty ? 0 : store.habits.map(store.bestStreak).reduce(math.max)}', 'Best ever', Icons.emoji_events_rounded, C.lime),
                        _statMini(total == 0 ? '0%' : '${((done / total) * 100).round()}%', 'Consistency', Icons.track_changes_rounded, C.teal),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Reveal(
              delayMs: 460,
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _filter = cats[i]),
                    child: Chip2(cats[i], selected: _filter == cats[i]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              Reveal(
                delayMs: 540,
                child: Glass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No habits yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: C.text)),
                      const SizedBox(height: 6),
                      const Text('Add the first one below — small and daily beats big and rare.', style: TextStyle(fontSize: 13, height: 1.4, color: C.mute)),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(list.length, (i) {
                final h = list[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Reveal(
                    delayMs: 540 + i * 60,
                    child: HabitCard(
                      store: store,
                      habit: h,
                      onOpen: () => Navigator.of(context).push(_route(HabitDetailPage(store: store, habitId: h.id))),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 90),
          ],
        ),
        Positioned(
          right: 4,
          bottom: MediaQuery.of(context).padding.bottom + 96,
          child: GestureDetector(
            onTap: () async {
              await showGlassSheet(context, HabitEditor(store: store));
              if (mounted) setState(() {});
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: Accent.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Accent.color.withValues(alpha: 0.4), blurRadius: 20)]),
              child: const Icon(Icons.add_rounded, color: C.base, size: 30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statMini(String value, String label, IconData icon, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.text)),
              Text(label, style: const TextStyle(fontSize: 10.5, color: C.mute)),
            ],
          ),
        ),
      );
}

class HabitCard extends StatefulWidget {
  const HabitCard({super.key, required this.store, required this.habit, required this.onOpen});
  final AppStore store;
  final Habit habit;
  final VoidCallback onOpen;
  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  final GlobalKey _boxKey = GlobalKey();

  void _fireBurst() {
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(box.size.center(Offset.zero));
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => BurstEffect(center: pos, color: widget.habit.color, onDone: () => entry.remove()));
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final h = widget.habit;
    final now = DateTime.now();
    final done = store.isDoneOn(h, now);
    final streak = store.currentStreak(h);
    final week = List.generate(7, (i) => now.subtract(Duration(days: now.weekday - 1 - i)));

    return GestureDetector(
      onTap: widget.onOpen,
      child: Glass(
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: h.color.withValues(alpha: 0.18), shape: BoxShape.circle),
                  child: Icon(h.icon, color: h.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: C.text)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.local_fire_department_rounded, size: 14, color: C.orange),
                        const SizedBox(width: 3),
                        Text('$streak', style: const TextStyle(fontSize: 12, color: C.mute)),
                        const SizedBox(width: 8),
                        Chip2(h.category, color: categoryColor(h.category)),
                      ]),
                    ],
                  ),
                ),
                GestureDetector(
                  key: _boxKey,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (!done) _fireBurst();
                    store.toggleHabit(h, now);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? h.color : Colors.transparent,
                      border: Border.all(color: done ? h.color : Colors.white.withValues(alpha: 0.3), width: 1.6),
                    ),
                    child: done ? const Icon(Icons.check_rounded, color: C.base, size: 20) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: week.map((d) {
                final due = store.isDue(h, d);
                final dn = store.isDoneOn(h, d);
                final today = dayKey(d) == dayKey(now);
                return Expanded(
                  child: Column(
                    children: [
                      Text(weekdayShort(d.weekday).substring(0, 1), style: TextStyle(fontSize: 10, color: today ? C.lime : C.mute)),
                      const SizedBox(height: 5),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !due ? Colors.white.withValues(alpha: 0.08) : (dn ? h.color : Colors.white.withValues(alpha: 0.18)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class BurstEffect extends StatefulWidget {
  const BurstEffect({super.key, required this.center, required this.color, required this.onDone});
  final Offset center;
  final Color color;
  final VoidCallback onDone;
  @override
  State<BurstEffect> createState() => _BurstEffectState();
}

class _BurstEffectState extends State<BurstEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
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
              final dist = 46 * t;
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

class HabitDetailPage extends StatefulWidget {
  const HabitDetailPage({super.key, required this.store, required this.habitId});
  final AppStore store;
  final String habitId;
  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  String _range = 'Week';
  Timer? _ticker;
  int _elapsed = 0;
  bool _running = false;

  Habit get h => widget.store.habits.firstWhere((e) => e.id == widget.habitId);

  void _startPause() {
    HapticFeedback.mediumImpact();
    setState(() => _running = !_running);
    if (_running) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed++);
      });
    } else {
      _ticker?.cancel();
    }
  }

  void _save() {
    if (_elapsed > 0) {
      widget.store.addFocusSeconds(h, DateTime.now(), _elapsed);
    }
    _ticker?.cancel();
    setState(() {
      _running = false;
      _elapsed = 0;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmtElapsed(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final now = DateTime.now();
    final logsForHabit = store.logs.where((l) => l.habitId == h.id).toList();
    final lastDone = logsForHabit.where((l) => l.done).toList()..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: C.text)),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        await showGlassSheet(context, HabitEditor(store: store, existing: h));
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.edit_rounded, color: C.text),
                    ),
                    IconButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1A22),
                            title: const Text('Delete this habit?', style: TextStyle(color: C.text)),
                            content: const Text('This removes its history too.', style: TextStyle(color: C.mute)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: C.coral))),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await store.deleteHabit(h.id);
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: C.mute),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: h.color.withValues(alpha: 0.18), shape: BoxShape.circle),
                      child: Icon(h.icon, color: h.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(h.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: C.text))),
                  ],
                ),
                const SizedBox(height: 12),
                Chip2(_repeatLabel(h), color: h.color),
                const SizedBox(height: 20),
                Glass(
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: C.mute, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Kicker('FOCUS TIME'),
                            const SizedBox(height: 4),
                            Text(_fmtElapsed(_elapsed), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.text)),
                          ],
                        ),
                      ),
                      if (_elapsed > 0 && !_running)
                        IconButton(onPressed: _save, icon: const Icon(Icons.check_circle_rounded, color: C.lime, size: 30)),
                      GestureDetector(
                        onTap: _startPause,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: C.base),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionLabel('STREAKS'),
                Row(
                  children: [
                    _streakTile('${store.currentStreak(h)}', 'days', 'Current', Icons.local_fire_department_rounded, C.orange),
                    const SizedBox(width: 10),
                    _streakTile('${store.bestStreak(h)}', 'days', 'Best', Icons.emoji_events_rounded, C.lime),
                    const SizedBox(width: 10),
                    _streakTile('${store.totalCompletions(h)}', '', 'Total', Icons.check_circle_rounded, C.teal),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionLabel('ACTIVITY'),
                Row(
                  children: ['Week', 'Month', 'Year'].map((r) {
                    final on = r == _range;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(onTap: () => setState(() => _range = r), child: Chip2(r, selected: on)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                _activityView(store, h, now),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    _LegendDot(color: Color(0xFF4C8DF6), label: 'Note added'),
                    SizedBox(width: 14),
                    _LegendDot(color: C.orange, label: 'Planned'),
                    SizedBox(width: 14),
                    _LegendDot(color: C.lime, label: 'Completed'),
                  ],
                ),
                const SizedBox(height: 20),
                Glass(
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, color: C.lime, size: 24),
                      const SizedBox(width: 14),
                      const Expanded(child: Text('Last check', style: TextStyle(fontSize: 15, color: C.mute))),
                      Text(lastDone.isEmpty ? 'Never' : lastDone.first.date, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _repeatLabel(Habit h) {
    switch (h.repeatType) {
      case 'weekdays':
        return h.weekdays.map(weekdayShort).join(' · ');
      case 'timesPerWeek':
        return '${h.timesPerWeek}× per week';
      default:
        return 'Daily';
    }
  }

  Widget _streakTile(String value, String suffix, String label, IconData icon, Color color) => Expanded(
        child: Glass(
          radius: 20,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text('$value${suffix.isNotEmpty ? ' $suffix' : ''}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.text)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: C.mute)),
            ],
          ),
        ),
      );

  Widget _activityView(AppStore store, Habit h, DateTime now) {
    if (_range == 'Week') {
      final start = now.subtract(Duration(days: now.weekday - 1));
      final days = List.generate(7, (i) => start.add(Duration(days: i)));
      return Row(
        children: days.map((d) {
          final dn = store.isDoneOn(h, d);
          final due = store.isDue(h, d);
          final today = dayKey(d) == dayKey(now);
          return Expanded(
            child: Column(
              children: [
                Text('${d.day}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: today ? C.lime : C.text)),
                Text(weekdayShort(d.weekday), style: const TextStyle(fontSize: 9, color: C.mute)),
                const SizedBox(height: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !due ? Colors.white.withValues(alpha: 0.05) : (dn ? h.color : Colors.white.withValues(alpha: 0.10)),
                    border: today ? Border.all(color: C.lime, width: 1.4) : null,
                  ),
                  child: dn ? const Icon(Icons.check_rounded, size: 16, color: C.base) : null,
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else if (_range == 'Month') {
      final start = DateTime(now.year, now.month, 1);
      final days = List.generate(DateTime(now.year, now.month + 1, 0).day, (i) => start.add(Duration(days: i)));
      return Wrap(
        spacing: 7,
        runSpacing: 7,
        children: days.map((d) {
          final dn = store.isDoneOn(h, d);
          final due = store.isDue(h, d);
          return Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: !due ? Colors.white.withValues(alpha: 0.05) : (dn ? h.color : Colors.white.withValues(alpha: 0.10)),
            ),
          );
        }).toList(),
      );
    } else {
      final start = DateTime(now.year, 1, 1);
      final days = List.generate(DateTime(now.year, 12, 31).difference(start).inDays + 1, (i) => start.add(Duration(days: i)));
      return Wrap(
        spacing: 3,
        runSpacing: 3,
        children: days.map((d) {
          final dn = store.isDoneOn(h, d);
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: dn ? h.color : Colors.white.withValues(alpha: 0.08)),
          );
        }).toList(),
      );
    }
  }
}
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10.5, color: C.mute)),
        ],
      );
}

class HabitEditor extends StatefulWidget {
  const HabitEditor({super.key, required this.store, this.existing});
  final AppStore store;
  final Habit? existing;
  @override
  State<HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<HabitEditor> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late int _icon = widget.existing?.iconIndex ?? 0;
  late Color _color = widget.existing?.color ?? C.teal;
  late String _repeat = widget.existing?.repeatType ?? 'daily';
  late List<int> _weekdays = List.of(widget.existing?.weekdays ?? [1, 2, 3, 4, 5]);
  late int _timesPerWeek = widget.existing?.timesPerWeek ?? 3;
  late String _category = widget.existing?.category ?? 'Study';
  late bool _hasTime = widget.existing?.plannedMinutes != null;
  late int _plannedMinutes = widget.existing?.plannedMinutes ?? 8 * 60;

  static const _colors = [C.teal, C.violet, C.orange, C.lime, C.coral];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() async {
    if (_name.text.trim().isEmpty) return;
    if (widget.existing != null) {
      final h = widget.existing!;
      h.name = _name.text.trim();
      h.iconIndex = _icon;
      h.colorValue = _color.value;
      h.repeatType = _repeat;
      h.weekdays = _weekdays;
      h.timesPerWeek = _timesPerWeek;
      h.category = _category;
      h.plannedMinutes = _hasTime ? _plannedMinutes : null;
      await widget.store.updateHabit(h);
    } else {
      final h = Habit(
        id: newId(),
        name: _name.text.trim(),
        iconIndex: _icon,
        colorValue: _color.value,
        repeatType: _repeat,
        weekdays: _weekdays,
        timesPerWeek: _timesPerWeek,
        category: _category,
        plannedMinutes: _hasTime ? _plannedMinutes : null,
        createdAt: DateTime.now(),
      );
      await widget.store.addHabit(h);
    }
    if (mounted) Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.existing == null ? 'New habit' : 'Edit habit', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.text)),
        const SizedBox(height: 18),
        TextField(
          controller: _name,
          style: const TextStyle(color: C.text, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Habit name',
            hintStyle: const TextStyle(color: C.mute),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('ICON'),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: habitIcons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final on = i == _icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = i),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? _color.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                    border: on ? Border.all(color: _color, width: 1.6) : null,
                  ),
                  child: Icon(habitIcons[i], color: on ? _color : C.mute, size: 20),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('COLOUR'),
        Row(
          children: _colors.map((c) {
            final on = c.value == _color.value;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: on ? Border.all(color: Colors.white, width: 2.4) : null),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const SectionLabel('CATEGORY'),
        Wrap(
          spacing: 8,
          children: categories.map((c) => GestureDetector(onTap: () => setState(() => _category = c), child: Chip2(c, selected: c == _category, color: categoryColor(c)))).toList(),
        ),
        const SizedBox(height: 16),
        const SectionLabel('REPEAT'),
        Wrap(
          spacing: 8,
          children: [
            GestureDetector(onTap: () => setState(() => _repeat = 'daily'), child: Chip2('Daily', selected: _repeat == 'daily')),
            GestureDetector(onTap: () => setState(() => _repeat = 'weekdays'), child: Chip2('Choose days', selected: _repeat == 'weekdays')),
            GestureDetector(onTap: () => setState(() => _repeat = 'timesPerWeek'), child: Chip2('N per week', selected: _repeat == 'timesPerWeek')),
          ],
        ),
        if (_repeat == 'weekdays') ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final d = i + 1;
              final on = _weekdays.contains(d);
              return GestureDetector(
                onTap: () => setState(() => on ? _weekdays.remove(d) : _weekdays.add(d)),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: on ? _color : Colors.white.withValues(alpha: 0.08),
                  child: Text(weekdayShort(d).substring(0, 1), style: TextStyle(color: on ? C.base : C.mute, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              );
            }),
          ),
        ],
        if (_repeat == 'timesPerWeek') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _timesPerWeek = (_timesPerWeek - 1).clamp(1, 7).toInt()), icon: const Icon(Icons.remove_circle_outline, color: C.mute)),
              Text('$_timesPerWeek× a week', style: const TextStyle(color: C.text, fontSize: 15)),
              IconButton(onPressed: () => setState(() => _timesPerWeek = (_timesPerWeek + 1).clamp(1, 7).toInt()), icon: const Icon(Icons.add_circle_outline, color: C.mute)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Text('Planned time', style: TextStyle(color: C.text, fontSize: 14.5))),
            Switch(value: _hasTime, activeColor: _color, onChanged: (v) => setState(() => _hasTime = v)),
          ],
        ),
        if (_hasTime)
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _plannedMinutes ~/ 60, minute: _plannedMinutes % 60));
              if (picked != null) setState(() => _plannedMinutes = picked.hour * 60 + picked.minute);
            },
            child: Glass(radius: 18, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text(fmtMinutes(_plannedMinutes), style: const TextStyle(color: C.text, fontSize: 15))),
          ),
        const SizedBox(height: 24),
        PillButton(label: widget.existing == null ? 'Create habit' : 'Save changes', onTap: _save, color: _color),
        const SizedBox(height: 6),
      ],
    );
  }
}
      
