import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'data.dart';
import 'versind_widgets.dart';

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

  /// All six accent swatches on ONE row, sized to the space available, so none (Blue was the one
  /// getting cut off) can ever run past the card edge. Each swatch has a full-height tap area.
  Widget _accentRow(AppStore store, AppSettings s) {
    return LayoutBuilder(
      builder: (context, cons) {
        const gap = 10.0;
        final n = Accent.presets.length;
        final d = ((cons.maxWidth - gap * (n - 1)) / n).clamp(28.0, 44.0).toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(n, (i) {
            final c = Accent.presets[i];
            final on = c.value == s.accentValue;
            return Semantics(
              button: true,
              selected: on,
              label: '${Accent.names[i]} accent',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  store.updateSettings((x) => x.accentValue = c.value);
                },
                child: SizedBox(
                  width: d,
                  height: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: d,
                      height: d,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: on ? Colors.white : Colors.transparent, width: 3),
                        boxShadow: on ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 14)] : [],
                      ),
                      child: on ? Icon(Icons.check_rounded, color: C.base, size: d * 0.45) : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

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
                  tooltip: 'Save name',
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
        const SectionLabel('ACCENT COLOUR'),
        Reveal(
          delayMs: 300,
          child: Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Colours your buttons, rings and highlights everywhere.', style: TextStyle(fontSize: 12.5, color: C.mute)),
                const SizedBox(height: 10),
                _accentRow(store, s),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('PLANNER'),
        Reveal(
          delayMs: 340,
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
          child: Text('Habit reminders follow this switch. Set reminder times inside each habit.', style: TextStyle(fontSize: 11.5, color: C.mute)),
        ),
        const SizedBox(height: 20),
        const SectionLabel('HABITS'),
        Reveal(
          delayMs: 420,
          child: Glass(child: _row('Haptics', Switch(value: s.hapticsEnabled, activeColor: C.lime, onChanged: (v) => store.updateSettings((x) => x.hapticsEnabled = v)))),
        ),
        const SizedBox(height: 20),
        const SectionLabel('BACKGROUND'),
        Reveal(delayMs: 440, child: BackgroundSettingsCard(store: store)),
        const SizedBox(height: 20),
        const SectionLabel('APPEARANCE'),
        Reveal(
          delayMs: 460,
          child: Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Glass style', style: TextStyle(fontSize: 14.5, color: C.text)),
                const SizedBox(height: 4),
                const Text('Frosted: softer, more opaque. Liquid Clear: higher transparency, crisper edges.', style: TextStyle(fontSize: 11.5, color: C.mute)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(onTap: () => store.updateSettings((x) => x.glassStyleIndex = 0), child: Chip2('Frosted', selected: s.glassStyleIndex == 0)),
                    const SizedBox(width: 8),
                    GestureDetector(onTap: () => store.updateSettings((x) => x.glassStyleIndex = 1), child: Chip2('Liquid Clear', selected: s.glassStyleIndex == 1)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: 10),
                const Text('Aurora intensity', style: TextStyle(fontSize: 14.5, color: C.text)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Subtle', 'Normal', 'Vivid'].asMap().entries.map((e) {
                    final on = s.auroraLevel == e.key;
                    return GestureDetector(onTap: () => store.updateSettings((x) => x.auroraLevel = e.key), child: Chip2(e.value, selected: on));
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: 10),
                const Text('Glass blur strength', style: TextStyle(fontSize: 14.5, color: C.text)),
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
          delayMs: 500,
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
          delayMs: 540,
          child: Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Versind · v1.0.8', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
                SizedBox(height: 6),
                Text('Motion update: a cinematic welcome, your choice of background, connected habit streaks and a wavy consistency line.', style: TextStyle(fontSize: 12.5, color: C.mute, height: 1.4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Reveal(
          delayMs: 580,
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
