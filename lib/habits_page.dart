import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'core.dart';
import 'data.dart';
import 'habit_widgets.dart';
import 'notifications.dart';

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

/// The habit's own cover image, or null if it has none (or the file is gone).
File? coverFileOf(Habit h) {
  final p = h.coverImagePath;
  if (p == null || p.isEmpty) return null;
  final f = File(p);
  return f.existsSync() ? f : null;
}

Widget _coverImage(File f, {double? height}) => SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(f, fit: BoxFit.cover, cacheWidth: 900, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.12), Colors.black.withValues(alpha: 0.62)],
              ),
            ),
          ),
        ],
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
    final done = store.habits.where((h) => store.isDue(h, now) && store.successOn(h, now)).length;
    final cats = ['All', ...{for (final h in store.habits) h.category}];
    var list = store.habits;
    if (_filter != 'All') list = list.where((h) => h.category == _filter).toList();
    final consistency = store.overallConsistency();

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
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Reveal(delayMs: 120, child: Text('$done/$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.lime))),
                ),
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
                    Row(
                      children: [
                        const Kicker('TODAY'),
                        const Spacer(),
                        Text(total == 0 ? '0%' : '${((done / total) * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.lime)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ConsistencyLine(value: total == 0 ? 0.0 : done / total, color: C.lime),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _statMini('${store.habits.isEmpty ? 0 : store.habits.map(store.currentStreak).reduce(math.max)}', 'Best current', Icons.local_fire_department_rounded, C.orange),
                        _statMini('${store.habits.isEmpty ? 0 : store.habits.map(store.bestStreak).reduce(math.max)}', 'Best ever', Icons.emoji_events_rounded, C.lime),
                        _statMini(total == 0 ? '0%' : '${((done / total) * 100).round()}%', 'Today', Icons.track_changes_rounded, C.teal),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Kicker('CONSISTENCY · 30 DAYS', color: C.teal),
                        const Spacer(),
                        Text('${(consistency * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.teal)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ConsistencyLine(value: consistency, color: C.teal),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Reveal(
              delayMs: 460,
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _filter = cats[i]),
                    child: Center(child: Chip2(cats[i], selected: _filter == cats[i])),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
          child: Semantics(
            button: true,
            label: 'Add habit',
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
              Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.text)),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: C.mute)),
            ],
          ),
        ),
      );
}

/// Type-aware habit card — normal (checkbox), avoid (log a slip),
/// amount (increment toward a daily goal), or a checklist progress pill.
class HabitCard extends StatefulWidget {
  const HabitCard({super.key, required this.store, required this.habit, required this.onOpen});
  final AppStore store;
  final Habit habit;
  final VoidCallback onOpen;
  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  final GlobalKey _actionKey = GlobalKey();

  Future<void> _afterToggle(bool wasAllDoneBefore) async {
    if (!wasAllDoneBefore && widget.store.allDueDoneToday() && mounted) {
      showDayCompleteBanner(context);
    }
  }

  void _tapNormal() async {
    final store = widget.store;
    final h = widget.habit;
    final now = DateTime.now();
    final wasAll = store.allDueDoneToday();
    final becomingDone = !store.isDoneOn(h, now);
    HapticFeedback.mediumImpact();
    if (becomingDone) fireCompletionBurst(context, _actionKey, h.color);
    await store.toggleHabit(h, now);
    _afterToggle(wasAll);
  }

  void _tapAvoid() async {
    final store = widget.store;
    final h = widget.habit;
    final now = DateTime.now();
    HapticFeedback.lightImpact();
    await store.toggleHabit(h, now); // done == slipped, for avoid habits
  }

  void _incrementAmount() async {
    final store = widget.store;
    final h = widget.habit;
    final now = DateTime.now();
    final wasAll = store.allDueDoneToday();
    final current = store.amountOn(h, now);
    final wasGoalReached = current >= h.amountGoal;
    final next = current + 1;
    HapticFeedback.lightImpact();
    await store.setAmount(h, now, next);
    if (!wasGoalReached && next >= h.amountGoal) {
      fireCompletionBurst(context, _actionKey, h.color);
      HapticFeedback.mediumImpact();
    }
    _afterToggle(wasAll);
  }

