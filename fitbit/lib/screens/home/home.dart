import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'streak_service.dart';
import 'meditation_timer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2;
  Timer? _timer;
  int _start = 600;
  List<Map<String, String>> recommendedMusic = [];
  String? selectedMood;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentlyPlayingTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkAndUpdateStreak();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatLastDone(DateTime? time) {
    if (time == null) return "No activity yet";
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return "Updated just now";
    if (diff.inMinutes < 60) return "Updated ${diff.inMinutes} minute(s) ago";
    if (diff.inHours < 24) return "Updated ${diff.inHours} hour(s) ago";
    return "Last done on ${time.day}/${time.month}/${time.year} at ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Future<void> checkAndUpdateStreak() async {
    await StreakService.updateStreak();
    final data = await StreakService.getUserStreakData();
    final streak = data?['streakCount'] ?? 1;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔥 You\'re on a $streak day streak!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _playMusic(String title, String url) async {
    try {
      if (_currentlyPlayingTitle == title && _isPlaying) {
        // Pause if the same song is playing
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        // Play new song or resume
        if (_currentlyPlayingTitle != title) {
          await _audioPlayer.setAsset(url);
        }
        await _audioPlayer.play();
        setState(() {
          _currentlyPlayingTitle = title; // Update the currently playing title
          _isPlaying = true;
        });
      }
    } catch (e) {
      print("Error playing music: $e");
    }
  }
  
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      print('User logged out successfully');

      // Clear any stored credentials or user data if you have any
      // await storage.delete(key: 'user_email');
      // await storage.delete(key: 'user_password');

      // Navigate to login screen and remove all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to log out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void recommendMusic(String mood) {
    setState(() {
      selectedMood = mood;
      // Filter music based on mood
      switch (mood) {
        case 'Relax':
          recommendedMusic = [
            {
              "title": "Ocean of Peace",
              "genre": "Calm & Soothing",
              "image": "assets/music/ocean_of_peace.png",
              "url": "assets/music/music_files/ocean_of_peace.mp3" // Added URL
            },
            {
              "title": "Gentle Winds",
              "genre": "Calm & Soothing",
              "image": "assets/music/gentle_winds.png",
              "url": "assets/music/music_files/gentle_winds.mp3" // Added URL
            },
          ];
          break;
        case 'Focus':
          recommendedMusic = [
            {
              "title": "Electric Sunset",
              "genre": "Youth-Focused",
              "image": "assets/music/electric_sunset.png",
              "url": "assets/music/music_files/electric_sunset.mp3" // Added URL
            },
          ];
          break;
        case 'Calm':
          recommendedMusic = [
            {
              "title": "Soft Glow",
              "genre": "Calm & Soothing",
              "image": "assets/music/soft_glow.png",
              "url": "assets/music/music_files/soft_glow.mp3" // Added URL
            },
            {
              "title": "Tranquil Paths",
              "genre": "Calm & Soothing",
              "image": "assets/music/tranquil_paths.png",
              "url": "assets/music/music_files/tranquil_paths.mp3" // Added URL
            },
          ];
          break;
        case 'Anxious':
          recommendedMusic = [
            {
              "title": "Birdsong Bliss",
              "genre": "Seasonal/ASMR",
              "image": "assets/music/birdsong.png",
              "url": "assets/music/music_files/birdsong.mp3" // Added URL
            },
            {
              "title": "Forest Dawn",
              "genre": "Seasonal/ASMR",
              "image": "assets/music/forest_dawn.png",
              "url": "assets/music/music_files/forest_dawn.mp3" // Added URL
            },
          ];
          break;
      }
    });
  }

  Widget _buildRecommendedSection() {
    if (selectedMood == null) {
      return Container(); // Return empty container if no mood selected
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Recommended for your $selectedMood mood:',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B3534),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
      ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  genre,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(String mood) {
    bool isSelected = selectedMood == mood;
    return ElevatedButton(
      onPressed: () => recommendMusic(mood),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF0B3534) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF0B3534),
        elevation: isSelected ? 8 : 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFF0B3534),
            width: 1,
          ),
        ),
      ),
      child: Text(mood),
    );
  }

  // Start meditation timer logic
  

  // Timer display widget
  Widget _buildCountdownTimer() {
    final minutes = (_start ~/ 60).toString().padLeft(2, '0');
    final seconds = (_start % 60).toString().padLeft(2, '0');
    return Text(
      'Time Left: $minutes:$seconds',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

// Build Meditation Timer Section
 Widget _buildMeditationTimerSection() {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: const Color(0xFF0A3737),
      borderRadius: BorderRadius.circular(12.0),
    ),
    child: const MeditationTimer(), // ⭐ Place the new widget here
  );
}


