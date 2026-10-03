import 'dart:math' as math;
import 'core.dart';
import 'data.dart';

/// Evening cutoff after which an unfinished day counts as "at risk".
const int kEveningCutoffHour = 20;

/// A day is a "streak day" when at least this share of the habits due that day is finished,
/// or at least one planner block is done. Avoid-habits never count (they succeed by default
/// on days you never opened the app, which would inflate every number).
const double kStreakDayShare = 0.5;

const List<int> kStreakMilestones = [3, 7, 14, 30, 60, 100, 365];

enum DayKind { done, miss, neutral, pending, future }

class DayStat {
  const DayStat({required this.date, required this.due, required this.done, required this.focusSeconds, required this.blocksDone, required this.kind});
  final DateTime date;
  final int due, done, focusSeconds, blocksDone;
  final DayKind kind;
  double get ratio => due == 0 ? 0 : done / due;
  bool get perfect => due > 0 && done >= due;
}

class PeriodStats {
  const PeriodStats(this.due, this.done, this.focusSeconds, this.perfectDays);
  final int due, done, focusSeconds, perfectDays;
  double get rate => due == 0 ? 0 : done / due;
  bool get hasData => due > 0;
}

/// One daily aggregate, computed once per store change instead of scanning logs on every build.
class StatsSnapshot {
  StatsSnapshot._({
    required this.days,
    required this.today,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompletions,
    required this.totalFocusSeconds,
    required this.bestPerfectRun,
    required this.hadComeback,
    required this.todayPending,
  });

  final Map<String, DayStat> days;
  final DateTime today;
  final int currentStreak, bestStreak, totalCompletions, totalFocusSeconds, bestPerfectRun;
  final bool hadComeback, todayPending;

  DayStat statOn(DateTime d) {
    final day = dateOnly(d);
    final hit = days[dayKey(day)];
    if (hit != null) return hit;
    return DayStat(date: day, due: 0, done: 0, focusSeconds: 0, blocksDone: 0, kind: day.isAfter(today) ? DayKind.future : DayKind.neutral);
  }

  /// The [n] days ending on [end] (inclusive).
  PeriodStats period(DateTime end, int n) {
    int due = 0, done = 0, focus = 0, perfect = 0;
    for (int i = 0; i < n; i++) {
      final st = statOn(DateTime(end.year, end.month, end.day - i));
      due += st.due;
      done += st.done;
      focus += st.focusSeconds;
      if (st.perfect) perfect++;
    }
    return PeriodStats(due, done, focus, perfect);
  }

  static StatsSnapshot compute(AppStore s) {
    final today = dateOnly(DateTime.now());

    final idx = <String, HabitLog>{};
    int focusTotal = 0;
    for (final l in s.logs) {
      idx['${l.habitId}|${l.date}'] = l;
      focusTotal += l.focusSeconds;
    }
    final blocksDone = <String, int>{};
    for (final b in s.blocks) {
      if (b.done) blocksDone[b.date] = (blocksDone[b.date] ?? 0) + 1;
    }

    // first day we have anything for, capped at ~800 days so the work stays small
    DateTime first = today;
    for (final h in s.habits) {
      final c = dateOnly(h.createdAt);
      if (c.isBefore(first)) first = c;
    }
    for (final l in s.logs) {
      final d = DateTime.tryParse(l.date);
      if (d != null && dateOnly(d).isBefore(first)) first = dateOnly(d);
    }
    final floor = DateTime(today.year, today.month, today.day - 799);
    if (first.isBefore(floor)) first = floor;

    final days = <String, DayStat>{};
    final ordered = <DayStat>[];
    int totalDone = 0;

    for (var d = first; !d.isAfter(today); d = DateTime(d.year, d.month, d.day + 1)) {
      final key = dayKey(d);
      int due = 0, done = 0, fs = 0;
      for (final h in s.habits) {
        final l = idx['${h.id}|$key'];
        if (l != null) fs += l.focusSeconds;
        if (h.type == 'avoid') continue;
        if (d.isBefore(dateOnly(h.createdAt))) continue;
        final ok = l != null && (h.type == 'amount' ? l.amount >= h.amountGoal : l.done);
        if (h.repeatType == 'timesPerWeek') {
          // "N per week" habits only count on days you actually do them
          if (ok) {
            due++;
            done++;
          }
        } else if (s.isDue(h, d)) {
          due++;
          if (ok) done++;
        }
      }
      totalDone += done;
      final bd = blocksDone[key] ?? 0;
      final share = due == 0 ? 0.0 : done / due;
      final streakDay = (due > 0 && share >= kStreakDayShare) || bd > 0;

      DayKind kind;
      if (streakDay) {
        kind = DayKind.done;
      } else if (due == 0) {
        kind = DayKind.neutral;
      } else if (d == today) {
        kind = DayKind.pending;
      } else {
        kind = DayKind.miss;
      }
      final st = DayStat(date: d, due: due, done: done, focusSeconds: fs, blocksDone: bd, kind: kind);
      days[key] = st;
      ordered.add(st);
    }

    int best = 0, run = 0, perfectRun = 0, bestPerfect = 0, missRun = 0;
    bool comeback = false;
    for (final st in ordered) {
      switch (st.kind) {
        case DayKind.done:
          if (missRun >= 3) comeback = true;
          missRun = 0;
          run++;
          best = math.max(best, run);
          break;
        case DayKind.miss:
          run = 0;
          missRun++;
          break;
        case DayKind.neutral:
        case DayKind.pending:
        case DayKind.future:
          break; // rest days and today-in-progress neither extend nor break a streak
      }
      if (st.perfect) {
        perfectRun++;
        bestPerfect = math.max(bestPerfect, perfectRun);
      } else if (st.kind == DayKind.done || st.kind == DayKind.miss) {
        perfectRun = 0;
      }
    }

    return StatsSnapshot._(
      days: days,
      today: today,
      currentStreak: run,
      bestStreak: best,
      totalCompletions: totalDone,
      totalFocusSeconds: focusTotal,
      bestPerfectRun: bestPerfect,
      hadComeback: comeback,
      todayPending: ordered.isNotEmpty && ordered.last.kind == DayKind.pending,
    );
  }
}

