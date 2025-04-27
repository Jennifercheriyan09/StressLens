// journal_page.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Simple model for one entry
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Add a new entry for the currently selected day
  void _addEntry() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _entries.insert(
        0,
        JournalEntry(DateTime.now(), text),
      );
      _controller.clear();
    });
  }

  /// Filter entries to only those matching the selected day
  List<JournalEntry> get _filteredEntries => _entries.where((e) {
    return isSameDay(e.timestamp, _selectedDay);
  }).toList();

  /// Format as DD/MM/YYYY  HH:MM
  String _formatTimestamp(DateTime dt) {
    final d = dt;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date  $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        backgroundColor: const Color(0xFF0B3534),
      ),
      body: Column(
        children: [
          // ─── Calendar ─────────────────────────────
          TableCalendar<DateTime>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _controller.clear();
              });
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── Entry editor ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Write your journal entry...',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ─── Save button ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.save),
              label: const Text('Save Entry'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF0B3534),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Entries list ─────────────────────────
          Expanded(
            child: _filteredEntries.isEmpty
                ? const Center(child: Text('No entries for this date.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = _filteredEntries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      _formatTimestamp(entry.timestamp),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(entry.text),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
