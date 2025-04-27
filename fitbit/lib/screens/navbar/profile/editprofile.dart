import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String email = 'user@example.com'; // Replace with actual user email
  String name = 'User Admin'; // Replace with actual user name
  int age = 25; // Replace with actual age
  String gender = 'Male'; // Replace with actual gender
  String bloodPressure = '120/80'; // Replace with actual blood pressure
  String pulse = '72'; // Replace with actual pulse
  String hrv = '40'; // Heart Rate Variability
  String respirationRate = '16'; // Respiration Rate
  String temperature = '36.5'; // Body Temperature
  String muscleTension = 'Low'; // Muscle Tension
  String sleepQuality = 'Good'; // Sleep Quality
  String mood = 'Happy'; // Current Mood
  String? uploadedFileName;
  int _currentIndex = 4; // Assuming profile is at index 4

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController bloodPressureController = TextEditingController();
  final TextEditingController pulseController = TextEditingController();
  final TextEditingController hrvController = TextEditingController();
  final TextEditingController respirationRateController =
      TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController muscleTensionController = TextEditingController();
  final TextEditingController sleepQualityController = TextEditingController();
  final TextEditingController moodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = name;
    ageController.text = age.toString();
    genderController.text = gender;
    bloodPressureController.text = bloodPressure;
    pulseController.text = pulse;
    hrvController.text = hrv;
    respirationRateController.text = respirationRate;
    temperatureController.text = temperature;
    muscleTensionController.text = muscleTension;
    sleepQualityController.text = sleepQuality;
    moodController.text = mood;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF0B3534),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Details Section
            const Text('Personal Details',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            _buildEditableRow('Name', nameController, _saveName),
            _buildEditableRow('Age', ageController, _saveAge),
            _buildEditableRow('Gender', genderController, _saveGender),

            const SizedBox(height: 20),
            // Medical Details Section
            const Text('Medical Details',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            _buildEditableRow('Blood Pressure (mmHg)', bloodPressureController,
                _saveBloodPressure),
            _buildEditableRow('Pulse (bpm)', pulseController, _savePulse),
            _buildEditableRow('HRV (ms)', hrvController, _saveHRV),
            _buildEditableRow('Respiration Rate (breaths/min)',
                respirationRateController, _saveRespirationRate),
            _buildEditableRow('Body Temperature (°C)', temperatureController,
                _saveTemperature),
            _buildEditableRow('Muscle Tension (High / Low)',
                muscleTensionController, _saveMuscleTension),
            _buildEditableRow('Sleep Quality (Good / Moderate / Bad)',
                sleepQualityController, _saveSleepQuality),
            _buildEditableRow(
                'Mood (Happy / Moderate / Sad)', moodController, _saveMood),

            const SizedBox(height: 20),
            _buildUploadSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Helper method for displaying editable rows
  Widget _buildEditableRow(
      String label, TextEditingController controller, VoidCallback onSave) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: controller,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: onSave,
          ),
        ],
      ),
    );
  }

  // Helper method for the file upload section
  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload Medical Report',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text('Choose File'),
          onPressed: _uploadFile,
        ),
        if (uploadedFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Uploaded: $uploadedFileName'),
          ),
      ],
    );
  }

  // Save methods for each field
  void _saveName() {
    setState(() {
      name = nameController.text;
    });
    print('Name saved: $name');
  }

  void _saveAge() {
    setState(() {
      age = int.tryParse(ageController.text) ??
          age; // fallback to previous value if parsing fails
    });
    print('Age saved: $age');
  }

  void _saveGender() {
    setState(() {
      gender = genderController.text;
    });
    print('Gender saved: $gender');
  }

  void _saveBloodPressure() {
    setState(() {
      bloodPressure = bloodPressureController.text;
    });
    print('Blood Pressure saved: $bloodPressure');
  }

  void _savePulse() {
    setState(() {
      pulse = pulseController.text;
    });
    print('Pulse saved: $pulse');
  }

  void _saveHRV() {
    setState(() {
      hrv = hrvController.text;
    });
    print('HRV saved: $hrv');
  }

  void _saveRespirationRate() {
    setState(() {
      respirationRate = respirationRateController.text;
    });
    print('Respiration Rate saved: $respirationRate');
  }

  void _saveTemperature() {
    setState(() {
      temperature = temperatureController.text;
    });
    print('Body Temperature saved: $temperature');
  }

  void _saveMuscleTension() {
    setState(() {
      muscleTension = muscleTensionController.text;
    });
    print('Muscle Tension saved: $muscleTension');
  }

  void _saveSleepQuality() {
    setState(() {
      sleepQuality = sleepQualityController.text;
    });
    print('Sleep Quality saved: $sleepQuality');
  }

  void _saveMood() {
    setState(() {
      mood = moodController.text;
    });
    print('Mood saved: $mood');
  }

  // Define the file upload method
  void _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        uploadedFileName = result.files.single.name;
      });
      print('File selected: ${result.files.single.name}');
    }
  }

  // Build bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return SizedBox(
      height: 90, // Set your desired height here
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B3534),
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
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
              break; // Already on profile, no need to navigate
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
        ],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.green[300],
        selectedLabelStyle: TextStyle(color: Colors.green[300]),
        unselectedLabelStyle: TextStyle(color: Colors.green[300]),
      ),
    );
  }
}
