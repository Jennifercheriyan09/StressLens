import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(FlowerBloomApp());
}

class FlowerBloomApp extends StatelessWidget {
  const FlowerBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FlowerBloomScreen(),
    );
  }
}

class FlowerBloomScreen extends StatefulWidget {
  const FlowerBloomScreen({super.key});

  @override
  _FlowerBloomScreenState createState() => _FlowerBloomScreenState();
}

class _FlowerBloomScreenState extends State<FlowerBloomScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bloomAnimation;
  bool isInhale = true;
  bool isAnimating = false;
  Timer? _sessionTimer;
  int _elapsedTime = 0; // Elapsed time in seconds

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            isInhale = !isInhale;
          });
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
            isInhale = !isInhale;
          });
          _controller.forward();
        }
      });

    _bloomAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    setState(() {
      isAnimating = true;
      _elapsedTime = 0; // Reset timer
    });
    _controller.forward();

    // Start timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  void _stopAnimation() {
    setState(() {
      isAnimating = false;
      isInhale = true;
    });
    _controller.stop();
    _sessionTimer?.cancel();

    // Show popup with elapsed time
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Text(
            'You have breathed for ${_elapsedTime ~/ 60} minutes and ${_elapsedTime % 60} seconds.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3534),
        title:
            const Text('Flower Bloom', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isAnimating
                  ? (isInhale ? 'Inhale...' : 'Exhale...')
                  : 'Press Start to Breathe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
            const SizedBox(height: 20),
            ScaleTransition(
              scale: _bloomAnimation,
              child: Image.asset(
                'assets/games/flower_bloom.png', // Add a flower image in assets folder
                height: 200,
                width: 200,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isAnimating ? _stopAnimation : _startAnimation,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAnimating ? Colors.red : Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                isAnimating ? 'Stop' : 'Start',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
