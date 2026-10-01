import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core.dart';
import 'notifications.dart';

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

class ChecklistItem {
  ChecklistItem({required this.id, required this.title});
  final String id;
  String title;
  Map<String, dynamic> toJson() => {'id': id, 'title': title};
  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(id: '${j['id']}', title: '${j['title'] ?? ''}');
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.iconIndex,
    required this.colorValue,
    required this.repeatType,
    this.weekdays = const [],
    this.timesPerWeek = 3,
    this.everyNDays = 2,
    this.plannedMinutes,
    this.focusTargetMinutes,
    this.category = 'Study',
    this.type = 'normal',
    this.amountUnit = '',
    this.amountGoal = 1,
    required this.createdAt,
    this.description = '',
    List<ChecklistItem>? checklist,
    this.coverImagePath,
    List<int>? reminders,
    this.focusEnabled = true,
    this.notifBase = 0,
  })  : checklist = checklist ?? <ChecklistItem>[],
        reminders = reminders ?? <int>[];

  final String id;
  String name;
  int iconIndex;
  int colorValue;
  String repeatType;
  List<int> weekdays;
  int timesPerWeek;
  int everyNDays;
  int? plannedMinutes;
  int? focusTargetMinutes;
  String category;
  String type; // 'normal' | 'avoid' | 'amount'
  String amountUnit;
  double amountGoal;
  final DateTime createdAt;

  // ── added in v1.1.0 — all optional, so older saved habits load unchanged ──
  String description;
  List<ChecklistItem> checklist;
  String? coverImagePath; // per-habit cover image (never a global background)
  List<int> reminders; // minutes since midnight
  bool focusEnabled;
  int notifBase; // owns notification ids notifBase*200 .. +199

  Color get color => Color(colorValue);
  IconData get icon => habitIcons[iconIndex % habitIcons.length];

  /// A checklist only applies to normal habits that actually have steps.
  bool get hasChecklist => type == 'normal' && checklist.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconIndex': iconIndex,
        'colorValue': colorValue,
        'repeatType': repeatType,
        'weekdays': weekdays,
        'timesPerWeek': timesPerWeek,
        'everyNDays': everyNDays,
        'plannedMinutes': plannedMinutes,
        'focusTargetMinutes': focusTargetMinutes,
        'category': category,
        'type': type,
        'amountUnit': amountUnit,
        'amountGoal': amountGoal,
        'createdAt': createdAt.toIso8601String(),
        'description': description,
        'checklist': checklist.map((e) => e.toJson()).toList(),
        'coverImagePath': coverImagePath,
        'reminders': reminders,
        'focusEnabled': focusEnabled,
        'notifBase': notifBase,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'],
        name: j['name'],
        iconIndex: j['iconIndex'] ?? 0,
        colorValue: j['colorValue'] ?? C.lime.value,
        repeatType: j['repeatType'] ?? 'daily',
        weekdays: (j['weekdays'] as List?)?.map((e) => e as int).toList() ?? const [],
        timesPerWeek: j['timesPerWeek'] ?? 3,
        everyNDays: j['everyNDays'] ?? 2,
        plannedMinutes: j['plannedMinutes'],
        focusTargetMinutes: j['focusTargetMinutes'],
        category: j['category'] ?? 'Study',
        type: j['type'] ?? 'normal',
        amountUnit: j['amountUnit'] ?? '',
        amountGoal: (j['amountGoal'] ?? 1).toDouble(),
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        description: j['description'] ?? '',
        checklist: (j['checklist'] as List?)?.map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        coverImagePath: j['coverImagePath'],
        reminders: (j['reminders'] as List?)?.map((e) => (e as num).toInt()).toList(),
        focusEnabled: j['focusEnabled'] ?? true,
        notifBase: j['notifBase'] ?? 0,
      );
}

class HabitLog {
  HabitLog({required this.habitId, required this.date, this.done = false, this.focusSeconds = 0, this.amount = 0, this.note, List<String>? steps})
      : steps = steps ?? <String>[];
  final String habitId;
  final String date;
  bool done;
  int focusSeconds;
  double amount;
  String? note;
  List<String> steps; // ids of checklist steps ticked that day

  Map<String, dynamic> toJson() => {'habitId': habitId, 'date': date, 'done': done, 'focusSeconds': focusSeconds, 'amount': amount, 'note': note, 'steps': steps};
  factory HabitLog.fromJson(Map<String, dynamic> j) => HabitLog(
        habitId: j['habitId'],
        date: j['date'],
        done: j['done'] ?? false,
        focusSeconds: j['focusSeconds'] ?? 0,
        amount: (j['amount'] ?? 0).toDouble(),
        note: j['note'],
        steps: (j['steps'] as List?)?.map((e) => '$e').toList(),
      );
}

