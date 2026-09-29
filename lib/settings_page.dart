import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'data.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store, required this.onReset});
  final AppStore store;
  final VoidCallback onReset;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _name = TextEditingController(text: widget.store.settings.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Widget _row(String k, Widget v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(k, style: const TextStyle(fontSize: 14.5, color: C.text)), v]),
      );

  Widget _stepper(int value, int min, int max, void Function(int) onChange, {String Function(int)? fmt}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(visualDensity: VisualDensity.compact, onPressed: () => onChange((value - 1).clamp(min, max).toInt()), icon: const Icon(Icons.remove_circle_outline, color: C.mute, size: 20)),
          SizedBox(width: 44, child: Text(fmt != null ? fmt(value) : '$value', textAlign: TextAlign.center, style: const TextStyle(color: C.text, fontWeight: FontWeight.w600))),
          IconButton(visualDensity: VisualDensity.compact, onPressed: () => onChange((value + 1).clamp(min, max).toInt()), icon: const Icon(Icons.add_circle_outline, color: C.mute, size: 20)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final s = store.settings;

    return ListView(
      padding: pagePad,
      children: [
        const Reveal(child: Kicker('SETTINGS')),
        const SizedBox(height: 14),
        const Reveal(delayMs: 100, child: Text('Make it', style: h1Light)),
        const Reveal(delayMs: 180, child: Text('yours.', style: h1Bold)),
        const SizedBox(height: 24),
        const SectionLabel('PROFILE'),
        Reveal(
          delayMs: 260,
          child: Glass(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    style: const TextStyle(color: C.text, fontSize: 15),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Your name', hintStyle: TextStyle(color: C.mute)),
                    onSubmitted: (v) => store.updateSettings((x) => x.name = v.trim().isEmpty ? x.name : v.trim()),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    store.updateSettings((x) => x.name = _name.text.trim().isEmpty ? x.name : _name.text.trim());
                  },
                  icon: const Icon(Icons.check_rounded, color: C.lime),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('PLANNER'),
        Reveal(
          delayMs: 320,
          child: Glass(
            child: Column(
              children: [
                _row('Day starts', _stepper(s.dayStartHour, 0, 23, (v) => store.updateSettings((x) => x.dayStartHour = v), fmt: fmtHour)),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                _row('Day ends', _stepper(s.dayEndHour, 1, 24, (v) => store.updateSettings((x) => x.dayEndHour = v), fmt: (v) => fmtHour(v % 24))),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                _row(
                  'Slot size',
                  Row(
                    children: [15, 30, 60].map((m) {
                      final on = s.slotMinutes == m;
                      return Padding(padding: const EdgeInsets.only(left: 6), child: GestureDetector(onTap: () => store.updateSettings((x) => x.slotMinutes = m), child: Chip2('${m}m', selected: on)));
                    }).toList(),
                  ),
                ),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                _row(
                  'Week starts',
                  Row(children: [
                    GestureDetector(onTap: () => store.updateSettings((x) => x.weekStartsMonday = true), child: Chip2('Mon', selected: s.weekStartsMonday)),
                    const SizedBox(width: 6),
                    GestureDetector(onTap: () => store.updateSettings((x) => x.weekStartsMonday = false), child: Chip2('Sun', selected: !s.weekStartsMonday)),
                  ]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('NOTIFICATIONS'),
        Reveal(
          delayMs: 380,
          child: Glass(
            child: Column(
              children: [
                _row('Remind me about my plan', Switch(value: s.notificationsEnabled, activeColor: C.lime, onChanged: (v) => store.updateSettings((x) => x.notificationsEnabled = v))),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                _row('Lead time', _stepper(s.reminderLeadMinutes, 0, 60, (v) => store.updateSettings((x) => x.reminderLeadMinutes = v), fmt: (v) => '${v}m')),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Reminders are stored and ready — actual push alerts arrive next phase.', style: TextStyle(fontSize: 11.5, color: C.mute)),
        ),
        const SizedBox(height: 20),
        const SectionLabel('HABITS'),
        Reveal(
          delayMs: 440,
          child: Glass(child: _row('Haptics', Switch(value: s.hapticsEnabled, activeColor: C.lime, onChanged: (v) => store.updateSettings((x) => x.hapticsEnabled = v)))),
        ),
        const SizedBox(height: 20),
        const SectionLabel('APPEARANCE'),
        Reveal(
          delayMs: 500,
          child: Glass(
            child: Column(
              children: [
                _row(
                  'Aurora intensity',
                  Row(
                    children: ['Subtle', 'Normal', 'Vivid'].asMap().entries.map((e) {
                      final on = s.auroraLevel == e.key;
                      return Padding(padding: const EdgeInsets.only(left: 6), child: GestureDetector(onTap: () => store.updateSettings((x) => x.auroraLevel = e.key), child: Chip2(e.value, selected: on)));
                    }).toList(),
                  ),
                ),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: 6),
                const Align(alignment: Alignment.centerLeft, child: Text('Glass blur strength', style: TextStyle(fontSize: 14.5, color: C.text))),
                Slider(
                  value: s.glassBlur,
                  min: 8,
                  max: 36,
                  activeColor: C.lime,
                  inactiveColor: Colors.white.withValues(alpha: 0.15),
                  onChanged: (v) => store.updateSettings((x) => x.glassBlur = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('DATA'),
        Reveal(
          delayMs: 560,
          child: Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Backup and restore', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text)),
                const SizedBox(height: 6),
                const Text('Everything lives only on this phone. Export it before switching devices or reinstalling.', style: TextStyle(fontSize: 12.5, color: C.mute, height: 1.4)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: PillButton(label: 'Export', filled: false, onTap: () => _exportDialog(context, store))),
                    const SizedBox(width: 10),
                    Expanded(child: PillButton(label: 'Import', filled: false, onTap: () => _importDialog(context, store))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('ABOUT'),
        Reveal(
          delayMs: 620,
          child: Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Daybook · Phase 1', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
                SizedBox(height: 6),
                Text('Glass everywhere, a real Planner, a live Home now-line, and a finished Habits tab.', style: TextStyle(fontSize: 12.5, color: C.mute, height: 1.4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Reveal(
          delayMs: 680,
          child: Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start over', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text)),
                const SizedBox(height: 6),
                const Text('Replays the welcome flow. Your habits and plans stay put.', style: TextStyle(fontSize: 12.5, color: C.mute, height: 1.4)),
                const SizedBox(height: 14),
                PillButton(label: 'Replay welcome', filled: false, onTap: widget.onReset),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _exportDialog(BuildContext context, AppStore store) {
    final json = store.exportJson();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF17171D),
        title: const Text('Your backup', style: TextStyle(color: C.text)),
        content: SizedBox(width: double.maxFinite, child: SelectableText(json, style: const TextStyle(color: C.mute, fontSize: 11))),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(context);
            },
            child: const Text('Copy', style: TextStyle(color: C.lime)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: C.mute))),
        ],
      ),
    );
  }

  void _importDialog(BuildContext context, AppStore store) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF17171D),
        title: const Text('Restore a backup', style: TextStyle(color: C.text)),
        content: TextField(
          controller: controller,
          maxLines: 8,
          style: const TextStyle(color: C.text, fontSize: 12),
          decoration: const InputDecoration(hintText: 'Paste your backup JSON here', hintStyle: TextStyle(color: C.mute)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: C.mute))),
          TextButton(
            onPressed: () async {
              final ok = await store.importJson(controller.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Restored.' : 'That backup could not be read.')));
              }
            },
            child: const Text('Restore', style: TextStyle(color: C.lime)),
          ),
        ],
      ),
    );
  }
}
