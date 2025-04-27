import 'package:flutter/material.dart';

class SnakeGame extends StatelessWidget {
  const SnakeGame({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Snake Game')),
      body: const Center(child: Text('Snake Game')),
    );
  }
}
