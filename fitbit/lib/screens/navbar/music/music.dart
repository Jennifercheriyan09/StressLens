import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentlyPlayingTitle;
  int _currentIndex = 1; // Default to music being selected
  String _selectedGenre = 'All';
  String _searchQuery = ''; // Variable to hold the search query

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Clean up the player when the widget is disposed
    super.dispose();
  }

  final List<Map<String, String>> musicList = [
    {
      "title": "Retro Vibes",
      "genre": "Youth-Focused",
      "image": "assets/music/retro_vibes.png",
      "url": "assets/music/music_files/retro_vibes.mp3"
    },
    {
      "title": "Soulful Symphony",
      "genre": "Youth-Focused",
      "image": "assets/music/soulful_symphony.png",
      "url": "assets/music/music_files/soulful_symphony.mp3"
    },
    {
      "title": "Forest Dawn",
      "genre": "Seasonal/ASMR",
      "image": "assets/music/forest_dawn.png",
      "url": "assets/music/music_files/forest_dawn.mp3"
    },
    {
      "title": "Groove Wave",
      "genre": "Youth-Focused",
      "image": "assets/music/groove_wave.png",
      "url": "assets/music/music_files/groove_wave.mp3"
    },
    {
      "title": "Fireplace Glow",
      "genre": "Seasonal/ASMR",
      "image": "assets/music/fireplace_glow.png",
      "url": "assets/music/music_files/fireplace_glow.mp3"
    },
    {
      "title": "Ocean of Peace",
      "genre": "Calm & Soothing",
      "image": "assets/music/ocean_of_peace.png",
      "url": "assets/music/music_files/ocean_of_peace.mp3"
    },
    {
      "title": "Tranquil Paths",
      "genre": "Calm & Soothing",
      "image": "assets/music/tranquil_paths.png",
      "url": "assets/music/music_files/tranquil_paths.mp3"
    },
    {
      "title": "Soft Glow",
      "genre": "Calm & Soothing",
      "image": "assets/music/soft_glow.png",
      "url": "assets/music/music_files/soft_glow.mp3"
    },
    {
      "title": "Electric Sunset",
      "genre": "Youth-Focused",
      "image": "assets/music/electric_sunset.png",
      "url": "assets/music/music_files/electric_sunset.mp3"
    },
    {
      "title": "Gentle Winds",
      "genre": "Calm & Soothing",
      "image": "assets/music/gentle_winds.png",
      "url": "assets/music/music_files/gentle_winds.mp3"
    },
    {
      "title": "Thunderstorm Calm",
      "genre": "Seasonal/ASMR",
      "image": "assets/music/thunderstorm_calm.png",
      "url": "assets/music/music_files/thunderstorm_calm.mp3"
    },
    {
      "title": "Mountain Breeze",
      "genre": "Seasonal/ASMR",
      "image": "assets/music/mountain_breeze.png",
      "url": "assets/music/music_files/mountain_breeze.mp3"
    },
    {
      "title": "Feel the Flow",
      "genre": "Youth-Focused",
      "image": "assets/music/feel_the_flow.png",
      "url": "assets/music/music_files/feel_the_flow.mp3"
    },
    {
      "title": "Calm Waves",
      "genre": "Calm & Soothing",
      "image": "assets/music/calm_waves.png",
      "url": "assets/music/music_files/calm_waves.mp3"
    },
    {
      "title": "Birdsong Bliss",
      "genre": "Seasonal/ASMR",
      "image": "assets/music/birdsong.png",
      "url": "assets/music/music_files/birdsong.mp3"
    }
  ];

  List<Map<String, String>> get filteredMusicList {
    return musicList.where((music) {
      final matchesGenre =
          _selectedGenre == 'All' || music['genre'] == _selectedGenre;
      final matchesSearch =
      music['title']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesGenre && matchesSearch;
    }).toList();
  }

  Future<void> _playMusic(String title, String url) async {
    try {
      if (_currentlyPlayingTitle == title && _isPlaying) {
        // If already playing, do nothing here
        return;
      } else {
        // Play new song or resume
        if (_currentlyPlayingTitle != title) {
          await _audioPlayer.setAsset(url);
        }
        await _audioPlayer.play();
        setState(() {
          _currentlyPlayingTitle = title;
          _isPlaying = true;
        });
      }
    } catch (e) {
      print("Error playing music: $e");
    }
  }

  Future<void> _pauseMusic() async {
    try {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      print("Error pausing music: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music'),
        backgroundColor: const Color(0xFF0B3534), // Dark green AppBar
      ),
      backgroundColor: const Color(0xFFD1FFFF), // Light background color
      body: Column(
        children: [
          // Curved Search Box
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color of the search box
                borderRadius: BorderRadius.circular(30.0), // Curve the corners
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search Music Here',
                        border: InputBorder.none, // Remove the default border
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value; // Update the search query
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        // The search will be automatically applied in filteredMusicList
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _showGenreSelectionDialog,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF0B3534), // White text
            ),
            child: const Text('Select Music Genre'),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two items per row
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.8, // Adjusts height of each card
              ),
              itemCount: filteredMusicList.length,
              itemBuilder: (context, index) {
                return _buildMusicTile(
                  filteredMusicList[index]["title"]!,
                  filteredMusicList[index]["genre"]!,
                  filteredMusicList[index]["image"]!,
                  '3:45', // Placeholder duration
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildMusicTile(
      String title, String genre, String imagePath, String duration) {
    bool isCurrentlyPlaying = _currentlyPlayingTitle == title && _isPlaying;

    return InkWell(
      onTap: () async {
        final musicItem =
        musicList.firstWhere((item) => item['title'] == title);
        // Start playing immediately
        await _playMusic(title, musicItem['url']!);
        // Show the popup with a blurred background
        await _showMusicPopup(title, musicItem['image']!);
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
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
                Icon(
                  isCurrentlyPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  size: 40,
                  color: Colors.white,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    genre,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    duration,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMusicPopup(String title, String imagePath) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: "Music Popup",
      barrierDismissible: false, // Prevent dismissing by tapping outside
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(imagePath,
                      width: 150, height: 150, fit: BoxFit.cover),
                  const SizedBox(height: 20),
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.pause_circle, size: 50),
                    onPressed: () async {
                      // Pause the music and then close the popup
                      await _pauseMusic();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showGenreSelectionDialog() async {
    String? selectedGenre = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Music Genre'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Seasonal/ASMR'),
                onTap: () => Navigator.pop(context, 'Seasonal/ASMR'),
              ),
              ListTile(
                title: const Text('Calm & Soothing'),
                onTap: () => Navigator.pop(context, 'Calm & Soothing'),
              ),
              ListTile(
                title: const Text('Youth-Focused'),
                onTap: () => Navigator.pop(context, 'Youth-Focused'),
              ),
            ],
          ),
        );
      },
    );

    setState(() {
      _selectedGenre = selectedGenre!;
    });
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

              break;
            case 2:
              Navigator.pushNamed(context, '/home');
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
}