class StatsEngine {
  StatsEngine._();
  static AppStore? _store;
  static int _version = -1;
  static DateTime? _day;
  static StatsSnapshot? _snap;

  static StatsSnapshot of(AppStore s) {
    final today = dateOnly(DateTime.now());
    final cached = _snap;
    if (cached != null && identical(_store, s) && _version == s.version && _day == today) return cached;
    final snap = StatsSnapshot.compute(s);
    _store = s;
    _version = s.version;
    _day = today;
    _snap = snap;
    return snap;
  }
}

// ───────────────────────── achievements ─────────────────────────

enum AchKind { streak, volume, focus, behavior }

class AchievementDef {
  const AchievementDef({required this.id, required this.kind, required this.target, required this.title, required this.blurb, required this.unit});
  final String id, title, blurb, unit;
  final AchKind kind;
  final int target;

  double valueIn(StatsSnapshot s) {
    if (id == 'perfect_week') return s.bestPerfectRun.toDouble();
    if (id == 'comeback') return s.hadComeback ? 1.0 : 0.0;
    switch (kind) {
      case AchKind.streak:
        return s.bestStreak.toDouble();
      case AchKind.volume:
        return s.totalCompletions.toDouble();
      case AchKind.focus:
        return s.totalFocusSeconds / 3600;
      case AchKind.behavior:
        return 0.0;
    }
  }

  double fractionIn(StatsSnapshot s) => (valueIn(s) / target).clamp(0.0, 1.0).toDouble();
  bool earnedIn(StatsSnapshot s) => valueIn(s) >= target;
}

final List<AchievementDef> kAchievements = [
  for (final n in kStreakMilestones)
    AchievementDef(id: 'streak_$n', kind: AchKind.streak, target: n, unit: 'days', title: '$n-day streak', blurb: 'Keep a streak alive for $n days.'),
  for (final n in const [10, 50, 100, 500])
    AchievementDef(id: 'done_$n', kind: AchKind.volume, target: n, unit: 'done', title: '$n completions', blurb: 'Finish habits $n times.'),
  for (final n in const [1, 10, 50, 100])
    AchievementDef(id: 'focus_$n', kind: AchKind.focus, target: n, unit: n == 1 ? 'hour' : 'hours', title: '${n}h of focus', blurb: 'Log $n ${n == 1 ? 'hour' : 'hours'} of focus time.'),
  const AchievementDef(id: 'perfect_week', kind: AchKind.behavior, target: 7, unit: 'days', title: 'Perfect week', blurb: 'Seven perfect days in a row.'),
  const AchievementDef(id: 'comeback', kind: AchKind.behavior, target: 1, unit: '', title: 'Comeback', blurb: 'Get back on track after three missed days.'),
];
