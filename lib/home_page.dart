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
    final quote = quoteForToday();

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
        const SizedBox(height: 22),
        Reveal(delayMs: 320, child: const HomeDayStrip()),
        const SizedBox(height: 20),
        Reveal(
          delayMs: 420,
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
                    onTap: () {
                      HapticFeedback.mediumImpact();
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
          delayMs: 500,
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
            delayMs: 560,
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
          const Reveal(delayMs: 600, child: SectionLabel("TODAY'S HABITS")),
          Reveal(
            delayMs: 660,
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
          delayMs: 720,
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

class HomeDayStrip extends StatelessWidget {
  const HomeDayStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(const Duration(days: 3)).add(Duration(days: i)));
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final d = days[i];
          final today = dayKey(d) == dayKey(now);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(weekdayShort(d.weekday).substring(0, 1), style: TextStyle(fontSize: 10.5, color: today ? Accent.color : C.mute, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: today ? Accent.color : Colors.white.withValues(alpha: 0.06),
                  border: today ? null : Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  boxShadow: today ? [BoxShadow(color: Accent.color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))] : [],
                ),
                child: Text('${d.day}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: today ? C.base : C.text)),
              ),
            ],
          );
        },
      ),
    );
  }
}
