import 'package:flutter/material.dart';

class QnaPage extends StatefulWidget {
  const QnaPage({super.key});

  @override
  _QnaPageState createState() => _QnaPageState();
}

class _QnaPageState extends State<QnaPage> {
  final List<Question> _questions = [
    Question(
      text: '1. How are you feeling today?',
      options: ['Happy', 'Sad', 'Anger', 'Nervous', 'Excited'],
    ),
    Question(
      text: '2. How often do you experience stress or anxiety?',
      options: ['Rarely', 'Sometimes', 'Often', 'Always'],
    ),
    Question(
      text: '3. How does stress generally affect your daily life?',
      options: ['Positively', 'Negatively', 'No Effect'],
    ),
    Question(
      text: '4. What do you do to manage your stress?',
      options: ['Meditation', 'Exercise', 'Talking to friends', 'None'],
    ),
    Question(
      text: '5. What activities help improve your mood?',
      options: ['Listening to Music', 'Going for a Walk', 'Reading', 'Other'],
    ),
  ];

  int _currentQuestionIndex = 0;
  String? _selectedAnswer;

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null; // Reset selection for the next question
      });
    } else {
      _showSummaryDialog();
    }
  }

  void _showSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Summary of Your Answers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _questions.asMap().entries.map((entry) {
              int idx = entry.key;
              return Text(
                '${entry.value.text} \nYour answer: ${entry.value.selectedAnswer ?? "No answer"}',
                style: const TextStyle(fontSize: 16),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _setSelectedAnswer(String answer) {
    setState(() {
      _selectedAnswer = answer;
      _questions[_currentQuestionIndex].selectedAnswer =
          answer; // Store the selected answer
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Q&A Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Light background color
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                    spreadRadius: 2,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              width: double.infinity, // Take full width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Text with Background Color
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent.withOpacity(
                          0.3), // Light background color for the question
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _questions[_currentQuestionIndex].text,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children:
                        _questions[_currentQuestionIndex].options.map((option) {
                      bool isSelected = _selectedAnswer ==
                          option; // Check if this option is selected
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          // Center the button
                          child: ElevatedButton(
                            onPressed: () => _setSelectedAnswer(option),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
                              backgroundColor: isSelected
                                  ? Colors.grey
                                  : const Color(
                                      0xFF0E8388), // Change color if selected
                              foregroundColor: isSelected
                                  ? const Color(0xFF0E8388)
                                  : Colors
                                      .white, // Change text color based on selection
                              minimumSize: const Size(
                                  200, 50), // Adjust the width of the button
                            ),
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Spacer(), // Pushes buttons to the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex--;
                        _selectedAnswer = _questions[_currentQuestionIndex]
                            .selectedAnswer; // Resume the selected answer
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E8388),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 50),
                    ),
                    child: const Text('Back'),
                  ),
                if (_currentQuestionIndex < _questions.length - 1)
                  ElevatedButton(
                    onPressed: _selectedAnswer != null ? _nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E8388),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 50),
                    ), // Enable button only if an answer is selected
                    child: const Text('Next'),
                  ),
                if (_currentQuestionIndex ==
                    _questions.length - 1) // On the last question
                  ElevatedButton(
                    onPressed:
                        _selectedAnswer != null ? _showSummaryDialog : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E8388),
                      minimumSize: const Size(100, 50),
                    ), // Enable submit button
                    child: const Text('Submit'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Question {
  final String text;
  final List<String> options;
  String? selectedAnswer; // Track the selected answer for each question

  Question({required this.text, required this.options, this.selectedAnswer});
}
