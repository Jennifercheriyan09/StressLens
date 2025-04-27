import 'package:flutter/material.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';

class MeditationTimer extends StatefulWidget {
  const MeditationTimer({super.key});

  @override
  State<MeditationTimer> createState() => _MeditationTimerState();
}

class _MeditationTimerState extends State<MeditationTimer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late AudioPlayer _audioPlayer;
  final int _totalSeconds = 600; // 10 minutes
  String _breatheText = "Breathe In...";
  Timer? _breatheTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );

    _audioPlayer = AudioPlayer();

    // Breathe Animation Timer
    _breatheTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _breatheText = _breatheText == "Breathe In..." ? "Breathe Out..." : "Breathe In...";
      });
    });
  }

  String get timerString {
    Duration duration = _controller.duration! * (1.0 - _controller.value);
    return '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  Future<void> _startMeditation() async {
    _controller.reverse(from: 1.0);
    await _audioPlayer.setAsset('assets/music/music_files/ocean_of_peace.mp3'); // your calm music file
    _audioPlayer.play();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _audioPlayer.stop();
        _showMeditationCompleteDialog();
      }
    });
  }

  void _showMeditationCompleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Session Complete!'),
        content: const Text('Your 10-minute meditation has ended.'),
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

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    _breatheTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text(
            "Meditation Timer",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B3534),
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: 1.0 - _controller.value,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[300],
                  color: Colors.teal,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timerString,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _breatheText,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _startMeditation,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Meditation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
