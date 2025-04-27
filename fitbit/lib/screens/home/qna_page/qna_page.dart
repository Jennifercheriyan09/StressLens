import 'package:flutter/material.dart';

class DailyStressCheckScreen extends StatefulWidget {
  const DailyStressCheckScreen({Key? key}) : super(key: key);

  @override
  State<DailyStressCheckScreen> createState() => _DailyStressCheckScreenState();
}

class _DailyStressCheckScreenState extends State<DailyStressCheckScreen> {
  List<int?> _answers = List.generate(4, (index) => null);

  final List<Map<String, dynamic>> _questions = [
    {
      'question': '1. How stressed do you feel right now?',
      'options': ['Not at all', 'Mild', 'Moderate', 'High', 'Severe'],
      'points': [0, 1, 2, 3, 4],
    },
    {
      'question': '2. How well are you able to focus today?',
      'options': ['Very well', 'Okay', 'Difficult', 'Very difficult'],
      'points': [0, 1, 2, 3],
    },
    {
      'question': '3. How is your energy level today?',
      'options': ['High', 'Medium', 'Low'],
      'points': [0, 1, 2],
    },
    {
      'question': '4. How tense does your body feel right now?',
      'options': ['Relaxed', 'A little tense', 'Quite tense', 'Very tense'],
      'points': [0, 1, 2, 3],
    },
  ];

  void _submitCheckIn() {
    int totalScore = 0;
    for (int i = 0; i < _answers.length; i++) {
      if (_answers[i] != null) {
        totalScore += (_questions[i]['points'][_answers[i]!] as int); // 🔥 fixed casting
      }
    }

    String mood = '';
    String advice = '';

    if (totalScore <= 4) {
      mood = 'Feeling Calm 🌿';
      advice = 'Great! Keep embracing the calmness.';
    } else if (totalScore <= 8) {
      mood = 'Mild Stress 🌼';
      advice = 'Maybe take 5 deep breaths and relax.';
    } else if (totalScore <= 12) {
      mood = 'Moderate Stress 🌾';
      advice = 'Consider taking a short meditation or walk.';
    } else {
      mood = 'High Stress 🔥';
      advice = 'Pause, breathe deeply. Maybe journal or meditate.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Today\'s Stress Check-In'),
        content: Text('$mood\n\n$advice'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, // 🤍 White card background
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3), // Shadow position
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _questions[index]['question'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B3534), // Dark teal color
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(_questions[index]['options'].length, (optionIndex) {
              return RadioListTile<int>(
                title: Text(_questions[index]['options'][optionIndex]),
                value: optionIndex,
                groupValue: _answers[index],
                onChanged: (value) {
                  setState(() {
                    _answers[index] = value;
                  });
                },
                activeColor: const Color(0xFF0B3534), // Theme color for selected radio
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FFFF), // Light teal page background
      appBar: AppBar(
        title: const Text('Daily Stress Check', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3534),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Answer a few quick questions to reflect on your day:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B3534),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_questions.length, (index) => _buildQuestionCard(index)),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_answers.contains(null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please answer all questions')),
                    );
                  } else {
                    _submitCheckIn();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Submit Check-In', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
