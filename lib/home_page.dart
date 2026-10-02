import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'core.dart';
import 'data.dart';
import 'versind_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store, this.onOpenHabits});
  final AppStore store;
  final VoidCallback? onOpenHabits;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey _rightNowKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final now = DateTime.now();
    final h = now.hour;
    final part = (h >= 21 || h < 4) ? 3 : (h < 12 ? 0 : (h < 17 ? 1 : 2));
    const greet = ['Good morning,', 'Good afternoon,', 'Good evening,', 'Still up,'];
    final quote = quoteForToday();

    final nowMinutes = now.hour * 60 + now.minute;
    final blocksToday = store.blocksOn(now);
    final current = blocksToday.where((b) => nowMinutes >= b.startMinutes && nowMinutes < b.startMinutes + b.durationMinutes).toList();
    final upcoming = blocksToday.where((b) => b.startMinutes > nowMinutes).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final justDone = blocksToday.where((b) => b.startMinutes + b.durationMinutes <= nowMinutes).toList();
    // today's habits, unfinished first so the next thing to do is always on top
    final dueToday = store.habits.where((hb) => store.isDue(hb, now)).toList()
      ..sort((a, b) {
        final da = store.successOn(a, now) ? 1 : 0;
        final db = store.successOn(b, now) ? 1 : 0;
        return da.compareTo(db);
      });
    final pending = dueToday.where((hb) => !store.successOn(hb, now)).toList();

    final week = List.generate(7, (i) => now.subtract(Duration(days: now.weekday - 1 - i)));
    final todayIndex = now.weekday - 1;

    return ListView(
      padding: pagePad,
      children: [
        Reveal(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Kicker(dateLabel(now)),
                    const SizedBox(height: 14),
                    Text(greet[part], style: h1Light),
                    Text('${store.settings.name}.', maxLines: 2, overflow: TextOverflow.ellipsis, style: h1Bold),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              ProfileAvatar(store: store),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Reveal(delayMs: 200, child: DatePanel(days: week, selectedIndex: todayIndex)),
        const SizedBox(height: 20),
        Reveal(
          delayMs: 320,
          child: SolidCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: C.base.withValues(alpha: 0.18), shape: BoxShape.circle),
                  child: Icon(current.isNotEmpty ? Icons.bolt_rounded : Icons.wb_sunny_rounded, color: C.base, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RIGHT NOW', style: TextStyle(fontSize: 11.5, letterSpacing: 2, fontWeight: FontWeight.w700, color: C.base.withValues(alpha: 0.6))),
                      const SizedBox(height: 6),
                      if (current.isNotEmpty) ...[
                        Text(current.first.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: C.base)),
                        const SizedBox(height: 4),
                        Text(
                          '${fmtMinutes(current.first.startMinutes)} – ${fmtMinutes(current.first.startMinutes + current.first.durationMinutes)}',
                          style: TextStyle(fontSize: 12.5, color: C.base.withValues(alpha: 0.7)),
                        ),
                      ] else if (upcoming.isNotEmpty) ...[
                        Text('Free until ${fmtMinutes(upcoming.first.startMinutes)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.base)),
                        const SizedBox(height: 4),
                        Text('Next: ${upcoming.first.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: C.base.withValues(alpha: 0.7))),
                      ] else ...[
                        const Text('Nothing planned yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.base)),
                        Text('Open Planner to shape your day.', style: TextStyle(fontSize: 12.5, color: C.base.withValues(alpha: 0.7))),
                      ],
                    ],
                  ),
                ),
                if (current.isNotEmpty)
                  GestureDetector(
                    key: _rightNowKey,
                    onTap: () {
                      final wasDone = current.first.done;
                      HapticFeedback.mediumImpact();
                      if (!wasDone) fireCompletionBurst(context, _rightNowKey, priorityColor(current.first.priority));
                      store.toggleBlock(current.first);
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(color: C.base, shape: BoxShape.circle),
                      child: Icon(current.first.done ? Icons.check_rounded : Icons.play_arrow_rounded, color: store.settings.accent),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Reveal(
          delayMs: 400,
          child: Glass(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded, color: store.settings.accent, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quote.text, style: const TextStyle(fontSize: 14, height: 1.5, fontStyle: FontStyle.italic, color: C.text)),
                      const SizedBox(height: 8),
                      Text('— ${quote.author}', style: const TextStyle(fontSize: 12, color: C.mute)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (justDone.isNotEmpty) ...[
          const SizedBox(height: 14),
          Reveal(
            delayMs: 460,
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: C.mute),
                const SizedBox(width: 8),
                Expanded(child: Text('Just finished: ${justDone.last.title}', style: const TextStyle(fontSize: 12.5, color: C.mute))),
              ],
            ),
          ),
        ],
        if (dueToday.isNotEmpty) ...[
          const SizedBox(height: 16),
          Reveal(delayMs: 500, child: _PendingHabits(pending: pending, total: dueToday.length, onTap: widget.onOpenHabits)),
        ],
        const SizedBox(height: 8),
        Reveal(
          delayMs: 620,
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

/// Circular profile-picture slot, top-right of the greeting.
/// Tap to pick from the gallery; the image is copied into the app's own
/// storage so it survives cache clears. Falls back to initials, then a
/// placeholder icon.
class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key, required this.store});
  final AppStore store;
  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 640, imageQuality: 85);
      if (img == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final ext = img.path.contains('.') ? img.path.split('.').last : 'jpg';
      final dest = '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(img.path).copy(dest);
      await widget.store.updateSettings((s) => s.profilePicturePath = dest);
    } catch (_) {
      // Silently ignore — picker cancellation or platform quirk.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.store.settings.profilePicturePath;
    final hasImage = path != null && File(path).existsSync();
    final name = widget.store.settings.name.trim();
    final initials = name.isEmpty ? '' : name[0].toUpperCase();

    return Semantics(
      button: true,
      label: 'Profile picture',
      child: GestureDetector(
        onTap: _pick,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24), width: 1.4),
            image: hasImage ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover) : null,
          ),
          child: hasImage
              ? null
              : (initials.isEmpty
                  ? const Icon(Icons.person_rounded, color: C.mute, size: 24)
                  : Text(initials, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: C.text))),
        ),
      ),
    );
  }
}

