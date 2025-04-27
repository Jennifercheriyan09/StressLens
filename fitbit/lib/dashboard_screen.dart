import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

final random = Random();

String? predictedStressLevel = "Waiting...";
final storage = FlutterSecureStorage();

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedDayOffset = 0; // 0 = Today, 1 = Yesterday, etc.

  StreamSubscription? _linkSub;
  String aiPredictionResult = "Loading AI prediction...";
  String recommendationResult = "Loading recommendations...";

  String? heartRate = "Fetching...";
  String? steps = "Fetching...";
  String? calories = "Fetching...";
  String? zoneMinutes = "Fetching...";
  String? sleepSummary = "Fetching...";
  String? hrv = "Fetching...";

  List<double> hourlyHeartRate = List.filled(24, 0.0);
  List<double> hourlySteps = List.filled(24, 0.0);
  List<double> hourlyCalories = List.filled(24, 0.0);
  List<double> hourlyStressLevels =
      List.filled(24, 0.0); // We'll map predictions

  final String clientId = '23Q3HG';
  final String clientSecret = 'a835dae2b567c1502203f6e795c59c4a';
  final String redirectUri = 'com.example.fitbit://callback';

  @override
  void initState() {
    super.initState();
    clearTokensAtStart();
    initUniLinks();
    fetchFitbitData().then((_) => fetchAndPredictHourlyStress());
    fetchAiAndRecommendations(); // Fetch AI predictions after graphs
    startHourlyAutoSave();
  }

  void startHourlyAutoSave() {
    Timer.periodic(Duration(hours: 1), (timer) {
      saveTodayDataAuto();
    });
  }

  Future<void> clearTokensAtStart() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    print("🧹 Tokens cleared at app start!");
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void initUniLinks() {
    _linkSub = uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code'];
        exchangeCodeForToken(code!);
      }
    });
  }

  Future<void> launchFitbitLogin() async {
    final scope =
        Uri.encodeComponent('profile heartrate activity sleep weight');
    final redirectUriEncoded = Uri.encodeComponent(redirectUri);
    final authUrl = 'https://www.fitbit.com/oauth2/authorize?response_type=code'
        '&client_id=$clientId&redirect_uri=$redirectUriEncoded&scope=$scope&expires_in=604800';

    try {
      await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      print("❌ Error launching Fitbit URL: $e");
    }
  }

  Future<void> exchangeCodeForToken(String code) async {
    final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
    final response = await http.post(
      Uri.parse('https://api.fitbit.com/oauth2/token'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': clientId,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
        'code': code,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      await storage.write(key: 'access_token', value: json['access_token']);
      await storage.write(key: 'refresh_token', value: json['refresh_token']);
      fetchFitbitData();
    } else {
      print('❌ Token Exchange Error: ${response.body}');
    }
  }

  int toInt(String? val) => int.tryParse(val ?? '') ?? 0;
  double toDouble(String? val) => double.tryParse(val ?? '') ?? 0.0;
  Future<void> savePast7DaysData() async {
    final now = DateTime.now();
    final firestore = FirebaseFirestore.instance;
    final token = await storage.read(key: 'access_token');
    if (token == null) {
      print("❌ No Access Token");
      return;
    }

    final headers = {'Authorization': 'Bearer $token'};

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final selectedDate = now.subtract(Duration(days: dayOffset));
      final formattedDate =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      final docSnapshot = await firestore
          .collection('user_health_data')
          .doc(formattedDate)
          .get();

      if (docSnapshot.exists) {
        print("✅ $formattedDate already exists. Skipping...");
        continue;
      }

      try {
        // Fetch heart, steps, calories
        final heartUrl =
            'https://api.fitbit.com/1/user/-/activities/heart/date/$formattedDate/1d/1min.json';
        final stepsUrl =
            'https://api.fitbit.com/1/user/-/activities/steps/date/$formattedDate/1d/1min.json';
        final caloriesUrl =
            'https://api.fitbit.com/1/user/-/activities/calories/date/$formattedDate/1d/1min.json';

        final responses = await Future.wait([
          http.get(Uri.parse(heartUrl), headers: headers),
          http.get(Uri.parse(stepsUrl), headers: headers),
          http.get(Uri.parse(caloriesUrl), headers: headers),
        ]);

        if (responses.any((r) => r.statusCode != 200)) {
          print('❌ Failed fetching intraday for $formattedDate');
          continue;
        }

        final heartData =
            jsonDecode(responses[0].body)['activities-heart-intraday']
                ['dataset'];
        final stepsData =
            jsonDecode(responses[1].body)['activities-steps-intraday']
                ['dataset'];
        final caloriesData =
            jsonDecode(responses[2].body)['activities-calories-intraday']
                ['dataset'];

        Map<int, List<double>> heartBuckets = {},
            stepBuckets = {},
            calorieBuckets = {};
        for (int h = 0; h < 24; h++) {
          heartBuckets[h] = [];
          stepBuckets[h] = [];
          calorieBuckets[h] = [];
        }

        void groupByHour(List<dynamic> data, Map<int, List<double>> bucket) {
          for (var entry in data) {
            final time = entry['time'];
            final value = (entry['value'] as num).toDouble();
            final hour = int.tryParse(time.split(":")[0]) ?? 0;
            bucket[hour]?.add(value);
          }
        }

        groupByHour(heartData, heartBuckets);
        groupByHour(stepsData, stepBuckets);
        groupByHour(caloriesData, calorieBuckets);

        Map<String, dynamic> hourlyData = {};

        for (int h = 0; h < 24; h++) {
          final hrAvg = heartBuckets[h]!.isNotEmpty
              ? (heartBuckets[h]!.reduce((a, b) => a + b) /
                      heartBuckets[h]!.length)
                  .round()
              : 0;
          final stepsSum = stepBuckets[h]!.isNotEmpty
              ? stepBuckets[h]!.reduce((a, b) => a + b).round()
              : 0;
          final calSum = calorieBuckets[h]!.isNotEmpty
              ? calorieBuckets[h]!.reduce((a, b) => a + b).round()
              : 0;

          final hourString = h.toString().padLeft(2, '0');

          hourlyData[hourString] = {
            "heart_rate": hrAvg,
            "steps": stepsSum,
            "calories": calSum,
          };
        }

        // Save hourly + static data
        await firestore.collection('user_health_data').doc(formattedDate).set({
          "date": formattedDate,
          "data": hourlyData,
          "summary": {
            "resting_hr": heartRate ?? "N/A",
            "sleep_summary": sleepSummary ?? "N/A",
            "hrv": hrv ?? "N/A",
            "azm": zoneMinutes ?? "N/A",
          },
        });

        print("✅ Saved full data for $formattedDate!");
      } catch (e) {
        print('❌ Error fetching/saving for $formattedDate: $e');
      }
    }
  }

  Future<void> saveTodayDataAuto() async {
    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final firestore = FirebaseFirestore.instance;

    Map<String, dynamic> hourlyData = {};

    for (int h = 0; h <= now.hour; h++) {
      hourlyData[h.toString().padLeft(2, '0')] = {
        "heart_rate": hourlyHeartRate[h].round(),
        "steps": hourlySteps[h].round(),
        "calories": hourlyCalories[h].round(),
      };
    }

    await firestore.collection('user_health_data').doc(formattedDate).set({
      "date": formattedDate,
      "data": hourlyData,
      "summary": {
        "resting_hr": heartRate ?? "N/A",
        "sleep_summary": sleepSummary ?? "N/A",
        "hrv": hrv ?? "N/A",
        "azm": zoneMinutes ?? "N/A",
      },
    });

    print("✅ Auto-saved latest data for Today!");
  }

  Future<String?> fetchAiPrediction(Map<String, dynamic> healthData) async {
    final url = Uri.parse('https://stress-api-lafw.onrender.com/ai_predict');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(healthData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stress_level'];
      } else {
        print('❌ Server error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Request error: $e');
      return null;
    }
  }

  Future<String?> fetchRecommendations(Map<String, dynamic> healthData) async {
    final url =
        Uri.parse('https://stress-api-lafw.onrender.com/recommendations');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(healthData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['recommendations'];
      } else {
        print('❌ Server error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Request error: $e');
      return null;
    }
  }

  Future<void> fetchAiAndRecommendations() async {
    final now = DateTime.now();

    final healthData = {
      "heart_rate": hourlyHeartRate[now.hour.round()].round(),
      "steps": hourlySteps[now.hour.round()].round(),
      "calories": hourlyCalories[now.hour.round()].round(),
      "azm": int.tryParse(zoneMinutes ?? "0") ?? 0,
      "resting_hr": int.tryParse(heartRate ?? "70") ?? 70,
      "hrv": double.tryParse(hrv ?? "30.0") ?? 30.0,
      "sleep_minutes": sleepSummary != null && sleepSummary!.contains("Asleep")
          ? int.parse(
              RegExp(r"Asleep: (\d+)").firstMatch(sleepSummary!)?.group(1) ??
                  '420')
          : 420,
      "sleep_efficiency": 0.85,
    };

    try {
      final aiResponse = await http.post(
        Uri.parse('https://stress-api-lafw.onrender.com/ai_predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(healthData),
      );

      final recoResponse = await http.post(
        Uri.parse('https://stress-api-lafw.onrender.com/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(healthData),
      );

      if (aiResponse.statusCode == 200 && recoResponse.statusCode == 200) {
        final aiData = jsonDecode(aiResponse.body);
        final recoData = jsonDecode(recoResponse.body);

        String level = aiData['stress_level'];
        double score = aiData['score'];

        setState(() {
          aiPredictionResult = formatStressLevel(level, score);
          recommendationResult = formatRecommendations(recoData);
        });
      } else {
        setState(() {
          aiPredictionResult = "Unable to fetch AI prediction.";
          recommendationResult = "Unable to fetch recommendations.";
        });
      }
    } catch (e) {
      print("Error fetching AI/recommendations: $e");
    }
  }

  String formatStressLevel(String level, double score) {
    String emoji;
    Color color;

    if (level == "Low") {
      emoji = "🟢"; // green
    } else if (level == "Medium") {
      emoji = "🟡"; // yellow
    } else {
      emoji = "🔴"; // red
    }

    return "$emoji Stress Level: $level\nConfidence: ${(score * 100).toStringAsFixed(1)}%";
  }

  String formatRecommendations(Map<String, dynamic> recoData) {
    String formatted = "";

    if (recoData.containsKey('summary')) {
      formatted += "📋 Summary:\n";
      for (var item in recoData['summary']) {
        formatted += "• $item\n";
      }
      formatted += "\n";
    }

    if (recoData.containsKey('warnings')) {
      formatted += "⚡ Warning:\n";
      formatted += recoData['warnings'] + "\n\n";
    }

    if (recoData.containsKey('recommendations')) {
      formatted += "🌿 Recommendations:\n";
      for (var tip in recoData['recommendations']) {
        formatted += "• $tip\n";
      }
      formatted += "\n";
    }

    if (recoData.containsKey('note')) {
      formatted += "📝 Note:\n";
      formatted += recoData['note'];
    }

    return formatted.trim();
  }

  Future<void> loadSelectedDayFromFirestore() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final selectedDate = now.subtract(Duration(days: selectedDayOffset));
    final formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    try {
      final docSnapshot = await firestore
          .collection('user_health_data')
          .doc(formattedDate)
          .get();

      if (!docSnapshot.exists) {
        print("❌ No data found for $formattedDate in Firestore");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No data found for $formattedDate'),
        ));
        return;
      }

      final data = docSnapshot.data();
      final hourlyData = data?['data'] as Map<String, dynamic>;

      setState(() {
        for (int h = 0; h < 24; h++) {
          final hourString = h.toString().padLeft(2, '0');
          final hourEntry = hourlyData[hourString];
          if (hourEntry != null) {
            hourlyHeartRate[h] = (hourEntry['heart_rate'] ?? 0).toDouble();
            hourlySteps[h] = (hourEntry['steps'] ?? 0).toDouble();
            hourlyCalories[h] = (hourEntry['calories'] ?? 0).toDouble();
          } else {
            hourlyHeartRate[h] = 0.0;
            hourlySteps[h] = 0.0;
            hourlyCalories[h] = 0.0;
          }
        }
      });

      print("✅ Loaded data for $formattedDate");
    } catch (e) {
      print('❌ Error loading from Firestore: $e');
    }
  }

  Future<void> fetchFitbitData() async {
    final token = await storage.read(key: 'access_token');
    if (token == null) return;

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final now = DateTime.now();
      final selectedDate = now
          .subtract(Duration(days: selectedDayOffset)); // ✅ This is important
      final formattedDate =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      final responses = await Future.wait([
        http.get(
            Uri.parse(
                'https://api.fitbit.com/1/user/-/activities/heart/date/$formattedDate/1d.json'),
            headers: headers),
        http.get(
            Uri.parse(
                'https://api.fitbit.com/1/user/-/activities/date/$formattedDate.json'),
            headers: headers),
        http.get(
            Uri.parse(
                'https://api.fitbit.com/1.2/user/-/sleep/date/$formattedDate.json'),
            headers: headers),
        http.get(
            Uri.parse(
                'https://api.fitbit.com/1/user/-/hrv/date/$formattedDate.json'),
            headers: headers),
        http.get(
            Uri.parse(
                'https://api.fitbit.com/1/user/-/activities/active-zone-minutes/date/$formattedDate/1d.json'),
            headers: headers),
      ]);

      setState(() {
        // ✅ Heart Rate safely
        if (responses[0].statusCode == 200) {
          final data = jsonDecode(responses[0].body);
          final heartList = data['activities-heart'];
          if (heartList != null && heartList is List && heartList.isNotEmpty) {
            heartRate =
                heartList[0]['value']?['restingHeartRate']?.toString() ??
                    'No data';
          } else {
            heartRate = 'No data';
          }
        }

        // ✅ Steps and Calories safely
        if (responses[1].statusCode == 200) {
          final data = jsonDecode(responses[1].body);
          steps = data['summary']?['steps']?.toString() ?? '0';
          calories = data['summary']?['caloriesOut']?.toString() ?? '0';
        }

        // ✅ Sleep safely
        if (responses[2].statusCode == 200) {
          final summary = jsonDecode(responses[2].body)['summary'];
          final asleep = summary?['totalMinutesAsleep'];
          final inBed = summary?['totalTimeInBed'];
          sleepSummary = (asleep != null && inBed != null)
              ? 'Asleep: $asleep mins, In bed: $inBed mins'
              : 'No data';
        }

        // ✅ HRV safely
        if (responses[3].statusCode == 200) {
          final data = jsonDecode(responses[3].body);
          final hrvList = data['hrv'];
          if (hrvList != null && hrvList is List && hrvList.isNotEmpty) {
            hrv = hrvList[0]['value']?['dailyRmssd']?.toString() ?? 'No data';
          } else {
            hrv = 'No data';
          }
        }

        // ✅ AZM safely
        if (responses[4].statusCode == 200) {
          final data = jsonDecode(responses[4].body);
          final azmList = data['activities-active-zone-minutes'];
          if (azmList != null && azmList is List && azmList.isNotEmpty) {
            zoneMinutes =
                azmList[0]['value']?['activeZoneMinutes']?.toString() ?? '0';
          } else {
            zoneMinutes = '0';
          }
        }
      });
    } catch (e) {
      print('❌ Error fetching Fitbit Data: $e');
    }
  }

  Future<String?> predictStressLevel(Map<String, dynamic> healthData) async {
    final url = Uri.parse('https://stress-api-lafw.onrender.com/predict');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(healthData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stress_level'];
      } else {
        print('❌ Server error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Request error: $e');
      return null;
    }
  }

  Future<void> fetchAndPredictHourlyStress() async {
    final token = await storage.read(key: 'access_token');
    if (token == null) return;

    final headers = {'Authorization': 'Bearer $token'};
    final now = DateTime.now();
    final selectedDate = now.subtract(Duration(days: selectedDayOffset));
    final formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final heartUrl =
        'https://api.fitbit.com/1/user/-/activities/heart/date/$formattedDate/1d/1min.json';
    final stepsUrl =
        'https://api.fitbit.com/1/user/-/activities/steps/date/$formattedDate/1d/1min.json';
    final caloriesUrl =
        'https://api.fitbit.com/1/user/-/activities/calories/date/$formattedDate/1d/1min.json';

    final responses = await Future.wait([
      http.get(Uri.parse(heartUrl), headers: headers),
      http.get(Uri.parse(stepsUrl), headers: headers),
      http.get(Uri.parse(caloriesUrl), headers: headers),
    ]);

    if (responses.any((res) => res.statusCode != 200)) {
      print("❌ Error fetching intraday data");
      return;
    }

    final heartData =
        jsonDecode(responses[0].body)['activities-heart-intraday']['dataset'];
    final stepsData =
        jsonDecode(responses[1].body)['activities-steps-intraday']['dataset'];
    final caloriesData =
        jsonDecode(responses[2].body)['activities-calories-intraday']
            ['dataset'];

    Map<int, List<double>> heartBuckets = {},
        stepBuckets = {},
        calorieBuckets = {};
    final random = Random(); // ✅ Random generator

    for (int h = 0; h < 24; h++) {
      heartBuckets[h] = [];
      stepBuckets[h] = [];
      calorieBuckets[h] = [];
    }

    void groupByHour(List<dynamic> data, Map<int, List<double>> bucket) {
      for (var entry in data) {
        final time = entry['time'];
        final value = (entry['value'] as num).toDouble();
        final hour = int.tryParse(time.split(":")[0]) ?? 0;
        bucket[hour]?.add(value);
      }
    }

    groupByHour(heartData, heartBuckets);
    groupByHour(stepsData, stepBuckets);
    groupByHour(caloriesData, calorieBuckets);

    final int restingHr =
        (heartRate != null && heartRate != 'N/A') ? toInt(heartRate) : 72;
    final double parsedHrv = (hrv != null && hrv != 'No data')
        ? (toDouble(hrv) != 0.0 ? toDouble(hrv) : 30.0)
        : 30.0;
    final int sleepMins = (sleepSummary != null &&
            sleepSummary!.contains("Asleep"))
        ? int.tryParse(
                RegExp(r"Asleep: (\d+)").firstMatch(sleepSummary!)?.group(1) ??
                    '') ??
            420
        : 420;
    final int azmVal = (zoneMinutes != null && zoneMinutes != 'No data')
        ? toInt(zoneMinutes)
        : 35;
    const double sleepEfficiency = 0.85;

    int maxHour = selectedDayOffset == 0 ? now.hour : 23;

    for (int h = 0; h <= maxHour; h++) {
      if (heartBuckets[h]!.isEmpty &&
          stepBuckets[h]!.isEmpty &&
          calorieBuckets[h]!.isEmpty) {
        print("⚠️ Skipping hour $h: No data");
        continue;
      }

      final hrAvg = heartBuckets[h]!.isNotEmpty
          ? (heartBuckets[h]!.reduce((a, b) => a + b) / heartBuckets[h]!.length)
              .round()
          : restingHr;

      final stepsSum = stepBuckets[h]!.isNotEmpty
          ? stepBuckets[h]!.reduce((a, b) => a + b).round()
          : 0;

      final calSum = calorieBuckets[h]!.isNotEmpty
          ? calorieBuckets[h]!.reduce((a, b) => a + b).round()
          : 0;

      final hourlyData = {
        "heart_rate": hrAvg + (stepsSum == 0 ? 2 + random.nextInt(3) : 0),
        "steps": stepsSum == 0
            ? 25 + random.nextInt(10)
            : stepsSum + random.nextInt(5),
        "calories":
            calSum == 0 ? 12 + random.nextInt(5) : calSum + random.nextInt(3),
        "azm": azmVal == 0 ? 35 : azmVal,
        "resting_hr": restingHr,
        "hrv": parsedHrv,
        "sleep_minutes": sleepMins,
        "sleep_efficiency": sleepEfficiency,
      };

      print("📊 Hour $h → Inputs → $hourlyData");

      final result = await predictStressLevel(hourlyData);

      setState(() {
        hourlyHeartRate[h] = hrAvg.toDouble();
        hourlySteps[h] = stepsSum.toDouble();
        hourlyCalories[h] = calSum.toDouble();
        if (result == "Low") {
          hourlyStressLevels[h] = 0;
        } else if (result == "Medium") {
          hourlyStressLevels[h] = 1;
        } else if (result == "High") {
          hourlyStressLevels[h] = 2;
        } else {
          hourlyStressLevels[h] = 1; // fallback to Medium
        }
      });

      print("🕐 Hour $h → Stress: ${result ?? 'Failed'}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StressLens Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: launchFitbitLogin,
                      icon: Icon(Icons.watch),
                      label: Text("Connect Fitbit"),
                    ),
                    ElevatedButton(
                      onPressed: fetchAndPredictHourlyStress,
                      child: Text("Predict Hourly Stress"),
                    ),
                    SizedBox(width: 10),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: savePast7DaysData,
                      child: Text("Save Past 7 Days"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Your clear tokens logic
                      },
                      icon: Icon(Icons.refresh),
                      label: Text("Clear Tokens"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
// Add this before GridView.count(...)
              Row(
                children: [
                  Text(
                    "🕒 Select Day: ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<int>(
                    value: selectedDayOffset,
                    items: List.generate(7, (index) {
                      String text;
                      if (index == 0)
                        text = "Today";
                      else if (index == 1)
                        text = "Yesterday";
                      else
                        text = "$index Days Ago";
                      return DropdownMenuItem(
                        value: index,
                        child: Text(text),
                      );
                    }),
                    onChanged: (value) async {
                      setState(() {
                        selectedDayOffset = value!;
                      });

                      // 👇 Fetch new data for new day
                      loadSelectedDayFromFirestore();
                      await fetchFitbitData();
                    },
                  ),
                ],
              ),

              // Static Metrics Grid
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  healthMetricCard("❤️ Resting HR", "$heartRate bpm"),
                  healthMetricCard("👣 Steps", "$steps"),
                  healthMetricCard("\ud83d\udd25 Calories", "$calories kcal"),
                  healthMetricCard("\ud83d\udcaa AZM", "$zoneMinutes min"),
                  healthMetricCard("📌 Sleep", "$sleepSummary"),
                  healthMetricCard("💓 HRV", "$hrv ms"),
                ],
              ),

              SizedBox(height: 30),

              // Placeholder for Graphs
// 📈 Hourly Dynamic Metrics Charts
              HourlyLineChart(
                title: "Hourly Heart Rate",
                data: hourlyHeartRate,
                lineColor: Colors.red,
                selectedDayOffset: selectedDayOffset,
              ),
              HourlyLineChart(
                title: "Hourly Steps",
                data: hourlySteps,
                lineColor: Colors.blue,
                selectedDayOffset: selectedDayOffset,
              ),
              HourlyLineChart(
                title: "Hourly Calories",
                data: hourlyCalories,
                lineColor: Colors.orange,
                selectedDayOffset: selectedDayOffset,
              ),
              HourlyLineChart(
                title: "Hourly Stress Levels",
                data: hourlyStressLevels,
                lineColor: Colors.purple,
                selectedDayOffset: selectedDayOffset,
              ),
              SizedBox(height: 20), // space before AI card

              Card(
                color: Colors.green.shade50,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🔵 Current Hour Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCurrentStatItem(
                            icon: Icons.favorite,
                            label: "Heart Rate",
                            value:
                                "${hourlyHeartRate[DateTime.now().hour].round()} bpm",
                          ),
                          _buildCurrentStatItem(
                            icon: Icons.directions_walk,
                            label: "Steps",
                            value:
                                "${hourlySteps[DateTime.now().hour].round()}",
                          ),
                          _buildCurrentStatItem(
                            icon: Icons.local_fire_department,
                            label: "Calories",
                            value:
                                "${hourlyCalories[DateTime.now().hour].round()} kcal",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                  height: 20), // after this your AI prediction card will come

              SizedBox(height: 20),
              Card(
                color: Colors.lightBlue.shade50,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🧠 AI Stress Insight",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        aiPredictionResult,
                        style: TextStyle(fontSize: 16),
                      ),
                      Divider(height: 20, color: Colors.blueGrey),
                      Text(
                        "🧩 Recommendations:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        recommendationResult,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildCurrentStatItem(
    {required IconData icon, required String label, required String value}) {
  return Column(
    children: [
      Icon(icon, size: 30, color: Colors.teal),
      SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 14)),
    ],
  );
}