class PlannerBlock {
  PlannerBlock({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.startMinutes,
    required this.durationMinutes,
    this.linkedHabitId,
    this.done = false,
    this.priority = 'medium',
  });
  final String id;
  String title;
  String category;
  String date;
  int startMinutes;
  int durationMinutes;
  String? linkedHabitId;
  bool done;
  String priority;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'date': date,
        'startMinutes': startMinutes,
        'durationMinutes': durationMinutes,
        'linkedHabitId': linkedHabitId,
        'done': done,
        'priority': priority,
      };
  factory PlannerBlock.fromJson(Map<String, dynamic> j) => PlannerBlock(
        id: j['id'],
        title: j['title'],
        category: j['category'] ?? 'Other',
        date: j['date'],
        startMinutes: j['startMinutes'] ?? 480,
        durationMinutes: j['durationMinutes'] ?? 30,
        linkedHabitId: j['linkedHabitId'],
        done: j['done'] ?? false,
        priority: j['priority'] ?? 'medium',
      );
}

class AppSettings {
  AppSettings({
    this.name = '',
    this.dayStartHour = 6,
    this.dayEndHour = 23,
    this.slotMinutes = 30,
    this.weekStartsMonday = true,
    this.notificationsEnabled = true,
    this.reminderLeadMinutes = 10,
    this.hapticsEnabled = true,
    this.auroraLevel = 1,
    this.glassBlur = 24,
    this.accentValue = 0xFFD4F25C,
    this.glassStyleIndex = 0,
    this.profilePicturePath,
  });
  String name;
  int dayStartHour, dayEndHour, slotMinutes, reminderLeadMinutes, auroraLevel, glassStyleIndex;
  bool weekStartsMonday, notificationsEnabled, hapticsEnabled;
  double glassBlur;
  int accentValue;
  String? profilePicturePath;

  Color get accent => Color(accentValue);

  Map<String, dynamic> toJson() => {
        'name': name,
        'dayStartHour': dayStartHour,
        'dayEndHour': dayEndHour,
        'slotMinutes': slotMinutes,
        'weekStartsMonday': weekStartsMonday,
        'notificationsEnabled': notificationsEnabled,
        'reminderLeadMinutes': reminderLeadMinutes,
        'hapticsEnabled': hapticsEnabled,
        'auroraLevel': auroraLevel,
        'glassBlur': glassBlur,
        'accentValue': accentValue,
        'glassStyleIndex': glassStyleIndex,
        'profilePicturePath': profilePicturePath,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        name: j['name'] ?? '',
        dayStartHour: j['dayStartHour'] ?? 6,
        dayEndHour: j['dayEndHour'] ?? 23,
        slotMinutes: j['slotMinutes'] ?? 30,
        weekStartsMonday: j['weekStartsMonday'] ?? true,
        notificationsEnabled: j['notificationsEnabled'] ?? true,
        reminderLeadMinutes: j['reminderLeadMinutes'] ?? 10,
        hapticsEnabled: j['hapticsEnabled'] ?? true,
        auroraLevel: j['auroraLevel'] ?? 1,
        glassBlur: (j['glassBlur'] ?? 24).toDouble(),
        accentValue: j['accentValue'] ?? 0xFFD4F25C,
        glassStyleIndex: j['glassStyleIndex'] ?? 0,
        profilePicturePath: j['profilePicturePath'],
      );
}

class AppStore extends ChangeNotifier {
  AppStore(this._prefs);
  final SharedPreferences _prefs;

  bool onboarded = false;
  AppSettings settings = AppSettings();
  List<Habit> habits = [];
  List<HabitLog> logs = [];
  List<PlannerBlock> blocks = [];

  static const _kOnboarded = 'onboarded_v1';
  static const _kSettings = 'settings_v1';
  static const _kHabits = 'habits_v1';
  static const _kLogs = 'logs_v1';
  static const _kBlocks = 'blocks_v1';
  static const _kNotifSeq = 'notif_seq_v1';

  void _syncStatics() {
    GlassConfig.blur = settings.glassBlur;
    GlassConfig.auroraIntensity = [0.6, 1.0, 1.4][settings.auroraLevel.clamp(0, 2).toInt()];
    GlassConfig.style = settings.glassStyleIndex == 1 ? GlassStyle.clear : GlassStyle.frosted;
    Accent.color = settings.accent;
  }

