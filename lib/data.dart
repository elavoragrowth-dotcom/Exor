import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core.dart';

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.iconIndex,
    required this.colorValue,
    required this.repeatType,
    this.weekdays = const [],
    this.timesPerWeek = 3,
    this.plannedMinutes,
    this.focusTargetMinutes,
    this.category = 'Study',
    required this.createdAt,
  });

  final String id;
  String name;
  int iconIndex;
  int colorValue;
  String repeatType;
  List<int> weekdays;
  int timesPerWeek;
  int? plannedMinutes;
  int? focusTargetMinutes;
  String category;
  final DateTime createdAt;

  Color get color => Color(colorValue);
  IconData get icon => habitIcons[iconIndex % habitIcons.length];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconIndex': iconIndex,
        'colorValue': colorValue,
        'repeatType': repeatType,
        'weekdays': weekdays,
        'timesPerWeek': timesPerWeek,
        'plannedMinutes': plannedMinutes,
        'focusTargetMinutes': focusTargetMinutes,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'],
        name: j['name'],
        iconIndex: j['iconIndex'] ?? 0,
        colorValue: j['colorValue'] ?? C.lime.value,
        repeatType: j['repeatType'] ?? 'daily',
        weekdays: (j['weekdays'] as List?)?.map((e) => e as int).toList() ?? const [],
        timesPerWeek: j['timesPerWeek'] ?? 3,
        plannedMinutes: j['plannedMinutes'],
        focusTargetMinutes: j['focusTargetMinutes'],
        category: j['category'] ?? 'Study',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class HabitLog {
  HabitLog({required this.habitId, required this.date, this.done = false, this.focusSeconds = 0, this.note});
  final String habitId;
  final String date;
  bool done;
  int focusSeconds;
  String? note;

  Map<String, dynamic> toJson() => {'habitId': habitId, 'date': date, 'done': done, 'focusSeconds': focusSeconds, 'note': note};
  factory HabitLog.fromJson(Map<String, dynamic> j) => HabitLog(
        habitId: j['habitId'],
        date: j['date'],
        done: j['done'] ?? false,
        focusSeconds: j['focusSeconds'] ?? 0,
        note: j['note'],
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
  });
  String name;
  int dayStartHour, dayEndHour, slotMinutes, reminderLeadMinutes, auroraLevel;
  bool weekStartsMonday, notificationsEnabled, hapticsEnabled;
  double glassBlur;
  int accentValue;

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
    GlassConfig.blur = settings.glassBlur;
    GlassConfig.auroraIntensity = [0.6, 1.0, 1.4][settings.auroraLevel.clamp(0, 2).toInt()];
    Accent.color = settings.accent;
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
    Accent.color = accent;
    onboarded = true;
    await _prefs.setBool(_kOnboarded, true);
    await _prefs.setBool('onboarded', true);
    await _prefs.setString('name', name);
    await _prefs.setInt('dayStart', dayStart);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    onboarded = false;
    await _prefs.setBool(_kOnboarded, false);
    await _prefs.setBool('onboarded', false);
    notifyListeners();
  }

  Future<void> updateSettings(void Function(AppSettings s) fn) async {
    fn(settings);
    GlassConfig.blur = settings.glassBlur;
    GlassConfig.auroraIntensity = [0.6, 1.0, 1.4][settings.auroraLevel.clamp(0, 2).toInt()];
    Accent.color = settings.accent;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> addHabit(Habit h) async {
    habits.add(h);
    await _saveHabits();
    notifyListeners();
  }

  Future<void> updateHabit(Habit h) async {
    final i = habits.indexWhere((e) => e.id == h.id);
    if (i >= 0) habits[i] = h;
    await _saveHabits();
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    habits.removeWhere((h) => h.id == id);
    logs.removeWhere((l) => l.habitId == id);
    await _saveHabits();
    await _saveLogs();
    notifyListeners();
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

  int focusSecondsOn(Habit h, DateTime day) {
    final l = logs.where((e) => e.habitId == h.id && e.date == dayKey(day)).toList();
    return l.isEmpty ? 0 : l.first.focusSeconds;
  }

  Future<void> toggleHabit(Habit h, DateTime day) async {
    final log = _logFor(h.id, dayKey(day));
    log.done = !log.done;
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
      default:
        return true;
    }
  }

  int currentStreak(Habit h) {
    int streak = 0;
    DateTime cursor = dateOnly(DateTime.now());
    if (!isDoneOn(h, cursor)) cursor = cursor.subtract(const Duration(days: 1));
    int guard = 0;
    while (guard < 1000) {
      guard++;
      if (isDue(h, cursor)) {
        if (isDoneOn(h, cursor)) {
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
    final doneDates = logs.where((l) => l.habitId == h.id && l.done).map((l) => l.date).toSet();
    if (doneDates.isEmpty) return 0;
    int best = 0, running = 0;
    DateTime cursor = dateOnly(h.createdAt);
    final end = dateOnly(DateTime.now());
    int guard = 0;
    while (!cursor.isAfter(end) && guard < 2000) {
      guard++;
      if (isDue(h, cursor)) {
        if (doneDates.contains(dayKey(cursor))) {
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

  int totalCompletions(Habit h) => logs.where((l) => l.habitId == h.id && l.done).length;

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
      settings = AppSettings.fromJson(j['settings']);
      habits = (j['habits'] as List).map((e) => Habit.fromJson(e)).toList();
      logs = (j['logs'] as List).map((e) => HabitLog.fromJson(e)).toList();
      blocks = (j['blocks'] as List).map((e) => PlannerBlock.fromJson(e)).toList();
      await _saveSettings();
      await _saveHabits();
      await _saveLogs();
      await _saveBlocks();
      GlassConfig.blur = settings.glassBlur;
      GlassConfig.auroraIntensity = [0.6, 1.0, 1.4][settings.auroraLevel.clamp(0, 2).toInt()];
      Accent.color = settings.accent;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
