import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'data.dart';

typedef DueCheck = bool Function(Habit h, DateTime day);

/// Habit reminders on Android.
///
/// ID scheme: every habit owns a block of 200 notification ids,
/// `habit.notifBase * 200 .. +199`, so cancelling a habit's reminders can never
/// touch another habit's and re-scheduling can never leave duplicates behind.
///   daily / N-per-week : base + r*8
///   chosen weekdays    : base + r*8 + weekday (1..7)
///   every N days       : base + 40 + r*32 + dayOffset (0..30)
/// where r is the index of the reminder time (max [maxReminders]).
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const String _channelId = 'habit_reminders_v1';
  static const int _block = 200;
  static const int maxReminders = 5;
  static const int _testId = 2147000000;
  static const int _horizonDays = 30;

  static bool get supported => Platform.isAndroid;

  // ───────────────────────── setup ─────────────────────────

  static Future<void> init() async {
    if (_ready || !supported) return;
    try {
      tzdata.initializeTimeZones();
      await _setLocalZone();
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      );
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        'Habit reminders',
        description: 'Gentle reminders for your habits',
        importance: Importance.high,
      ));
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  static Future<void> _setLocalZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fallback: pick any zone that has the phone's current UTC offset.
      final off = DateTime.now().timeZoneOffset;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (tz.TZDateTime.now(loc).timeZoneOffset == off) {
          tz.setLocalLocation(loc);
          break;
        }
      }
    }
  }

  // ─────────────────────── permissions ───────────────────────

  /// Shows the Android 13+ permission dialog if needed. Returns true if allowed.
  static Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == true) return true;
      return await android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> allowed() async {
    if (!supported) return false;
    await init();
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<AndroidScheduleMode> _mode() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final can = await android?.canScheduleExactNotifications() ?? false;
      return can ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  // ───────────────────────── public API ─────────────────────────

  /// Immediate notification so the user can confirm delivery works.
  /// Returns false if notifications are blocked.
  static Future<bool> sendTest() async {
    if (!await requestPermission()) return false;
    try {
      await _plugin.show(
        id: _testId,
        title: 'Reminders are working',
        body: 'This is how your habit reminders will look.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Habit reminders',
            channelDescription: 'Gentle reminders for your habits',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('sendTest failed: $e');
      return false;
    }
  }

  /// Cancels every pending reminder that belongs to [h].
  static Future<void> cancelHabit(Habit h) async {
    if (!supported || h.notifBase <= 0) return;
    await init();
    if (!_ready) return;
    final lo = h.notifBase * _block;
    final hi = lo + _block;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id >= lo && p.id < hi) await _plugin.cancel(id: p.id);
      }
    } catch (_) {
      for (int i = lo; i < hi; i++) {
        try {
          await _plugin.cancel(id: i);
        } catch (_) {}
      }
    }
  }

  /// Replace [h]'s schedule: cancel the old one, then schedule the current one.
  static Future<void> syncHabit(Habit h, AppSettings s, DueCheck due) async {
    if (!supported) return;
    await init();
    if (!_ready) return;
    await cancelHabit(h);
    await _schedule(h, s, due, await _mode(), await allowed());
  }

  /// Rebuild every habit's schedule from scratch (app start, master toggle, import).
  static Future<void> syncAll(List<Habit> habits, AppSettings s, DueCheck due) async {
    if (!supported) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (_) {}
    final mode = await _mode();
    final ok = await allowed();
    for (final h in habits) {
      await _schedule(h, s, due, mode, ok);
    }
  }

  // ───────────────────────── internals ─────────────────────────

  static Future<void> _schedule(Habit h, AppSettings s, DueCheck due, AndroidScheduleMode mode, bool permitted) async {
    if (!permitted || !s.notificationsEnabled || h.reminders.isEmpty || h.notifBase <= 0) return;
    final base = h.notifBase * _block;
    final times = (h.reminders.toSet().toList()..sort()).take(maxReminders).toList();
    final now = tz.TZDateTime.now(tz.local);

    for (int r = 0; r < times.length; r++) {
      final m = times[r];
      switch (h.repeatType) {
        case 'weekdays':
          for (final w in h.weekdays.toSet()) {
            if (w < 1 || w > 7) continue;
            var c = _at(now, m);
            for (int i = 0; i < 8; i++) {
              final cand = c.add(Duration(days: i));
              if (cand.weekday == w && cand.isAfter(now)) {
                await _zoned(base + r * 8 + w, h, cand, mode, DateTimeComponents.dayOfWeekAndTime);
                break;
              }
            }
          }
          break;
        case 'everyNDays':
          for (int i = 0; i <= _horizonDays; i++) {
            final day = now.add(Duration(days: i));
            final cand = _at(day, m);
            if (cand.isAfter(now) && due(h, day)) {
              await _zoned(base + 40 + r * 32 + i, h, cand, mode, null);
            }
          }
          break;
        default: // daily and N-per-week
          var c = _at(now, m);
          if (!c.isAfter(now)) c = c.add(const Duration(days: 1));
          await _zoned(base + r * 8, h, c, mode, DateTimeComponents.time);
      }
    }
  }

  static tz.TZDateTime _at(tz.TZDateTime day, int minutes) =>
      tz.TZDateTime(tz.local, day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

  static String _body(Habit h) {
    if (h.description.trim().isNotEmpty) return h.description.trim();
    switch (h.type) {
      case 'avoid':
        return 'Stay steady today.';
      case 'amount':
        return 'Time to add to today\'s ${h.amountUnit.isEmpty ? 'goal' : h.amountUnit}.';
      default:
        return 'A small step now keeps the streak alive.';
    }
  }

  static Future<void> _zoned(int id, Habit h, tz.TZDateTime when, AndroidScheduleMode mode, DateTimeComponents? match) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Habit reminders',
        channelDescription: 'Gentle reminders for your habits',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        color: h.color,
        ticker: h.name,
      ),
    );
    Future<void> go(AndroidScheduleMode m) => _plugin.zonedSchedule(
          id: id,
          title: h.name,
          body: _body(h),
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: m,
          payload: h.id,
          matchDateTimeComponents: match,
        );
    try {
      await go(mode);
    } catch (e) {
      // Exact alarms can be revoked by the user; fall back to inexact so the reminder still fires.
      try {
        await go(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (e2) {
        debugPrint('schedule failed for ${h.name}: $e2');
      }
    }
  }
}
