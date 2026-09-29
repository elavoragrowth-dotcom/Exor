import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'data.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key, required this.store});
  final AppStore store;
  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  DateTime _selected = DateTime.now();
  final ScrollController _scroll = ScrollController();
  static const double hourHeight = 76;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  void _scrollToNow() {
    final s = widget.store.settings;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = s.dayStartHour * 60;
    final offset = ((nowMin - startMin) / 60 * hourHeight - 200).clamp(0, double.infinity);
    if (_scroll.hasClients) _scroll.jumpTo(offset.toDouble());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<DateTime> _weekAround(DateTime d) {
    final start = d.subtract(Duration(days: d.weekday - 1));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final s = store.settings;
    final week = _weekAround(_selected);
    final blocks = store.blocksOn(_selected);
    final totalHours = (s.dayEndHour - s.dayStartHour).clamp(1, 24);
    final now = DateTime.now();
    final isToday = dayKey(now) == dayKey(_selected);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Reveal(child: Kicker(_selected.year == now.year ? 'THIS WEEK' : '${_selected.year}')),
              const SizedBox(height: 10),
              const Reveal(delayMs: 100, child: Text('Shape your', style: h1Light)),
              const Reveal(delayMs: 180, child: Text('day.', style: h1Bold)),
              const SizedBox(height: 16),
              Reveal(
                delayMs: 260,
                child: Row(
                  children: week.map((d) {
                    final on = dayKey(d) == dayKey(_selected);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selected = d);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: on ? C.lime : Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(18)),
                          child: Column(
                            children: [
                              Text(weekdayShort(d.weekday).substring(0, 1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: on ? C.base : C.mute)),
                              const SizedBox(height: 4),
                              Text('${d.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: on ? C.base : C.text)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 140),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _createAt(context, d.localPosition.dy),
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
                            SizedBox(width: 52, child: Text(fmtHour(s.dayStartHour + i), style: const TextStyle(fontSize: 10.5, color: C.mute))),
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
                          onTap: () => _editBlock(context, b),
                          child: BlockCard(block: b, onToggle: () => store.toggleBlock(b)),
                        ),
                      ),
                    if (isToday)
                      Positioned(
                        top: (now.hour * 60 + now.minute - s.dayStartHour * 60) / 60 * hourHeight,
                        left: 52,
                        right: 0,
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle)),
                            Expanded(child: Container(height: 1.4, color: C.lime.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _createAt(BuildContext context, double y) {
    final s = widget.store.settings;
    final rawMinutes = s.dayStartHour * 60 + (y / hourHeight * 60);
    final slot = s.slotMinutes == 0 ? 30 : s.slotMinutes;
    final snapped = (rawMinutes / slot).round() * slot;
    showGlassSheet(context, BlockEditor(store: widget.store, date: _selected, initialStart: snapped.clamp(0, 23 * 60 + 45).toInt()));
  }

  void _editBlock(BuildContext context, PlannerBlock b) {
    showGlassSheet(context, BlockEditor(store: widget.store, date: _selected, existing: b));
  }
}

class BlockCard extends StatelessWidget {
  const BlockCard({super.key, required this.block, required this.onToggle});
  final PlannerBlock block;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(block.category);
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
                Text('${fmtMinutes(block.startMinutes)} · ${fmtDurationShort(block.durationMinutes)}', style: const TextStyle(fontSize: 10.5, color: C.mute)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
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
  late int _start = widget.existing?.startMinutes ?? widget.initialStart ?? 8 * 60;
  int _duration = 30;
  String? _linkedHabit;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? 'Study';
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
      b.startMinutes = _start;
      b.durationMinutes = _duration;
      b.linkedHabitId = _linkedHabit;
      await widget.store.updateBlock(b);
    } else {
      final b = PlannerBlock(
        id: newId(),
        title: _title.text.trim(),
        category: _category,
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