// journaling / writing section
  Widget _buildFeelingSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capture your cares, craft your calm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                        context, '/qna'); // This should match '/qna'
                    // Navigate to Q&A page
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.question_answer,
                            size: 50, color: Colors.blue),
                        SizedBox(height: 10),
                        Text(
                          'Let\'s Do a Q&A',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                        context, '/journal'); // Navigate to Journal page
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.greenAccent, width: 2),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note, size: 50, color: Colors.green),
                        SizedBox(height: 10),
                        Text(
                          'Journal Section',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowAreYouFeelingSection() {
    final List<String> feelings = [
      'Relax',
      'Focus',
      'Calm',
      'Anxious',
      'Stressed'
    ];
    final List<String> imagePaths = [
      'assets/feeling_image/relax.png', // Path to Relax image
      'assets/feeling_image/focus.png', // Path to Focus image
      'assets/feeling_image/calm.png', // Path to Calm image
      'assets/feeling_image/anxious.png', // Path to Anxious image
      'assets/feeling_image/stressed.png', // Path to Stressed image
    ];

    String? selectedFeeling;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0x3D3A9793).withOpacity(0.3),
        // Background for the section
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Shadow color
            offset: const Offset(4, 4), // Offset of the shadow
            blurRadius: 8, // Blur radius of the shadow
            spreadRadius: 1, // Spread radius of the shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling today?',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 16,
            children: [
              // First row with three smaller buttons
              ...List.generate(3, (index) {
                return SizedBox(
                  width: 100, // Width for first row buttons
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedFeeling = feelings[index];
                      });
                      print('Selected feeling: $selectedFeeling');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedFeeling == feelings[index]
                          ? Colors.grey.withOpacity(0.5)
                          : Colors.transparent,
                      elevation: 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          imagePaths[index],
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feelings[index],
                          style: const TextStyle(
                              color: Colors.black, fontSize: 15),
                        ),
                      ],
                    ),
                  ),

                );
              }),
            ],
          ),
          const SizedBox(height: 10), // Space between first and second row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Second row with two larger buttons centered
              ...List.generate(2, (index) {
                return SizedBox(
                  width: 120, // Width for second row buttons
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedFeeling = feelings[index + 3];
                      });
                      print('Selected feeling: $selectedFeeling');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedFeeling == feelings[index + 3]
                          ? Colors.grey.withOpacity(0.5)
                          : Colors.transparent,
                      elevation: 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          imagePaths[index + 3],
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feelings[index + 3],
                          style: const TextStyle(
                              color: Colors.black, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedForYouSection() {
    final List<Map<String, String>> recommendedSongs = [
      {'title': 'Calm Breeze', 'artist': 'Artist 1'},
      {'title': 'Soothing Waves', 'artist': 'Artist 2'},
      {'title': 'Focus Vibes', 'artist': 'Artist 3'},
      {'title': 'Relaxation Tones', 'artist': 'Artist 4'},
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // Adjust according to your theme
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended for you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Column(
            children: recommendedSongs.map((song) {
              return ListTile(
                leading: const Icon(Icons.music_note, color: Colors.teal),
                // Icon or thumbnail
                title: Text(song['title']!),
                subtitle: Text(song['artist']!),
                onTap: () {
                  // Logic to play the song or navigate to detailed view
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capture your cares, craft your calm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/qna');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.question_answer,
                            size: 50, color: Colors.blue),
                        SizedBox(height: 10),
                        Text(
                          'Let\'s Do a Q&A',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/journal');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.greenAccent, width: 2),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note, size: 50, color: Colors.green),
                        SizedBox(height: 10),
                        Text(
                          'Journal Section',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SizedBox(
      height: 80, // Set your desired height here
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B3534),
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
          // Navigate to different screens based on index
          switch (_currentIndex) {
            case 0:
              Navigator.pushNamed(context, '/chatbot');
              break;
            case 1:
              Navigator.pushNamed(context, '/music');
              break;
            case 2:
              break;
            case 3:
              Navigator.pushNamed(context, '/games');
              break;
            case 4:
              Navigator.pushNamed(context, '/profile');
              break;
            case 5:
              Navigator.pushNamed(context, '/dashboard');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'ChatBot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Music',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games_outlined),
            label: 'Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Dashboard',
          ),
        ],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.green,
        selectedLabelStyle: TextStyle(color: Colors.green[300]),
        unselectedLabelStyle: TextStyle(color: Colors.green[300]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3534),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF3FFFF),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MeditationTimer(),
              // 🔥 Streak Tracker Section
              const SizedBox(height: 20),
              _buildJournalSection(), // Updated method name here
              const SizedBox(height: 20),
              const Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B3534),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [
                  _buildMoodButton('Relax'),
                  _buildMoodButton('Focus'),
                  _buildMoodButton('Calm'),
                  _buildMoodButton('Anxious'),
                ],
              ),
              if (selectedMood != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Recommended for your $selectedMood mood:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B3534),
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
Widget _buildStreakTile({
  required IconData icon,
  required String title,
  required int streakCount,
  required String lastDone,
  required VoidCallback onPressed,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 5,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.teal.withOpacity(0.2),
          child: Icon(icon, color: Colors.teal, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Streak: $streakCount days\nLast done: $lastDone",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B3534),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Mark Done'),
        ),
      ],
    ),
  );
}
