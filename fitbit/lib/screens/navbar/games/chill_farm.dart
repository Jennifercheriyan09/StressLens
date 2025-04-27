import 'package:flutter/material.dart';
import 'dart:async';

class ChillFarmScreen extends StatefulWidget {
  const ChillFarmScreen({super.key});

  @override
  _ChillFarmScreenState createState() => _ChillFarmScreenState();
}

class _ChillFarmScreenState extends State<ChillFarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _growthAnimation;
  int _growthStage = 0;
  int _harvestedCount = 0;
  final List<String> _harvestedPlants = []; // List to track harvested plants

  Timer? _growthTimer;
  int _remainingTime = 15; // Initial countdown time in seconds

  final List<String> _growthStages = [
    'assets/games/seed.jpg', // Seed image
    'assets/games/sprout.png', // Sprout image
    'assets/games/full_plant.jpg', // Full-grown plant image
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _growthAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    _controller.forward();
  }

  void _startGrowthTimer() {
    if (_growthStage < _growthStages.length - 1) {
      setState(() {
        _remainingTime = 15; // Reset countdown
      });

      _growthTimer?.cancel(); // Cancel any existing timer
      _growthTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime > 0) {
          setState(() {
            _remainingTime--;
          });
        } else {
          timer.cancel();
          _growPlantAutomatically();
        }
      });
    }
  }

  void _growPlantAutomatically() {
    setState(() {
      if (_growthStage < _growthStages.length - 1) {
        _growthStage++;
        if (_growthStage < _growthStages.length - 1) {
          _startGrowthTimer();
        }
      }
    });
  }

  void _growPlant() {
    setState(() {
      if (_growthStage < _growthStages.length - 1) {
        _growthStage++;
        _startGrowthTimer();
      }
    });
  }

  void _harvestPlant() {
    setState(() {
      _growthStage = 0; // Reset to the initial stage
      _harvestedPlants.add(_growthStages.last); // Add harvested plant to list
      _harvestedCount++;
      _growthTimer?.cancel(); // Stop the timer on harvest
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _growthTimer?.cancel(); // Cancel the timer if it's running
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chill Farm'),
        backgroundColor: const Color(0xFF0B3534),
      ),
      backgroundColor: const Color(0xFFF3FFFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display harvested plants at the top
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _harvestedPlants.length,
                (index) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    _harvestedPlants[index],
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Harvested Plants: $_harvestedCount',
              style: TextStyle(fontSize: 18, color: Colors.teal.shade900),
            ),
            const SizedBox(height: 40),
            // Animated plant growth
            ScaleTransition(
              scale: _growthAnimation,
              child: Image.asset(
                _growthStages[_growthStage],
                height: 200,
                width: 200,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _growthStage == 0
                  ? "Plant a Seed"
                  : _growthStage == _growthStages.length - 1
                      ? "Harvest Your Plant!"
                      : "Growing... $_remainingTime seconds left",
              style: TextStyle(fontSize: 24, color: Colors.teal.shade900),
            ),
            const SizedBox(height: 40),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _growthStage < _growthStages.length - 1
                      ? _growPlant
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('Water Plant'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _growthStage == _growthStages.length - 1
                      ? _harvestPlant
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                  ),
                  child: Text('Harvest'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
