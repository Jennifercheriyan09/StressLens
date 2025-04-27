import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JournalEntry {
  final DateTime timestamp;
  final String text;

  JournalEntry(this.timestamp, this.text);
}

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  DateTime _selectedDay = DateTime.now();
  final List<JournalEntry> _entries = [];
  final TextEditingController _controller = TextEditingController();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isWritingMode = false; // <--- New variable

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchEntries() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _firestore
        .collection('user_journals')
        .doc(uid)
        .collection('entries')
        .where('date', isEqualTo: _formatDate(_selectedDay))
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _entries.clear();
      _entries.addAll(snapshot.docs.map((doc) {
        final data = doc.data();
        return JournalEntry(
          (data['timestamp'] as Timestamp).toDate(),
          data['text'],
        );
      }));
    });
  }

  Future<void> _addEntry() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final newEntry = {
      'timestamp': DateTime.now(),
      'text': text,
      'date': _formatDate(_selectedDay),
    };

    await _firestore
        .collection('user_journals')
        .doc(uid)
        .collection('entries')
        .add(newEntry);

    setState(() {
      _entries.insert(0, JournalEntry(DateTime.now(), text));
      _controller.clear();
      _isWritingMode = false; // Go back to calendar after save
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FFFF),
      appBar: AppBar(
        title: const Text('Daily Journal ✍️', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3534),
      ),
      body: _isWritingMode ? _buildWritingMode() : _buildCalendarMode(),
    );
  }

  Widget _buildCalendarMode() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _selectedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _isWritingMode = true;
              _controller.clear();
              _fetchEntries(); // Load entries for selected day
            });
          },
          calendarStyle: const CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.orangeAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Select a day to start journaling 📓'),
      ],
    );
  }

  Widget _buildWritingMode() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: _addEntry,
            icon: const Icon(Icons.save),
            label: const Text('Save Entry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  spreadRadius: 1,
                  blurRadius: 6,
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText: 'Write your thoughts for the day...',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () {
            setState(() {
              _isWritingMode = false; // Back to calendar view
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: const Text('Back to Calendar'),
        ),
      ],
    );
  }
}