/// A short reminder, not the habit blocks themselves: how many habits are still open today.
class _PendingHabits extends StatelessWidget {
  const _PendingHabits({required this.pending, required this.total, this.onTap});
  final List<Habit> pending;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final allDone = pending.isEmpty;
    final names = pending.take(3).map((e) => e.name).join(' · ');
    final extra = pending.length > 3 ? '  +${pending.length - 3}' : '';
    return Semantics(
      button: onTap != null,
      label: allDone ? 'All habits done today' : '${pending.length} habits pending today',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Glass(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (allDone)
                const Icon(Icons.check_circle_rounded, color: C.lime, size: 30)
              else
                SizedBox(
                  width: 30.0 + (pending.take(3).length - 1) * 18,
                  height: 34,
                  child: Stack(
                    children: [
                      for (int i = pending.take(3).length - 1; i >= 0; i--)
                        Positioned(
                          left: i * 18.0,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: Color.alphaBlend(pending[i].color.withValues(alpha: 0.28), const Color(0xFF111116)), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF111116), width: 2)),
                            child: Icon(pending[i].icon, color: pending[i].color, size: 17),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    allDone
                        ? const Text('All habits done today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text))
                        : Row(children: [
                            CountUp(value: pending.length, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.lime)),
                            Text(pending.length == 1 ? ' habit still to do' : ' habits still to do', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
                          ]),
                    const SizedBox(height: 3),
                    Text(allDone ? 'Nice work — see you tomorrow.' : '$names$extra', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: C.mute)),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right_rounded, color: C.mute),
            ],
          ),
        ),
      ),
    );
  }
}
