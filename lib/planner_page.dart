import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'data.dart';
import 'versind_widgets.dart';

enum PlannerView { day, week, month }

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key, required this.store});
  final AppStore store;
  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  DateTime _selected = dateOnly(DateTime.now());
  PlannerView _view = PlannerView.day;
  late DateTime _month = DateTime(_selected.year, _selected.month, 1);
  final ScrollController _dayScroll = ScrollController();
  final ScrollController _weekScroll = ScrollController();
  static const double hourHeight = 76;
  static const double weekHour = 56;
  static const double gutter = 44;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpTo(_dayScroll, hourHeight));
  }

  @override
  void dispose() {
    _dayScroll.dispose();
    _weekScroll.dispose();
    super.dispose();
  }

  /// Today: scroll to the current time. Any other day: start the view around 8 AM.
  void _jumpTo(ScrollController c, double hh) {
    if (!c.hasClients) return;
    final s = widget.store.settings;
    final now = DateTime.now();
    final isToday = dateOnly(_selected) == dateOnly(now);
    final focusMin = isToday ? now.hour * 60 + now.minute : 8 * 60;
    final offset = ((focusMin - s.dayStartHour * 60) / 60 * hh - 160).clamp(0.0, c.position.maxScrollExtent).toDouble();
    c.jumpTo(offset);
  }

  void _setView(PlannerView v) {
    if (v == _view) return;
    HapticFeedback.selectionClick();
    setState(() {
      _view = v;
      if (v == PlannerView.month) _month = DateTime(_selected.year, _selected.month, 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (v == PlannerView.day) _jumpTo(_dayScroll, hourHeight);
      if (v == PlannerView.week) _jumpTo(_weekScroll, weekHour);
    });
  }

  void _openDay(DateTime d) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = dateOnly(d);
      _view = PlannerView.day;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpTo(_dayScroll, hourHeight));
  }

  List<DateTime> _weekOf(DateTime d) => List.generate(7, (i) => DateTime(d.year, d.month, d.day - (d.weekday - 1) + i));

  int _hours() {
    final s = widget.store.settings;
    return (s.dayEndHour - s.dayStartHour).clamp(1, 24).toInt();
  }

  String _shortHour(int h) {
    final x = h % 24;
    final h12 = x % 12 == 0 ? 12 : x % 12;
    return '$h12 ${x < 12 ? 'AM' : 'PM'}';
  }

  // ───────────────────────── build ─────────────────────────

  Widget _viewChip(String label, PlannerView v) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _setView(v),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Chip2(label, selected: _view == v)),
      );

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_view) {
      case PlannerView.day:
        body = _dayBody();
        break;
      case PlannerView.week:
        body = _weekBody();
        break;
      case PlannerView.month:
        body = _monthBody();
        break;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Reveal(child: Kicker(dateLabel(_selected))),
              const SizedBox(height: 8),
              const Reveal(
                delayMs: 100,
                child: Text.rich(TextSpan(children: [TextSpan(text: 'Shape your ', style: h1Light), TextSpan(text: 'day.', style: h1Bold)])),
              ),
              const SizedBox(height: 8),
              Reveal(
                delayMs: 180,
                child: Row(children: [
                  _viewChip('Day', PlannerView.day),
                  const SizedBox(width: 8),
                  _viewChip('Week', PlannerView.week),
                  const SizedBox(width: 8),
                  _viewChip('Month', PlannerView.month),
                ]),
              ),
              const SizedBox(height: 6),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _view == PlannerView.month
                      ? KeyedSubtree(key: const ValueKey('month-head'), child: _monthHeader())
                      : KeyedSubtree(
                          key: const ValueKey('week-head'),
                          child: PagedDatePanel(
                            selected: _selected,
                            onSelect: (d) {
                              setState(() => _selected = dateOnly(d));
                              if (_view == PlannerView.day) WidgetsBinding.instance.addPostFrameCallback((_) => _jumpTo(_dayScroll, hourHeight));
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim), child: child),
            ),
            child: KeyedSubtree(key: ValueKey(_view), child: body),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Day ─────────────────────────

  Widget _dayBody() {
    final store = widget.store;
    final s = store.settings;
    final blocks = store.blocksOn(_selected);
    final totalHours = _hours();
    final now = DateTime.now();
    final isToday = dateOnly(now) == dateOnly(_selected);

    return SingleChildScrollView(
      controller: _dayScroll,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 140),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _createAt(_selected, d.localPosition.dy, hourHeight),
        child: SizedBox(
          height: totalHours * hourHeight,
          child: Stack(
            children: [
              for (int i = 0; i <= totalHours; i++)
                Positioned(
                  top: i * hourHeight,
                  left: 0,
                  right: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 52, child: Text(fmtHour(s.dayStartHour + i), style: const TextStyle(fontSize: 11, color: C.mute))),
                      Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.07))),
                    ],
                  ),
                ),
              for (final b in blocks)
                Positioned(
                  top: (b.startMinutes - s.dayStartHour * 60) / 60 * hourHeight,
                  left: 58,
                  right: 0,
                  height: math.max(30.0, b.durationMinutes / 60 * hourHeight - 4),
                  child: GestureDetector(
                    onTap: () => _editBlock(_selected, b),
                    child: BlockCard(key: ValueKey(b.id), block: b, store: store),
                  ),
                ),
              if (isToday)
                Positioned(
                  top: (now.hour * 60 + now.minute - s.dayStartHour * 60) / 60 * hourHeight,
                  left: 52,
                  right: 0,
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: Accent.color, shape: BoxShape.circle)),
                      Expanded(child: Container(height: 1.4, color: Accent.color.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Week ─────────────────────────

  Widget _weekBody() {
    final store = widget.store;
    final s = store.settings;
    final week = _weekOf(_selected);
    final totalHours = _hours();
    final now = DateTime.now();
    final today = dateOnly(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, cons) {
          final colW = (cons.maxWidth - gutter) / 7;
          return Column(
            children: [
              // day headers — tap one to open that day
              Row(
                children: [
                  const SizedBox(width: gutter),
                  for (final d in week)
                    SizedBox(
                      width: colW,
                      child: Semantics(
                        button: true,
                        label: 'Open ${weekdayShort(d.weekday)} ${d.day}',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openDay(d),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              children: [
                                Text(weekdayShort(d.weekday).substring(0, 1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dateOnly(d) == today ? Accent.color : C.mute)),
                                const SizedBox(height: 4),
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: dateOnly(d) == today ? Accent.color : Colors.transparent),
                                  child: Text('${d.day}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: dateOnly(d) == today ? C.base : C.text)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              Expanded(
                child: SingleChildScrollView(
                  controller: _weekScroll,
                  padding: const EdgeInsets.only(bottom: 140),
                  child: SizedBox(
                    height: totalHours * weekHour,
                    child: Stack(
                      children: [
                        for (int i = 0; i <= totalHours; i++)
                          Positioned(
                            top: i * weekHour,
                            left: 0,
                            right: 0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: gutter, child: Text(_shortHour(s.dayStartHour + i), style: const TextStyle(fontSize: 10, color: C.mute))),
                                Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06))),
                              ],
                            ),
                          ),
                        for (int d = 0; d < 7; d++)
                          Positioned(
                            left: gutter + d * colW,
                            width: colW,
                            top: 0,
                            bottom: 0,
                            child: _weekColumn(week[d], colW, today),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _weekColumn(DateTime date, double colW, DateTime today) {
    final store = widget.store;
    final s = store.settings;
    final blocks = store.blocksOn(date);
    final isToday = dateOnly(date) == today;
    final now = DateTime.now();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isToday ? Accent.color.withValues(alpha: 0.05) : Colors.transparent,
        border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _createAt(date, d.localPosition.dy, weekHour),
            ),
          ),
          for (final b in blocks)
            Positioned(
              top: (b.startMinutes - s.dayStartHour * 60) / 60 * weekHour,
              left: 1.5,
              right: 1.5,
              height: math.max(24.0, b.durationMinutes / 60 * weekHour - 2),
              child: GestureDetector(onTap: () => _editBlock(date, b), child: _MiniBlock(block: b, tall: b.durationMinutes >= 60)),
            ),
          if (isToday)
            Positioned(
              top: (now.hour * 60 + now.minute - s.dayStartHour * 60) / 60 * weekHour,
              left: 0,
              right: 0,
              child: Container(height: 1.4, color: Accent.color.withValues(alpha: 0.8)),
            ),
        ],
      ),
    );
  }

  // ───────────────────────── Month ─────────────────────────

  Widget _monthHeader() {
    final today = dateOnly(DateTime.now());
    final onThisMonth = _month.year == today.year && _month.month == today.month;
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return Glass(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          IconButton(tooltip: 'Previous month', onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1)), icon: const Icon(Icons.chevron_left_rounded, color: C.mute)),
          Expanded(child: Text('${names[_month.month - 1]} ${_month.year}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text))),
          IconButton(tooltip: 'Next month', onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1)), icon: const Icon(Icons.chevron_right_rounded, color: C.mute)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _month = DateTime(today.year, today.month, 1)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 8, 10),
              child: Text('Today', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: onThisMonth ? C.mute : Accent.color)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthBody() {
    final lead = _month.weekday - 1;
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((lead + count) / 7).ceil();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 140),
      child: KeyedSubtree(
        key: ValueKey('m-${_month.year}-${_month.month}'),
        child: Column(
          children: [
            Row(children: kShortDays.map((d) => Expanded(child: Center(child: Text(d.substring(0, 1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.mute))))).toList()),
            const SizedBox(height: 8),
            for (int r = 0; r < rows; r++)
              Reveal(
                delayMs: r * 45,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: List.generate(7, (c) {
                      final n = r * 7 + c - lead + 1;
                      if (n < 1 || n > count) return const Expanded(child: SizedBox(height: 64));
                      return Expanded(child: _monthCell(DateTime(_month.year, _month.month, n)));
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _monthCell(DateTime date) {
    final store = widget.store;
    final blocks = store.blocksOn(date);
    final today = dateOnly(DateTime.now());
    final isToday = date == today;
    final isSel = date == dateOnly(_selected);
    final accent = Accent.color;
    return Semantics(
      button: true,
      label: '${date.day}, ${blocks.length} planned',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDay(date),
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSel ? accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: isToday ? accent : (isSel ? accent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.07)), width: isToday ? 1.5 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isToday ? accent : C.text)),
              const SizedBox(height: 6),
              SizedBox(
                height: 8,
                child: blocks.isEmpty
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final b in blocks.take(3))
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: priorityColor(b.priority).withValues(alpha: b.done ? 0.35 : 1)),
                            ),
                          if (blocks.length > 3) Text('+${blocks.length - 3}', style: const TextStyle(fontSize: 8.5, color: C.mute)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── shared ─────────────────────────

  void _createAt(DateTime date, double y, double hh) {
    final s = widget.store.settings;
    final rawMinutes = s.dayStartHour * 60 + (y / hh * 60);
    final slot = s.slotMinutes == 0 ? 30 : s.slotMinutes;
    final snapped = (rawMinutes / slot).round() * slot;
    showGlassSheet(context, BlockEditor(store: widget.store, date: date, initialStart: snapped.clamp(0, 23 * 60 + 45).toInt()));
  }

  void _editBlock(DateTime date, PlannerBlock b) {
    showGlassSheet(context, BlockEditor(store: widget.store, date: date, existing: b));
  }
}

/// Compact block for the week view.
class _MiniBlock extends StatelessWidget {
  const _MiniBlock({required this.block, required this.tall});
  final PlannerBlock block;
  final bool tall;
  @override
  Widget build(BuildContext context) {
    final c = priorityColor(block.priority);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: c.withValues(alpha: block.done ? 0.12 : 0.28),
        child: Row(
          children: [
            Container(width: 3, color: c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(3, 2, 2, 2),
                child: Text(
                  block.title,
                  maxLines: tall ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, height: 1.15, fontWeight: FontWeight.w600, color: block.done ? C.mute : C.text, decoration: block.done ? TextDecoration.lineThrough : null),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The planner block now fires the same shared completion burst as
/// habits, and only when transitioning TO done (not when un-checking).
class BlockCard extends StatefulWidget {
  const BlockCard({super.key, required this.block, required this.store});
  final PlannerBlock block;
  final AppStore store;
  @override
  State<BlockCard> createState() => _BlockCardState();
}

class _BlockCardState extends State<BlockCard> {
  final GlobalKey _checkKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final color = priorityColor(block.priority);
    return Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      tint: block.done ? 0.04 : 0.09,
      child: Row(
        children: [
          Container(width: 4, height: double.infinity, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: block.done ? C.mute : C.text,
                    decoration: block.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text('${fmtMinutes(block.startMinutes)} · ${fmtDurationShort(block.durationMinutes)} · ${block.category}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: C.mute)),
              ],
            ),
          ),
          GestureDetector(
            key: _checkKey,
            onTap: () {
              final willBeDone = !block.done;
              HapticFeedback.mediumImpact();
              if (willBeDone) fireCompletionBurst(context, _checkKey, color);
              widget.store.toggleBlock(block);
            },
            child: Icon(block.done ? Icons.check_circle_rounded : Icons.circle_outlined, color: block.done ? color : C.mute, size: 22),
          ),
        ],
      ),
    );
  }
}

class BlockEditor extends StatefulWidget {
  const BlockEditor({super.key, required this.store, required this.date, this.existing, this.initialStart});
  final AppStore store;
  final DateTime date;
  final PlannerBlock? existing;
  final int? initialStart;
  @override
  State<BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<BlockEditor> {
  late final TextEditingController _title = TextEditingController(text: widget.existing?.title ?? '');
  String _category = 'Study';
  String _priority = 'medium';
  late int _start = widget.existing?.startMinutes ?? widget.initialStart ?? 8 * 60;
  int _duration = 30;
  String? _linkedHabit;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? 'Study';
    _priority = widget.existing?.priority ?? 'medium';
    _duration = widget.existing?.durationMinutes ?? 30;
    _linkedHabit = widget.existing?.linkedHabitId;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() async {
    if (_title.text.trim().isEmpty) return;
    if (widget.existing != null) {
      final b = widget.existing!;
      b.title = _title.text.trim();
      b.category = _category;
      b.priority = _priority;
      b.startMinutes = _start;
      b.durationMinutes = _duration;
      b.linkedHabitId = _linkedHabit;
      await widget.store.updateBlock(b);
    } else {
      final b = PlannerBlock(
        id: newId(),
        title: _title.text.trim(),
        category: _category,
        priority: _priority,
        date: dayKey(widget.date),
        startMinutes: _start,
        durationMinutes: _duration,
        linkedHabitId: _linkedHabit,
      );
      await widget.store.addBlock(b);
    }
    if (mounted) Navigator.pop(context);
  }

  void _delete() async {
    if (widget.existing != null) {
      await widget.store.deleteBlock(widget.existing!.id);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final habits = widget.store.habits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.existing == null ? 'New block' : 'Edit block', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.text)),
        const SizedBox(height: 18),
        TextField(
          controller: _title,
          style: const TextStyle(color: C.text, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'What are you doing?',
            hintStyle: const TextStyle(color: C.mute),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel('PRIORITY'),
        Wrap(
          spacing: 8,
          children: [
            GestureDetector(onTap: () => setState(() => _priority = 'high'), child: Chip2('High', selected: _priority == 'high', color: C.red)),
            GestureDetector(onTap: () => setState(() => _priority = 'medium'), child: Chip2('Medium', selected: _priority == 'medium', color: C.yellow)),
            GestureDetector(onTap: () => setState(() => _priority = 'low'), child: Chip2('Low', selected: _priority == 'low', color: C.blue)),
          ],
        ),
        const SizedBox(height: 16),
        const SectionLabel('CATEGORY'),
        Wrap(
          spacing: 8,
          children: categories.map((c) => GestureDetector(onTap: () => setState(() => _category = c), child: Chip2(c, selected: c == _category, color: categoryColor(c)))).toList(),
        ),
        const SizedBox(height: 16),
        const SectionLabel('START TIME'),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _start ~/ 60, minute: _start % 60));
            if (picked != null) setState(() => _start = picked.hour * 60 + picked.minute);
          },
          child: Glass(radius: 18, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text(fmtMinutes(_start), style: const TextStyle(color: C.text, fontSize: 15))),
        ),
        const SizedBox(height: 16),
        const SectionLabel('DURATION'),
        Wrap(
          spacing: 8,
          children: [15, 30, 45, 60, 90, 120].map((m) => GestureDetector(onTap: () => setState(() => _duration = m), child: Chip2(fmtDurationShort(m), selected: _duration == m))).toList(),
        ),
        if (habits.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionLabel('LINK TO A HABIT (OPTIONAL)'),
          Wrap(
            spacing: 8,
            children: [
              GestureDetector(onTap: () => setState(() => _linkedHabit = null), child: Chip2('None', selected: _linkedHabit == null)),
              ...habits.map((h) => GestureDetector(onTap: () => setState(() => _linkedHabit = h.id), child: Chip2(h.name, selected: _linkedHabit == h.id, color: h.color))),
            ],
          ),
        ],
        const SizedBox(height: 24),
        PillButton(label: widget.existing == null ? 'Add to day' : 'Save changes', onTap: _save),
        if (widget.existing != null) ...[
          const SizedBox(height: 10),
          PillButton(label: 'Delete', filled: false, color: C.coral, onTap: _delete),
        ],
        const SizedBox(height: 6),
      ],
    );
  }
}
