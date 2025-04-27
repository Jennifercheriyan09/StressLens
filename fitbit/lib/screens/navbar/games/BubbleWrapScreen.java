import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';

class BubbleWrapScreen extends StatefulWidget {
  const BubbleWrapScreen({Key? key}) : super(key: key);

  @override
  _BubbleWrapScreenState createState() => _BubbleWrapScreenState();
}

class _BubbleWrapScreenState extends State<BubbleWrapScreen> {
  final int _numberOfBubbles = 64; // Total number of bubbles
  late List<Bubble> _bubbles; // Initialize as an empty list
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Initialize the confetti controller
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 300));
    // Create an empty bubble list
    _bubbles = [];
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _resetBubbleGrid() {
    setState(() {
      _bubbles = List.generate(_numberOfBubbles, (index) {
        return _createBubble(index);
      });
    });
  }

  Bubble _createBubble(int index) {
    double size = _random.nextDouble() * 40 + 20; // Random size between 20 and 60
    Offset position;

    // Loop until a non-overlapping position is found
    do {
      position = Offset(
        _random.nextDouble() * (MediaQuery.of(context).size.width - size), // Random x position
        _random.nextDouble() * (MediaQuery.of(context).size.height - size), // Random y position
      );
    } while (_isOverlapping(position, size));

    return Bubble(
      index: index,
      size: size,
      isPopped: false,
      position: position,
    );
  }

  bool _isOverlapping(Offset position, double size) {
    for (Bubble bubble in _bubbles) {
      if (!bubble.isPopped) {
        // Calculate distance between the centers of the two bubbles
        double distance = sqrt(pow(bubble.position.dx - position.dx, 2) + pow(bubble.position.dy - position.dy, 2));
        if (distance < (bubble.size / 2 + size / 2)) {
          return true; // Overlap detected
        }
      }
    }
    return false; // No overlap
  }

  Future<void> _popBubble(int index) async {
    print('Attempting to pop bubble at index: $index');
    setState(() {
      _bubbles[index].isPopped = true;
    });

    // Play pop sound
    await _audioPlayer.play(AssetSource('assets/games/pop.mp3'));
    print('Played pop sound for bubble at index: $index');

    // Trigger haptic feedback
    HapticFeedback.mediumImpact();

    // Trigger confetti
    _confettiController.play();

    // Check if all bubbles are popped
    if (_bubbles.every((bubble) => bubble.isPopped)) {
      print('All bubbles have been popped!'); // This should print when all are popped
      _showAllPoppedDialog();
    } else {
      print('Still more bubbles to pop.'); // Print if not all are popped
    }
  }


  void _showAllPoppedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('You have popped all the bubbles!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bubbles.isEmpty) {
      _resetBubbleGrid(); // Generate bubbles only when the widget is built
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Wrap'),
        backgroundColor: const Color(0xFF00695C), // Dark teal color for the app bar
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetBubbleGrid,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB2DFDB), Color(0xFF80CBC4)], // Soft teal gradient for the background
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: _bubbles.map((bubble) {
                return Positioned(
                  left: bubble.position.dx,
                  top: bubble.position.dy,
                  child: GestureDetector(
                    onTap: () => _popBubble(bubble.index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: bubble.isPopped ? 0 : bubble.size,
                      height: bubble.isPopped ? 0 : bubble.size,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bubble.isPopped ? Colors.transparent : Color(0xFF00796B), // Uniform dark teal for bubbles
                        gradient: bubble.isPopped
                            ? null
                            : const LinearGradient(
                          colors: [Color(0xFF009688), Color(0xFF00796B)], // Gradient for the unpopped bubbles
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: bubble.isPopped
                            ? []
                            : [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.6),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      transform: bubble.isPopped
                          ? Matrix4.identity()
                          : (Matrix4.identity()..scale(1.1)), // Bubble scale effect
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Confetti widget for effect on popping
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: [Color(0xFF00796B), Color(0xFF004D40)], // Confetti colors matching the theme
              numberOfParticles: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class Bubble {
  final int index;
  final double size;
  bool isPopped;
  final Offset position;

  Bubble({required this.index, required this.size, required this.isPopped, required this.position});
}
