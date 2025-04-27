import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math';

class MusicRecScreen extends StatefulWidget {
  const MusicRecScreen({super.key});

  @override
  _MusicRecScreenState createState() => _MusicRecScreenState();
}

class _MusicRecScreenState extends State<MusicRecScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, String>> recommendedMusic = [];
  List<Map<String, String>> initialMusic = []; // To hold the initial songs
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _selectRandomInitialSongs();
  }

  void _selectRandomInitialSongs() {
    List<Map<String, String>> allMusic = [
      // Your existing music list
      {
        "title": "Birdsong Bliss",
        "genre": "Seasonal/ASMR",
        "image": "assets/music/birdsong.png",
        "url": "https://example.com/birdsong.mp3"
      },
      {
        "title": "Forest Dawn",
        "genre": "Seasonal/ASMR",
        "image": "assets/music/forest_dawn.png"
      },
      {
        "title": "Calm Waves",
        "genre": "Calm & Soothing",
        "image": "assets/music/calm_waves.png"
      },
      {
        "title": "Ocean of Peace",
        "genre": "Calm & Soothing",
        "image": "assets/music/ocean_of_peace.png"
      },
      {
        "title": "Electric Sunset",
        "genre": "Youth-Focused",
        "image": "assets/music/electric_sunset.png"
      },
      // Add more songs as needed
    ];

    // Shuffle and select 3 random songs
    allMusic.shuffle(_random);
    initialMusic = allMusic.take(3).toList();

    setState(() {
      recommendedMusic = initialMusic; // Show initial songs
    });
  }

  void recommendMusic(String mood) {
    List<Map<String, String>> allMusic = [
      // The same music list used above
      {
        "title": "Birdsong Bliss",
        "genre": "Seasonal/ASMR",
        "image": "assets/music/birdsong.png",
        "url": "https://example.com/birdsong.mp3"
      },
      {
        "title": "Forest Dawn",
        "genre": "Seasonal/ASMR",
        "image": "assets/music/forest_dawn.png"
      },
      {
        "title": "Calm Waves",
        "genre": "Calm & Soothing",
        "image": "assets/music/calm_waves.png"
      },
      {
        "title": "Ocean of Peace",
        "genre": "Calm & Soothing",
        "image": "assets/music/ocean_of_peace.png"
      },
      {
        "title": "Electric Sunset",
        "genre": "Youth-Focused",
        "image": "assets/music/electric_sunset.png"
      },
      // Add more songs as needed
    ];

    setState(() {
      recommendedMusic = allMusic
          .where((music) {
            if (mood == "Relax") {
              return music['genre'] == 'Seasonal/ASMR' ||
                  music['genre'] == 'Calm & Soothing';
            } else if (mood == "Focus") {
              return music['genre'] ==
                  'Youth-Focused'; // Focus on energetic music
            } else if (mood == "Calm") {
              return music['genre'] == 'Calm & Soothing';
            } else if (mood == "Anxious") {
              return music['genre'] ==
                  'Seasonal/ASMR'; // Gentle music to calm anxiety
            }
            return false;
          })
          .toList()
          .take(2)
          .toList(); // Display at most 2 recommended songs
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How Are You Feeling Today?'),
        backgroundColor: const Color(0xFF0B3534),
      ),
      backgroundColor: const Color(0xFFD1FFFF),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Please select your mood:',
              style: TextStyle(fontSize: 20),
            ),
          ),
          Wrap(
            spacing: 10,
            children: [
              _buildMoodButton('Relax'),
              _buildMoodButton('Focus'),
              _buildMoodButton('Calm'),
              _buildMoodButton('Anxious'),
            ],
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.8,
              ),
              itemCount: recommendedMusic.length,
              itemBuilder: (context, index) {
                return _buildMusicTile(
                  recommendedMusic[index]["title"]!,
                  recommendedMusic[index]["genre"]!,
                  recommendedMusic[index]["image"]!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(String mood) {
    return ElevatedButton(
      onPressed: () => recommendMusic(mood),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0B3534),
        foregroundColor: Colors.white,
      ),
      child: Text(mood),
    );
  }

  Widget _buildMusicTile(String title, String genre, String imagePath) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 100,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
