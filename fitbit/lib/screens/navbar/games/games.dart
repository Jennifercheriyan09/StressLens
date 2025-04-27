import 'package:flutter/material.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _currentIndex = 3; // Default to games being selected

  // Reuse the BottomNavigationBar
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
              Navigator.pushNamed(context, '/home');
              break;
            case 3:
              // Navigator.pushNamed(context, '/games');
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
            label: 'Dasboard',
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
        title: const Text('Games'),
        backgroundColor: const Color(0xFF0B3534), // Dark green AppBar
      ),
      backgroundColor: const Color(0xFFF3FFFF), // Light background color
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          // Center the column
          child: SingleChildScrollView(
            // Enable scrolling
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              children: [
                _buildGameCard('Flower Bloom', 'assets/games/flower_bloom.png',
                    '/flower_bloom'),
                const SizedBox(height: 32), // Space between cards
                _buildGameCard(
                    'Chill Farm', 'assets/games/chill_farm.png', '/chill_farm'),
                const SizedBox(height: 32),
                _buildGameCard(
                    'Bubble Pop', 'assets/games/bubble_pop.png', '/bubble_pop')
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildGameCard(String title, String imagePath, String route) {
    return SizedBox(
      width: 280, // Increased width for the game cards
      child: Card(
        color: const Color(0xFF0B3534), // Dark card background
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              children: [
                Image.asset(imagePath,
                    width: 150, height: 150), // Centered image
                const SizedBox(height: 8), // Space between image and text
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28, // Font size for the title
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