Widget healthMetricCard(String title, String value) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18)),
        ],
      ),
    ),
  );
}

class HourlyLineChart extends StatelessWidget {
  final String title;
  final List<double> data;
  final Color lineColor;
  final int selectedDayOffset;

  const HourlyLineChart({
    required this.title,
    required this.data,
    required this.lineColor,
    required this.selectedDayOffset,
  });
  double _getYAxisInterval(String title) {
    if (title.toLowerCase().contains('stress')) {
      return 1; // ✅ Stress Levels (0,1,2) need interval 1
    } else if (title.toLowerCase().contains('steps')) {
      return 500; // Steps chart
    } else if (title.toLowerCase().contains('calories')) {
      return 50; // Calories chart
    } else {
      return 20; // Default for Heart Rate chart
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isToday = (selectedDayOffset == 0);
    final int maxHour = isToday ? DateTime.now().hour : 23;

    List<FlSpot> visibleSpots = data
        .asMap()
        .entries
        .where((e) => e.key <= maxHour)
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList(); // ✅ Only till now

    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 4,
                        getTitlesWidget: (value, meta) {
                          if (value % 4 == 0) {
                            return Text(
                              '${value.toInt()}h',
                              style: TextStyle(fontSize: 10),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: _getYAxisInterval(title),
                        getTitlesWidget: (value, meta) {
                          if (value % _getYAxisInterval(title) == 0) {
                            return Text(
                              '${value.toInt()}',
                              style: TextStyle(fontSize: 10),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    verticalInterval: 4,
                    horizontalInterval: _getYAxisInterval(title),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 1),
                      left: BorderSide(color: Colors.black, width: 1),
                      top: BorderSide(color: Colors.transparent),
                      right: BorderSide(color: Colors.transparent),
                    ),
                  ),
                  minX: 0,
                  maxX: 23, // All 24 hours
                  minY: title.toLowerCase().contains('stress') ? 0 : 0,
                  maxY: title.toLowerCase().contains('stress')
                      ? 2
                      : (visibleSpots.isEmpty
                          ? 10
                          : (visibleSpots
                                  .map((e) => e.y)
                                  .reduce((a, b) => a > b ? a : b)) +
                              _getYAxisInterval(title)),

                  lineBarsData: [
                    LineChartBarData(
                      spots: visibleSpots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withOpacity(0.2),
                      ),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
