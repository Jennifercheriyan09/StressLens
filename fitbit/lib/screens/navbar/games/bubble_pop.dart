import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';

class BubbleWrapScreen extends StatefulWidget {
  const BubbleWrapScreen({super.key});

  @override
  _BubbleWrapScreenState createState() => _BubbleWrapScreenState();
}

class _BubbleWrapScreenState extends State<BubbleWrapScreen> {
  final int _numberOfBubbles = 45; // Reduced number of bubbles to 20
  late List<Bubble> _bubbles;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 300));
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
      _bubbles = _createBubbles();
    });
  }

  List<Bubble> _createBubbles() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const bubbleSize = 50.0; // Fixed bubble size for consistency
    const bubbleSpacing = 22.0; // Space between bubbles
    final bubblesPerRow = (screenWidth / (bubbleSize + bubbleSpacing))
        .floor(); // Adjusted for spacing
    final bubblesPerColumn = (_numberOfBubbles / bubblesPerRow).ceil();

    List<Bubble> bubbles = [];
    for (int i = 0; i < _numberOfBubbles; i++) {
      int row = i ~/ bubblesPerRow;
      int column = i % bubblesPerRow;

      // Calculate position based on grid layout with spacing
      double xPosition = column * (bubbleSize + bubbleSpacing);
      double yPosition = row * (bubbleSize + bubbleSpacing);

      bubbles.add(Bubble(
        size: bubbleSize,
        isPopped: false,
        position: Offset(xPosition, yPosition),
      ));
    }
    return bubbles;
  }

  Future<void> _popBubble(int index) async {
    setState(() {
      _bubbles[index].isPopped = true;
    });

    _audioPlayer.play(AssetSource('assets/games/pop.mp3'));
    HapticFeedback.mediumImpact();
    _confettiController.play();

    if (_bubbles.every((bubble) => bubble.isPopped)) {
      Future.delayed(
          const Duration(milliseconds: 500), _showCongratulationsMessage);
    }
  }

  void _showCongratulationsMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text(
              'You popped all the bubbles! 🎉 Great job on managing your stress!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetBubbleGrid();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bubbles.isEmpty) {
      _resetBubbleGrid();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Wrap',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor:
            const Color(0xFF0B3534), // Darker teal color matching bubbles
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetBubbleGrid,
            tooltip: 'Reset Bubbles',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB2EBF2),
                  Color(0xFF00796B)
                ], // Light aqua to teal for a fresh vibe
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
                    onTap: () => _popBubble(_bubbles.indexOf(bubble)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: bubble.isPopped ? 0 : bubble.size,
                      height: bubble.isPopped ? 0 : bubble.size,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bubble.isPopped
                            ? Colors.transparent
                            : Colors.white
                                .withOpacity(0.5), // Transparent white
                        boxShadow: bubble.isPopped
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      transform: bubble.isPopped
                          ? Matrix4.identity()
                          : (Matrix4.identity()..scale(1.1)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.yellow,
                Colors.orange,
                Colors.pink,
                Colors.purple,
              ],
              numberOfParticles: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class Bubble {
  final double size;
  bool isPopped;
  final Offset position;

  Bubble({required this.size, required this.isPopped, required this.position});
}