  /// 44x44 touch target around the visible control.
  Widget _hit({required String label, required VoidCallback onTap, required Widget child}) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            alignment: Alignment.center,
            child: KeyedSubtree(key: _actionKey, child: child),
          ),
        ),
      );

  Widget _trailingControl() {
    final store = widget.store;
    final h = widget.habit;
    final now = DateTime.now();

    if (h.hasChecklist) {
      final total = h.checklist.length;
      final n = store.stepsDoneOn(h, now);
      final all = n >= total;
      return _hit(
        label: '${h.name}: $n of $total steps done. Open checklist',
        onTap: widget.onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: all ? h.color : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: all ? h.color : Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checklist_rounded, size: 15, color: all ? C.base : C.text),
              const SizedBox(width: 5),
              Text('$n/$total', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: all ? C.base : C.text)),
            ],
          ),
        ),
      );
    }

    if (h.type == 'avoid') {
      final slipped = store.isDoneOn(h, now);
      return _hit(
        label: slipped ? '${h.name}: slipped today. Tap to undo' : '${h.name}: tap to log a slip',
        onTap: _tapAvoid,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: slipped ? C.coral.withValues(alpha: 0.18) : Colors.transparent,
            border: Border.all(color: slipped ? C.coral : Colors.white.withValues(alpha: 0.3), width: 1.6),
          ),
          child: Icon(slipped ? Icons.close_rounded : Icons.shield_outlined, color: slipped ? C.coral : Colors.white.withValues(alpha: 0.6), size: 18),
        ),
      );
    }

    if (h.type == 'amount') {
      final value = store.amountOn(h, now);
      final reached = value >= h.amountGoal;
      final txt = '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}/${h.amountGoal.toStringAsFixed(h.amountGoal.truncateToDouble() == h.amountGoal ? 0 : 1)}';
      return _hit(
        label: '${h.name}: $txt. Tap to add one',
        onTap: _incrementAmount,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: reached ? h.color : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: reached ? h.color : Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(txt, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: reached ? C.base : C.text)),
        ),
      );
    }

    final done = store.isDoneOn(h, now);
    return _hit(
      label: done ? '${h.name}: done. Tap to undo' : '${h.name}: tap to complete',
      onTap: _tapNormal,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final h = widget.habit;
    final now = DateTime.now();
    final streak = store.currentStreak(h);
    final week = List.generate(7, (i) => now.subtract(Duration(days: now.weekday - 1 - i)));
    final cover = coverFileOf(h);

    return GestureDetector(
      onTap: widget.onOpen,
      child: Glass(
        radius: 24,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cover != null) _coverImage(cover, height: 92),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                            Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: C.text)),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                const Icon(Icons.local_fire_department_rounded, size: 14, color: C.orange),
                                const SizedBox(width: 3),
                                Text('$streak', style: const TextStyle(fontSize: 12, color: C.mute)),
                                const SizedBox(width: 8),
                                Chip2(h.category, color: categoryColor(h.category)),
                                if (h.type != 'normal') ...[
                                  const SizedBox(width: 6),
                                  Chip2(habitTypeLabel(h.type), color: C.violet),
                                ],
                              ]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _trailingControl(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: week.map((d) {
                      final due = store.isDue(h, d);
                      final ok = store.successOn(h, d);
                      final today = dayKey(d) == dayKey(now);
                      return Expanded(
                        child: Column(
                          children: [
                            Text(weekdayShort(d.weekday).substring(0, 1), style: TextStyle(fontSize: 11, color: today ? C.lime : C.mute)),
                            const SizedBox(height: 5),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: !due ? Colors.white.withValues(alpha: 0.08) : (ok ? h.color : Colors.white.withValues(alpha: 0.18)),
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
          ],
        ),
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
  final GlobalKey _stepBurstKey = GlobalKey();

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

  Future<void> _tapStep(ChecklistItem step) async {
    final store = widget.store;
    final habit = h;
    final now = DateTime.now();
    final wasDone = store.isDoneOn(habit, now);
    final wasAll = store.allDueDoneToday();
    HapticFeedback.selectionClick();
    await store.toggleStep(habit, now, step.id);
    if (!mounted) return;
    setState(() {});
    if (!wasDone && store.isDoneOn(habit, now)) {
      HapticFeedback.mediumImpact();
      fireCompletionBurst(context, _stepBurstKey, habit.color);
      if (!wasAll && store.allDueDoneToday()) showDayCompleteBanner(context);
    }
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
    final cover = coverFileOf(h);
    final consistency = store.consistency(h);

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
                    IconButton(tooltip: 'Close', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: C.text)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Edit habit',
                      onPressed: () async {
                        await showGlassSheet(context, HabitEditor(store: store, existing: h));
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.edit_rounded, color: C.text),
                    ),
                    IconButton(
                      tooltip: 'Delete habit',
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF1A1A22),
                            title: const Text('Delete this habit?', style: TextStyle(color: C.text)),
                            content: const Text('This removes its history and reminders too.', style: TextStyle(color: C.mute)),
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
                if (cover != null) ...[
                  const SizedBox(height: 4),
                  ClipRRect(borderRadius: BorderRadius.circular(28), child: _coverImage(cover, height: 168)),
                ],
                const SizedBox(height: 14),
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
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Chip2(_repeatLabel(h), color: h.color),
                  Chip2(habitTypeLabel(h.type), color: C.violet),
                  Chip2(h.category, color: categoryColor(h.category)),
                ]),
                if (h.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Glass(radius: 22, padding: const EdgeInsets.all(16), child: Text(h.description.trim(), style: const TextStyle(fontSize: 14, height: 1.5, color: C.text))),
                ],
                if (h.hasChecklist) ...[
                  const SizedBox(height: 20),
                  Glass(
                    radius: 24,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Kicker('CHECKLIST'),
                            const Spacer(),
                            Container(key: _stepBurstKey, child: Text('${store.stepsDoneOn(h, now)}/${h.checklist.length}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: h.color))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...h.checklist.map((step) {
                          final on = store.stepDone(h, now, step.id);
                          return Semantics(
                            button: true,
                            checked: on,
                            label: step.title,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _tapStep(step),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 48),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: on ? h.color : Colors.transparent,
                                        border: Border.all(color: on ? h.color : Colors.white.withValues(alpha: 0.3), width: 1.6),
                                      ),
                                      child: on ? const Icon(Icons.check_rounded, size: 16, color: C.base) : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        step.title,
                                        style: TextStyle(fontSize: 14.5, color: on ? C.mute : C.text, decoration: on ? TextDecoration.lineThrough : null),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                    if (h.focusEnabled) ...[
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
                        if (_elapsed > 0 && !_running) IconButton(tooltip: 'Save focus time', onPressed: _save, icon: const Icon(Icons.check_circle_rounded, color: C.lime, size: 30)),
                        Semantics(
                          button: true,
                          label: _running ? 'Pause timer' : 'Start timer',
                          child: GestureDetector(
                            onTap: _startPause,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: C.base),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (h.reminders.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Glass(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: C.lime, size: 22),
                        const SizedBox(width: 14),
                        const Text('Reminders', style: TextStyle(fontSize: 15, color: C.mute)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (List.of(h.reminders)..sort()).map(fmtMinutes).join(' · '),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: C.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                Glass(
                  radius: 24,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Kicker('CONSISTENCY · 30 DAYS', color: C.teal),
                          const Spacer(),
                          Text('${(consistency * 100).round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.teal)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConsistencyLine(value: consistency, color: h.color),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionLabel('ACTIVITY'),
                Row(
                  children: ['Week', 'Month', 'Year'].map((r) {
                    final on = r == _range;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _range = r), child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Chip2(r, selected: on))),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Glass(radius: 24, padding: const EdgeInsets.all(18), child: _activityView(store, h, now)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _LegendDot(color: h.color, label: 'Done'),
                    _LegendDot(color: Colors.white.withValues(alpha: 0.18), label: 'Missed'),
                    _LegendDot(color: Colors.white.withValues(alpha: 0.08), label: 'Not scheduled'),
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
      case 'everyNDays':
        return 'Every ${h.everyNDays} days';
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
              Text('$value${suffix.isNotEmpty ? ' $suffix' : ''}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.text)),
              const SizedBox(height: 2),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: C.mute)),
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
          final ok = store.successOn(h, d);
          final due = store.isDue(h, d);
          final today = dayKey(d) == dayKey(now);
          return Expanded(
            child: Column(
              children: [
                Text('${d.day}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: today ? C.lime : C.text)),
                Text(weekdayShort(d.weekday), style: const TextStyle(fontSize: 11, color: C.mute)),
                const SizedBox(height: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !due ? Colors.white.withValues(alpha: 0.05) : (ok ? h.color : Colors.white.withValues(alpha: 0.10)),
                    border: today ? Border.all(color: C.lime, width: 1.4) : null,
                  ),
                  child: ok ? const Icon(Icons.check_rounded, size: 16, color: C.base) : null,
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
          final ok = store.successOn(h, d);
          final due = store.isDue(h, d);
          return Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: !due ? Colors.white.withValues(alpha: 0.05) : (ok ? h.color : Colors.white.withValues(alpha: 0.10)),
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
          final ok = store.successOn(h, d);
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: ok ? h.color : Colors.white.withValues(alpha: 0.08)),
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
          Text(label, style: const TextStyle(fontSize: 11, color: C.mute)),
        ],
      );
}

// ═══════════════════════════════ Habit editor ═══════════════════════════════

class HabitEditor extends StatefulWidget {
  const HabitEditor({super.key, required this.store, this.existing});
  final AppStore store;
  final Habit? existing;
  @override
  State<HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<HabitEditor> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _unit = TextEditingController(text: widget.existing?.amountUnit ?? '');
  late final TextEditingController _desc = TextEditingController(text: widget.existing?.description ?? '');
  final TextEditingController _newStep = TextEditingController();
  late int _icon = widget.existing?.iconIndex ?? 0;
  late Color _color = widget.existing?.color ?? C.teal;
  late String _repeat = widget.existing?.repeatType ?? 'daily';
  late List<int> _weekdays = List.of(widget.existing?.weekdays ?? [1, 2, 3, 4, 5]);
  late int _timesPerWeek = widget.existing?.timesPerWeek ?? 3;
  late int _everyN = widget.existing?.everyNDays ?? 2;
  late String _category = widget.existing?.category ?? 'Study';
  late String _type = widget.existing?.type ?? 'normal';
  late int _amountGoal = (widget.existing?.amountGoal ?? 1).round();
  late bool _hasTime = widget.existing?.plannedMinutes != null;
  late int _plannedMinutes = widget.existing?.plannedMinutes ?? 8 * 60;
  late bool _focus = widget.existing?.focusEnabled ?? true;
  late List<ChecklistItem> _steps = widget.existing?.checklist.map((e) => ChecklistItem(id: e.id, title: e.title)).toList() ?? <ChecklistItem>[];
  late List<int> _reminders = List.of(widget.existing?.reminders ?? <int>[]);
  late String? _cover = widget.existing?.coverImagePath;
  final List<String> _createdCovers = [];
  bool _saved = false;
  String? _notifMsg;
  bool _pickingCover = false;

  static const _colors = [C.teal, C.violet, C.orange, C.lime, C.coral];
  static const _periods = [('Morning', 8 * 60), ('Afternoon', 14 * 60), ('Evening', 19 * 60), ('Night', 21 * 60 + 30)];

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _desc.dispose();
    _newStep.dispose();
    if (!_saved) {
      for (final p in _createdCovers) {
        _rm(p);
      }
    }
    super.dispose();
  }

  void _rm(String? p) {
    if (p == null) return;
    try {
      final f = File(p);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  // ───────────── small building blocks ─────────────

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: child,
      );

  Widget _section(String label, Widget child, {String? hint}) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(label),
            if (hint != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(hint, style: const TextStyle(fontSize: 12, height: 1.4, color: C.mute))),
            child,
          ],
        ),
      );

  /// A chip with a full 44px-tall touch target.
  Widget _chip(String text, bool selected, VoidCallback onTap, {Color? color}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Chip2(text, selected: selected, color: color ?? C.lime)),
      );

  InputDecoration _fieldDeco(String hint, {double radius = 16}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: C.mute, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
      );

  String _typeHint() {
    switch (_type) {
      case 'avoid':
        return 'Something to stay away from. Tap when you slip — days without a slip build the streak.';
      case 'amount':
        return 'Count towards a daily goal, like 8 glasses of water.';
      default:
        return 'Tap to complete it each day.';
    }
  }

  // ───────────── checklist ─────────────

  void _addStep() {
    final t = _newStep.text.trim();
    if (t.isEmpty || _steps.length >= 12) return;
    setState(() {
      _steps.add(ChecklistItem(id: newId() + _steps.length.toString(), title: t));
      _newStep.clear();
    });
  }

 // ───────────── reminders ─────────────

  Future<void> _addReminder() async {
    final init = _hasTime ? _plannedMinutes : 8 * 60;
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: init ~/ 60, minute: init % 60));
    if (picked == null || !mounted) return;
    final m = picked.hour * 60 + picked.minute;
    if (_reminders.contains(m)) {
      setState(() => _notifMsg = 'You already have a reminder at ${fmtMinutes(m)}.');
      return;
    }
    setState(() {
      _reminders.add(m);
      _reminders.sort();
      _notifMsg = null;
    });
    await _checkPermission();
  }

  Future<void> _editReminder(int index) async {
    final cur = _reminders[index];
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60));
    if (picked == null || !mounted) return;
    final m = picked.hour * 60 + picked.minute;
    if (m != cur && _reminders.contains(m)) {
      setState(() => _notifMsg = 'You already have a reminder at ${fmtMinutes(m)}.');
      return;
    }
    setState(() {
      _reminders[index] = m;
      _reminders.sort();
      _notifMsg = null;
    });
  }

  Future<void> _checkPermission() async {
    final ok = await NotificationService.requestPermission();
    if (!mounted) return;
    setState(() => _notifMsg = ok ? null : 'Notifications are blocked for Daybook. Allow them in Android Settings to receive reminders.');
  }

  Future<void> _sendTest() async {
    final ok = await NotificationService.sendTest();
    if (!mounted) return;
    setState(() => _notifMsg = ok ? 'Test sent — check your notification shade.' : 'Notifications are blocked for Daybook. Allow them in Android Settings.');
  }

  // ───────────── cover image ─────────────

  Future<void> _pickCover() async {
    if (_pickingCover) return;
    setState(() => _pickingCover = true);
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 82);
      if (img == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final ext = img.path.contains('.') ? img.path.split('.').last : 'jpg';
      final dest = '${dir.path}/habit_cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(img.path).copy(dest);
      _createdCovers.add(dest);
      if (_cover != null && _createdCovers.contains(_cover)) {
        _rm(_cover);
        _createdCovers.remove(_cover);
      }
      if (mounted) setState(() => _cover = dest);
    } catch (_) {
      // picker cancelled or platform quirk — keep the current cover
    } finally {
      if (mounted) setState(() => _pickingCover = false);
    }
  }

  void _removeCover() {
    if (_cover != null && _createdCovers.contains(_cover)) {
      _rm(_cover);
      _createdCovers.remove(_cover);
    }
    setState(() => _cover = null);
  }

  // ───────────── save ─────────────

  void _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final reminders = (_reminders.toSet().toList()..sort()).take(NotificationService.maxReminders).toList();
    final steps = _steps.where((s) => s.title.trim().isNotEmpty).toList();
    final ex = widget.existing;
    if (ex != null) {
      final oldCover = ex.coverImagePath;
      ex.name = name;
      ex.iconIndex = _icon;
      ex.colorValue = _color.value;
      ex.repeatType = _repeat;
      ex.weekdays = _weekdays;
      ex.timesPerWeek = _timesPerWeek;
      ex.everyNDays = _everyN;
      ex.category = _category;
      ex.plannedMinutes = _hasTime ? _plannedMinutes : null;
      ex.type = _type;
      ex.amountUnit = _unit.text.trim();
      ex.amountGoal = _amountGoal.toDouble();
      ex.description = _desc.text.trim();
      ex.checklist = steps;
      ex.reminders = reminders;
      ex.focusEnabled = _focus;
      ex.coverImagePath = _cover;
      await widget.store.updateHabit(ex);
      if (oldCover != null && oldCover != _cover) _rm(oldCover);
    } else {
      final h = Habit(
        id: newId(),
        name: name,
        iconIndex: _icon,
        colorValue: _color.value,
        repeatType: _repeat,
        weekdays: _weekdays,
        timesPerWeek: _timesPerWeek,
        everyNDays: _everyN,
        category: _category,
        plannedMinutes: _hasTime ? _plannedMinutes : null,
        type: _type,
        amountUnit: _unit.text.trim(),
        amountGoal: _amountGoal.toDouble(),
        createdAt: DateTime.now(),
        description: _desc.text.trim(),
        checklist: steps,
        reminders: reminders,
        focusEnabled: _focus,
        coverImagePath: _cover,
      );
      await widget.store.addHabit(h);
    }
    for (final p in _createdCovers) {
      if (p != _cover) _rm(p);
    }
    _saved = true;
    if (mounted) Navigator.pop(context);
  }

// ───────────── build ─────────────

  @override
  Widget build(BuildContext context) {
    final notifOn = widget.store.settings.notificationsEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.existing == null ? 'New habit' : 'Edit habit', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.text)),
        const SizedBox(height: 18),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(color: C.text, fontSize: 16),
          decoration: _fieldDeco('Habit name'),
        ),

        // ── TYPE ──
        _section(
          'TYPE',
          Wrap(
            spacing: 8,
            children: [
              _chip('Normal', _type == 'normal', () => setState(() => _type = 'normal')),
              _chip('Avoid', _type == 'avoid', () => setState(() => _type = 'avoid'), color: C.coral),
              _chip('Amount', _type == 'amount', () => setState(() => _type = 'amount'), color: C.teal),
            ],
          ),
          hint: _typeHint(),
        ),
        if (_type == 'amount') ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: TextField(controller: _unit, style: const TextStyle(color: C.text, fontSize: 14), decoration: _fieldDeco('Unit (e.g. glasses, pages)', radius: 14))),
              const SizedBox(width: 6),
              IconButton(tooltip: 'Decrease goal', onPressed: () => setState(() => _amountGoal = (_amountGoal - 1).clamp(1, 999)), icon: const Icon(Icons.remove_circle_outline, color: C.mute)),
              SizedBox(width: 32, child: Text('$_amountGoal', textAlign: TextAlign.center, style: const TextStyle(color: C.text, fontSize: 15, fontWeight: FontWeight.w600))),
              IconButton(tooltip: 'Increase goal', onPressed: () => setState(() => _amountGoal = (_amountGoal + 1).clamp(1, 999)), icon: const Icon(Icons.add_circle_outline, color: C.mute)),
            ],
          ),
        ],

        // ── FOCUS ──
        _section(
          'FOCUS',
          _card(Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, color: C.mute, size: 22),
              const SizedBox(width: 12),
              const Expanded(child: Text('Focus sessions', style: TextStyle(color: C.text, fontSize: 14.5))),
              Switch(value: _focus, activeColor: _color, onChanged: (v) => setState(() => _focus = v)),
            ],
          )),
          hint: 'Adds a timer to this habit. Time you save counts as focus time.',
        ),

        // ── CHECKLIST (normal habits only) ──
        if (_type == 'normal')
          _section(
            'CHECKLIST',
            _card(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_steps.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('No steps. Without steps, the habit is a single tap.', style: TextStyle(fontSize: 12.5, color: C.mute)),
                  ),
                for (int i = 0; i < _steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.4))),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_steps[i].title, style: const TextStyle(color: C.text, fontSize: 14.5))),
                        IconButton(
                          tooltip: 'Remove step',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _steps.removeAt(i)),
                          icon: const Icon(Icons.close_rounded, color: C.mute, size: 20),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newStep,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addStep(),
                        style: const TextStyle(color: C.text, fontSize: 14),
                        decoration: _fieldDeco(_steps.length >= 12 ? 'Up to 12 steps' : 'Add a step', radius: 14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(tooltip: 'Add step', onPressed: _addStep, icon: Icon(Icons.add_circle_rounded, color: _color, size: 30)),
                  ],
                ),
              ],
            )),
            hint: 'Split the habit into steps. It counts as done when every step is ticked.',
          ),

        // ── DESCRIPTION ──
        _section(
          'DESCRIPTION',
          TextField(
            controller: _desc,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: C.text, fontSize: 14.5),
            decoration: _fieldDeco('Why this habit matters, or a note to yourself'),
          ),
        ),

        // ── ICON ──
        _section(
          'ICON',
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: habitIcons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final on = i == _icon;
                return Semantics(
                  button: true,
                  selected: on,
                  label: 'Icon ${i + 1}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _icon = i),
                    child: Center(
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on ? _color.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                          border: on ? Border.all(color: _color, width: 1.6) : null,
                        ),
                        child: Icon(habitIcons[i], color: on ? _color : C.mute, size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ── COLOUR (scrollable) ──
        _section(
          'COLOUR',
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _colors[i];
                final on = c.value == _color.value;
                return Semantics(
                  button: true,
                  selected: on,
                  label: 'Colour ${i + 1}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _color = c),
                    child: SizedBox(
                      width: 48,
                      height: 52,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: on ? Border.all(color: Colors.white, width: 2.4) : null),
                          child: on ? const Icon(Icons.check_rounded, color: C.base, size: 18) : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

// ── CATEGORY ──
        _section(
          'CATEGORY',
          Wrap(spacing: 8, children: categories.map((c) => _chip(c, c == _category, () => setState(() => _category = c), color: categoryColor(c))).toList()),
        ),

        // ── FREQUENCY ──
        _section(
          'FREQUENCY',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _chip('Daily', _repeat == 'daily', () => setState(() => _repeat = 'daily')),
                  _chip('Choose days', _repeat == 'weekdays', () => setState(() => _repeat = 'weekdays')),
                  _chip('N per week', _repeat == 'timesPerWeek', () => setState(() => _repeat = 'timesPerWeek')),
                  _chip('Every N days', _repeat == 'everyNDays', () => setState(() => _repeat = 'everyNDays')),
                ],
              ),
              if (_repeat == 'weekdays')
                Row(
                  children: List.generate(7, (i) {
                    final d = i + 1;
                    final on = _weekdays.contains(d);
                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: on,
                        label: weekdayShort(d),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => on ? _weekdays.remove(d) : _weekdays.add(d)),
                          child: SizedBox(
                            height: 44,
                            child: Center(
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: on ? _color : Colors.white.withValues(alpha: 0.08),
                                child: Text(weekdayShort(d).substring(0, 1), style: TextStyle(color: on ? C.base : C.mute, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              if (_repeat == 'timesPerWeek')
                Row(
                  children: [
                    IconButton(tooltip: 'Fewer', onPressed: () => setState(() => _timesPerWeek = (_timesPerWeek - 1).clamp(1, 7).toInt()), icon: const Icon(Icons.remove_circle_outline, color: C.mute)),
                    Text('$_timesPerWeek× a week', style: const TextStyle(color: C.text, fontSize: 15)),
                    IconButton(tooltip: 'More', onPressed: () => setState(() => _timesPerWeek = (_timesPerWeek + 1).clamp(1, 7).toInt()), icon: const Icon(Icons.add_circle_outline, color: C.mute)),
                  ],
                ),
              if (_repeat == 'everyNDays')
                Row(
                  children: [
                    IconButton(tooltip: 'Fewer days', onPressed: () => setState(() => _everyN = (_everyN - 1).clamp(2, 30)), icon: const Icon(Icons.remove_circle_outline, color: C.mute)),
                    Text('Every $_everyN days', style: const TextStyle(color: C.text, fontSize: 15)),
                    IconButton(tooltip: 'More days', onPressed: () => setState(() => _everyN = (_everyN + 1).clamp(2, 30)), icon: const Icon(Icons.add_circle_outline, color: C.mute)),
                  ],
                ),
            ],
          ),
        ),

        // ── TIME OF DAY ──
        _section(
          'TIME OF DAY',
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Planned time', style: TextStyle(color: C.text, fontSize: 14.5))),
                  Switch(value: _hasTime, activeColor: _color, onChanged: (v) => setState(() => _hasTime = v)),
                ],
              ),
              if (_hasTime) ...[
                Wrap(
                  spacing: 8,
                  children: _periods.map((p) => _chip(p.$1, _plannedMinutes == p.$2, () => setState(() => _plannedMinutes = p.$2), color: _color)).toList(),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _plannedMinutes ~/ 60, minute: _plannedMinutes % 60));
                    if (picked != null) setState(() => _plannedMinutes = picked.hour * 60 + picked.minute);
                  },
                  child: Glass(
                    radius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: C.mute, size: 18),
                        const SizedBox(width: 10),
                        Text(fmtMinutes(_plannedMinutes), style: const TextStyle(color: C.text, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          )),
        ),

     // ── REMINDERS ──
        _section(
          'REMINDERS',
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_reminders.isEmpty)
                const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('No reminders. Add a time and Daybook will nudge you.', style: TextStyle(fontSize: 12.5, color: C.mute))),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < _reminders.length; i++)
                    Container(
                      padding: const EdgeInsets.only(left: 14),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: _color.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _editReminder(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.notifications_rounded, size: 15, color: _color),
                                const SizedBox(width: 6),
                                Text(fmtMinutes(_reminders[i]), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _color)),
                              ]),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove reminder',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() {
                              _reminders.removeAt(i);
                              _notifMsg = null;
                            }),
                            icon: Icon(Icons.close_rounded, size: 18, color: _color),
                          ),
                        ],
                      ),
                    ),
                  if (_reminders.length < NotificationService.maxReminders)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _addReminder,
                      child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Chip2('+ Add time', selected: false)),
                    ),
                ],
              ),
              if (!notifOn)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Reminders are switched off in Settings → Notifications, so none will fire until you turn them on.', style: TextStyle(fontSize: 12, height: 1.4, color: C.orange)),
                ),
              if (_notifMsg != null)
                Padding(padding: const EdgeInsets.only(top: 10), child: Text(_notifMsg!, style: const TextStyle(fontSize: 12, height: 1.4, color: C.orange))),
              const SizedBox(height: 4),
              _chip('Send a test notification', false, _sendTest, color: _color),
            ],
          )),
          hint: _repeat == 'weekdays'
              ? 'Fires on the days you chose.'
              : (_repeat == 'everyNDays' ? 'Fires on the days this habit is due.' : 'Fires every day.'),
        ),

        // ── COVER IMAGE ──
        _section(
          'COVER IMAGE',
          _card(_coverBlock()),
          hint: 'A picture for this habit only — it appears on its card and page.',
        ),

        const SizedBox(height: 24),
        PillButton(label: widget.existing == null ? 'Create habit' : 'Save changes', onTap: _save, color: _color, compactGlow: true),
        // room for the button glow so the sheet never crops it into a rectangle
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _coverBlock() {
    final f = _cover == null ? null : File(_cover!);
    final has = f != null && f.existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: has ? 'Replace cover image' : 'Choose cover image',
          child: GestureDetector(
            onTap: _pickCover,
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: has
                    ? _coverImage(f!)
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _pickingCover
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(Icons.add_photo_alternate_rounded, color: _color, size: 28),
                            const SizedBox(height: 8),
                            const Text('Choose a cover image', style: TextStyle(fontSize: 13, color: C.mute)),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (has)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _chip('Replace', false, _pickCover, color: _color),
                const SizedBox(width: 8),
                _chip('Remove', false, _removeCover, color: C.coral),
              ],
            ),
          ),
      ],
    );
  }
}
 
