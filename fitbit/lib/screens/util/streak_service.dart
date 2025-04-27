import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const _journalKey = 'journal_streak';
  static const _meditationKey = 'meditation_streak';
  static const _journalDateKey = 'last_journal_date';
  static const _meditationDateKey = 'last_meditation_date';

  static Future<void> markCompleted(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now(); // FULL Date + Time
    final nowStr = now.toIso8601String(); // full ISO time with seconds

    final lastDateKey = type == 'journal' ? _journalDateKey : _meditationDateKey;
    final streakKey = type == 'journal' ? _journalKey : _meditationKey;

    final lastDateStr = prefs.getString(lastDateKey);
    final currentStreak = prefs.getInt(streakKey) ?? 0;

    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      final difference = now.difference(lastDate).inDays;

      if (difference == 1) {
        // Next day
        prefs.setInt(streakKey, currentStreak + 1);
      } else if (difference == 0) {
        // Same day, just updating time
        prefs.setInt(streakKey, currentStreak);
      } else {
        // Missed, reset
        prefs.setInt(streakKey, 1);
      }
    } else {
      prefs.setInt(streakKey, 1); // First time user
    }

    prefs.setString(lastDateKey, nowStr); // Save FULL DateTime
  }

  static Future<int> getStreak(String type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(type == 'journal' ? _journalKey : _meditationKey) ?? 0;
  }

  static Future<DateTime?> getLastUpdateTime(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(type == 'journal' ? _journalDateKey : _meditationDateKey);
    if (lastDateStr == null) return null;
    return DateTime.tryParse(lastDateStr);
  }
}