  Future<void> load() async {
    onboarded = _prefs.getBool(_kOnboarded) ?? _prefs.getBool('onboarded') ?? false;
    final legacyName = _prefs.getString('name');
    final legacyDayStart = _prefs.getInt('dayStart');
    final rawSettings = _prefs.getString(_kSettings);
    if (rawSettings != null) {
      settings = AppSettings.fromJson(jsonDecode(rawSettings));
    } else {
      settings = AppSettings(name: legacyName ?? '', dayStartHour: legacyDayStart ?? 6);
    }
    habits = (jsonDecode(_prefs.getString(_kHabits) ?? '[]') as List)
        .map((e) => Habit.fromJson(e as Map<String, dynamic>))
        .toList();
    logs = (jsonDecode(_prefs.getString(_kLogs) ?? '[]') as List)
        .map((e) => HabitLog.fromJson(e as Map<String, dynamic>))
        .toList();
    blocks = (jsonDecode(_prefs.getString(_kBlocks) ?? '[]') as List)
        .map((e) => PlannerBlock.fromJson(e as Map<String, dynamic>))
        .toList();
    _syncStatics();

    // Habits saved before reminders existed get their notification id block now.
    bool assigned = false;
    for (final h in habits) {
      if (h.notifBase <= 0) {
        h.notifBase = _nextNotifBase();
        assigned = true;
      }
    }
    if (assigned) await _saveHabits();

    // Reminders must never be able to stop the app from starting.
    try {
      await NotificationService.init();
      await syncAllReminders();
    } catch (_) {}
  }

  int _nextNotifBase() {
    final next = (_prefs.getInt(_kNotifSeq) ?? 0) + 1;
    _prefs.setInt(_kNotifSeq, next);
    return next;
  }

  Future<void> syncAllReminders() async {
    try {
      await NotificationService.syncAll(habits, settings, isDue);
    } catch (_) {}
  }

  Future<void> _saveSettings() async => _prefs.setString(_kSettings, jsonEncode(settings.toJson()));
  Future<void> _saveHabits() async => _prefs.setString(_kHabits, jsonEncode(habits.map((e) => e.toJson()).toList()));
  Future<void> _saveLogs() async => _prefs.setString(_kLogs, jsonEncode(logs.map((e) => e.toJson()).toList()));
  Future<void> _saveBlocks() async => _prefs.setString(_kBlocks, jsonEncode(blocks.map((e) => e.toJson()).toList()));

  Future<void> completeOnboarding(String name, int dayStart, Color accent, bool notifications) async {
    settings.name = name;
    settings.dayStartHour = dayStart;
    settings.accentValue = accent.value;
    settings.notificationsEnabled = notifications;
    onboarded = true;
    await _prefs.setBool(_kOnboarded, true);
    await _prefs.setBool('onboarded', true);
    await _prefs.setString('name', name);
    await _prefs.setInt('dayStart', dayStart);
    await _saveSettings();
    _syncStatics();
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    onboarded = false;
    await _prefs.setBool(_kOnboarded, false);
    await _prefs.setBool('onboarded', false);
    notifyListeners();
  }

  Future<void> updateSettings(void Function(AppSettings s) fn) async {
    final notifBefore = settings.notificationsEnabled;
    fn(settings);
    _syncStatics();
    await _saveSettings();
    notifyListeners();
    // Only the master reminder switch changes what is scheduled.
    if (settings.notificationsEnabled != notifBefore) {
      if (settings.notificationsEnabled) await NotificationService.requestPermission();
      await syncAllReminders();
    }
  }

  Future<void> addHabit(Habit h) async {
    if (h.notifBase <= 0) h.notifBase = _nextNotifBase();
    habits.add(h);
    await _saveHabits();
    notifyListeners();
    await _syncReminders(h);
  }

  Future<void> updateHabit(Habit h) async {
    if (h.notifBase <= 0) h.notifBase = _nextNotifBase();
    final i = habits.indexWhere((e) => e.id == h.id);
    if (i >= 0) habits[i] = h;
    await _saveHabits();
    notifyListeners();
    await _syncReminders(h);
  }

  Future<void> deleteHabit(String id) async {
    final matches = habits.where((h) => h.id == id).toList();
    for (final h in matches) {
      try {
        await NotificationService.cancelHabit(h);
      } catch (_) {}
      _deleteFile(h.coverImagePath);
    }
    habits.removeWhere((h) => h.id == id);
    logs.removeWhere((l) => l.habitId == id);
    await _saveHabits();
    await _saveLogs();
    notifyListeners();
  }

  Future<void> _syncReminders(Habit h) async {
    try {
      await NotificationService.syncHabit(h, settings, isDue);
    } catch (_) {}
  }

