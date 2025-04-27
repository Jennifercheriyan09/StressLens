import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'editprofile.dart';
import '../../home/streak_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 4; // Default to profile being selected
  String? userEmail;
  int? userStreak;
  String? userName ;
  final String profileImagePath = 'assets/user_image.png';

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
    _fetchUserStreak();
  }

  Future<void> _fetchUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      userEmail = user?.email; // Fetch and set the user's email
      userName = user?.displayName;
    });
  }
Future<void> _fetchUserStreak() async {
  try {
    final data = await StreakService.getUserStreakData();
    if (data != null && mounted) {
      setState(() {
        userStreak = data['streakCount'];
      });
    }
  } catch (e) {
    print('Error fetching streak: $e');
  }
}

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 75,
                backgroundImage: AssetImage(profileImagePath),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () {
                    // Add functionality to upload/edit profile picture
                  },
                  color: const Color(0xFF0B3534),
                  iconSize: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hello, $userName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userEmail ?? 'Loading...',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        _buildCard(
          title: 'Daily Stress Tracker',
value: userStreak != null ? '$userStreak Days Streak' : 'Loading...',
          icon: Icons.stacked_bar_chart,
          color: Colors.green,
        ),
        _buildCard(
          title: 'Meditation Sessions',
          value: '10 Sessions Completed',
          icon: Icons.self_improvement,
          color: Colors.blue,
        ),
        _buildCard(
          title: 'Preferred Activities',
          value: 'Yoga, Music, Walks',
          icon: Icons.favorite,
          color: Colors.pink,
        ),
      ],
    );
  }

  Widget _buildCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF0B3534),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildInfoCards(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3534),
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              ),
              child: const Text('Edit Profile',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
              Navigator.pushNamed(context, '/home');
              break;
            case 3:
              Navigator.pushNamed(context, '/games');
              break;
            case 4:
              // Navigator.pushNamed(context, '/profile');
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
