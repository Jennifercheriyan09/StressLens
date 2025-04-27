import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // Update streak logic when user opens the app
  static Future<void> updateStreak() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore.collection('user_streaks').doc(uid);
    final doc = await docRef.get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (doc.exists) {
      final data = doc.data()!;
      final lastDateTimestamp = data['lastLogin'] as Timestamp;
      final lastDate = DateTime(
          lastDateTimestamp.toDate().year,
          lastDateTimestamp.toDate().month,
          lastDateTimestamp.toDate().day
      );
      final streak = data['streakCount'] ?? 1;

      if (today.difference(lastDate).inDays == 1) {
        // User logged in consecutive day
        await docRef.update({
          'streakCount': streak + 1,
          'lastLogin': now,
        });
      } else if (today.isAfter(lastDate)) {
        // Missed a day, reset streak
        await docRef.set({
          'streakCount': 1,
          'lastLogin': now,
        });
      }
      // If logged again today, do nothing
    } else {
      // First time entry
      await docRef.set({
        'streakCount': 1,
        'lastLogin': now,
      });
    }
  }

  // Fetch the user's streak info
  static Future<Map<String, dynamic>?> getUserStreakData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('user_streaks').doc(uid).get();
    return doc.data();
  }
}