  void _deleteFile(String? path) {
    if (path == null) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  HabitLog _logFor(String habitId, String date) {
    return logs.firstWhere(
      (l) => l.habitId == habitId && l.date == date,
      orElse: () {
        final l = HabitLog(habitId: habitId, date: date);
        logs.add(l);
        return l;
      },
    );
  }

  bool isDoneOn(Habit h, DateTime day) {
    final l = logs.where((e) => e.habitId == h.id && e.date == dayKey(day)).toList();
    return l.isNotEmpty && l.first.done;
  }

  double amountOn(Habit h, DateTime day) {
    final l = logs.where((e) => e.habitId == h.id && e.date == dayKey(day)).toList();
    return l.isEmpty ? 0 : l.first.amount;
  }

  /// The single source of truth for "did this habit succeed on this day",
  /// aware of its type: normal = checked, avoid = did NOT log a slip,
  /// amount = reached its daily goal.
  bool successOn(Habit h, DateTime day) {
    switch (h.type) {
      case 'avoid':
        return !isDoneOn(h, day);
      case 'amount':
        return amountOn(h, day) >= h.amountGoal;
      default:
        return isDoneOn(h, day);
    }
  }

  int focusSecondsOn(Habit h, DateTime day) {
    final l = logs.where((e) => e.habitId == h.id && e.date == dayKey(day)).toList();
    return l.isEmpty ? 0 : l.first.focusSeconds;
  }

  Future<void> toggleHabit(Habit h, DateTime day) async {
    final log = _logFor(h.id, dayKey(day));
    log.done = !log.done;
    if (h.hasChecklist) {
      log.steps = log.done ? h.checklist.map((e) => e.id).toList() : <String>[];
    }
    await _saveLogs();
    notifyListeners();
  }

  // ── checklist ──
  bool stepDone(Habit h, DateTime day, String stepId) {
    final l = logs.where((e) => e.habitId == h.id && e.date == dayKey(day)).toList();
    return l.isNotEmpty && l.first.steps.contains(stepId);
  }

  int stepsDoneOn(Habit h, DateTime day) {
    final ids = h.checklist.map((e) => e.id).toSet();
    final l = logs.where((e) => e.habitId == h.id && e.date == dayKey(day)).toList();
    if (l.isEmpty) return 0;
    return l.first.steps.where(ids.contains).length;
  }

  /// Ticks / unticks one step. The habit is done exactly when every step is ticked,
  /// so streaks and history keep using the normal `done` flag.
  Future<void> toggleStep(Habit h, DateTime day, String stepId) async {
    final log = _logFor(h.id, dayKey(day));
    if (log.steps.contains(stepId)) {
      log.steps.remove(stepId);
    } else {
      log.steps.add(stepId);
    }
    final ids = h.checklist.map((e) => e.id).toSet();
    log.steps = log.steps.where(ids.contains).toList();
    log.done = ids.isNotEmpty && ids.every(log.steps.contains);
    await _saveLogs();
    notifyListeners();
  }

  Future<void> setAmount(Habit h, DateTime day, double value) async {
    final log = _logFor(h.id, dayKey(day));
    log.amount = value < 0 ? 0 : value;
    log.done = log.amount >= h.amountGoal;
    await _saveLogs();
    notifyListeners();
  }

  Future<void> addFocusSeconds(Habit h, DateTime day, int seconds) async {
    final log = _logFor(h.id, dayKey(day));
    log.focusSeconds += seconds;
    await _saveLogs();
    notifyListeners();
  }

  bool isDue(Habit h, DateTime day) {
    switch (h.repeatType) {
      case 'weekdays':
        return h.weekdays.contains(day.weekday);
      case 'timesPerWeek':
        return true;
      case 'everyNDays':
        final n = h.everyNDays < 1 ? 1 : h.everyNDays;
        final diff = dateOnly(day).difference(dateOnly(h.createdAt)).inDays;
        return diff >= 0 && diff % n == 0;
      default:
        return true;
    }
  }

  bool allDueDoneToday() {
    final now = DateTime.now();
    final due = habits.where((h) => isDue(h, now)).toList();
    if (due.isEmpty) return false;
    return due.every((h) => successOn(h, now));
  }

  int currentStreak(Habit h) {
    int streak = 0;
    DateTime cursor = dateOnly(DateTime.now());
    if (!successOn(h, cursor)) cursor = cursor.subtract(const Duration(days: 1));
    int guard = 0;
    while (guard < 1000) {
      guard++;
      if (isDue(h, cursor)) {
        if (successOn(h, cursor)) {
          streak++;
        } else {
          break;
        }
      }
      final prev = cursor.subtract(const Duration(days: 1));
      if (prev.isBefore(h.createdAt.subtract(const Duration(days: 1)))) break;
      cursor = prev;
    }
    return streak;
  }

  int bestStreak(Habit h) {
    int best = 0, running = 0;
    DateTime cursor = dateOnly(h.createdAt);
    final end = dateOnly(DateTime.now());
    int guard = 0;
    while (!cursor.isAfter(end) && guard < 2000) {
      guard++;
      if (isDue(h, cursor)) {
        if (successOn(h, cursor)) {
          running++;
          if (running > best) best = running;
        } else {
          running = 0;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return best;
  }

  int totalCompletions(Habit h) {
    final dates = logs.where((l) => l.habitId == h.id).map((l) => l.date).toSet();
    int count = 0;
    for (final d in dates) {
      final parts = d.split('-');
      final day = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      if (successOn(h, day)) count++;
    }
    return count;
  }

  /// Share of due days in the last [days] days that succeeded (0..1).
  /// Today only counts once it is a success, so an unfinished day never reads as a miss.
  double consistency(Habit h, {int days = 30}) {
    final today = dateOnly(DateTime.now());
    final start = dateOnly(h.createdAt);
    int due = 0, ok = 0;
    for (int i = 0; i < days; i++) {
      final d = today.subtract(Duration(days: i));
      if (d.isBefore(start)) break;
      if (!isDue(h, d)) continue;
      final success = successOn(h, d);
      if (i == 0 && !success) continue;
      due++;
      if (success) ok++;
    }
    if (due == 0) return 0;
    if (h.repeatType == 'timesPerWeek') {
      // "N per week" habits are due every day in the streak maths, so measure against the weekly target.
      final span = today.difference(start).inDays + 1;
      final window = span < days ? span : days;
      final target = window * h.timesPerWeek / 7;
      return target <= 0 ? 0 : (ok / target).clamp(0.0, 1.0).toDouble();
    }
    return ok / due;
  }

  double overallConsistency({int days = 30}) {
    if (habits.isEmpty) return 0;
    final vals = habits.map((h) => consistency(h, days: days)).toList();
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  Future<void> addBlock(PlannerBlock b) async {
    blocks.add(b);
    await _saveBlocks();
    notifyListeners();
  }

  Future<void> updateBlock(PlannerBlock b) async {
    final i = blocks.indexWhere((e) => e.id == b.id);
    if (i >= 0) blocks[i] = b;
    await _saveBlocks();
    notifyListeners();
  }

  Future<void> deleteBlock(String id) async {
    blocks.removeWhere((b) => b.id == id);
    await _saveBlocks();
    notifyListeners();
  }

  Future<void> toggleBlock(PlannerBlock b) async {
    b.done = !b.done;
    if (b.linkedHabitId != null) {
      final h = habits.where((e) => e.id == b.linkedHabitId).toList();
      if (h.isNotEmpty) {
        final log = _logFor(h.first.id, b.date);
        log.done = b.done;
        if (h.first.hasChecklist) {
          log.steps = log.done ? h.first.checklist.map((e) => e.id).toList() : <String>[];
        }
        await _saveLogs();
      }
    }
    await _saveBlocks();
    notifyListeners();
  }

  List<PlannerBlock> blocksOn(DateTime day) {
    final list = blocks.where((b) => b.date == dayKey(day)).toList();
    list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return list;
  }

  String exportJson() => jsonEncode({
        'settings': settings.toJson(),
        'habits': habits.map((e) => e.toJson()).toList(),
        'logs': logs.map((e) => e.toJson()).toList(),
        'blocks': blocks.map((e) => e.toJson()).toList(),
      });

  Future<bool> importJson(String raw) async {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final newSettings = AppSettings.fromJson(j['settings']);
      final newHabits = (j['habits'] as List).map((e) => Habit.fromJson(e)).toList();
      final newLogs = (j['logs'] as List).map((e) => HabitLog.fromJson(e)).toList();
      final newBlocks = (j['blocks'] as List).map((e) => PlannerBlock.fromJson(e)).toList();
      // Drop reminders of the habits being replaced, then give imported habits fresh id blocks.
      for (final h in habits) {
        try {
          await NotificationService.cancelHabit(h);
        } catch (_) {}
      }
      for (final h in newHabits) {
        h.notifBase = _nextNotifBase();
      }
      settings = newSettings;
      habits = newHabits;
      logs = newLogs;
      blocks = newBlocks;
      await _saveSettings();
      await _saveHabits();
      await _saveLogs();
      await _saveBlocks();
      _syncStatics();
      notifyListeners();
      await syncAllReminders();
      return true;
    } catch (_) {
      return false;
    }
  }
}
