import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

// 🛠️ นำเข้า Service และ Helper ที่แยกไว้
import 'package:project/service/plants_service.dart';
import 'package:project/modal/plant_recommendation_helper.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  double currentTemp = 0;
  double maxTemperature = 0;
  double minTemperature = 0;

  int currentHumidity = 0;
  double windSpeed = 0;

  String weatherCondition = "";
  String currentDate = "";
  List<Map<String, dynamic>> hourlyForecast = [];
  bool isLoading = true;
  bool isRecommending = false;
  String errorMessage = "";

  double displayLat = 0.0;
  double displayLon = 0.0;

  List<dynamic> _cachedPlants = [];

  @override
  void initState() {
    super.initState();
    _determinePositionAndFetchWeather();
    _preloadPlantsData();
  }

  Future<void> _preloadPlantsData() async {
    try {
      _cachedPlants = await PlantsService.getplants();
    } catch (e) {
      debugPrint("Error preloading plants: $e");
    }
  }

  Future<void> _determinePositionAndFetchWeather() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'กรุณาเปิดบริการระบุตำแหน่ง (GPS) บนอุปกรณ์ของคุณ';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'สิทธิ์การเข้าถึงตำแหน่งถูกปฏิเสธ';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'สิทธิ์การเข้าถึงตำแหน่งถูกปฏิเสธอย่างถาวร กรุณาเปิดสิทธิ์ในตั้งค่า';
      }

      Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw 'ระบบค้นหาพิกัดใช้เวลานานเกินไป (กำลังใช้พิกัดสำรอง)';
          },
        );
      }

      await fetchWeatherData(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
      });
      await fetchWeatherData(13.7563, 100.5018);
    }
  }

  Future<void> fetchWeatherData(double lat, double lon) async {
    try {
      if (mounted) {
        setState(() {
          displayLat = lat;
          displayLon = lon;
        });
      }

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat'
        '&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'
        '&hourly=temperature_2m,weather_code'
        '&daily=temperature_2m_max,temperature_2m_min'
        '&timezone=Asia%2FBangkok',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("API Error : ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final current = data['current'];
      final hourly = data['hourly'];
      final daily = data['daily'];

      final List<dynamic> times = hourly['time'];
      final List<dynamic> temps = hourly['temperature_2m'];
      final List<dynamic> codes = hourly['weather_code'];

      final currentTime = DateTime.parse(current["time"]);

      final currentHourString =
          "${currentTime.year.toString().padLeft(4, '0')}-"
          "${currentTime.month.toString().padLeft(2, '0')}-"
          "${currentTime.day.toString().padLeft(2, '0')}T"
          "${currentTime.hour.toString().padLeft(2, '0')}:00";

      final currentHourIndex = times.indexWhere(
        (e) => e.toString() == currentHourString,
      );

      List<Map<String, dynamic>> tempHourly = [];

      for (int i = -2; i <= 2; i++) {
        final index = currentHourIndex + i;
        if (index >= 0 && index < times.length) {
          tempHourly.add({
            "time": times[index].toString().split("T")[1].substring(0, 5),
            "temp": (temps[index] as num).toDouble(),
            "code": codes[index],
            "isCurrent": i == 0,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        currentTemp = (current["temperature_2m"] as num).toDouble();
        currentHumidity = (current["relative_humidity_2m"] as num).toInt();
        windSpeed = (current["wind_speed_10m"] as num).toDouble();
        weatherCondition = getWeatherStatus(current["weather_code"]);
        maxTemperature = (daily["temperature_2m_max"][0] as num).toDouble();
        minTemperature = (daily["temperature_2m_min"][0] as num).toDouble();

        final apiTime = DateTime.parse(current["time"]);
        currentDate =
            "${apiTime.day} ${thaiMonth(apiTime.month)} ${apiTime.year + 543}";
        hourlyForecast = tempHourly;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        weatherCondition = "ดึงข้อมูลล้มเหลว";
      });
    }
  }

  // 🟩 ฟังก์ชันเรียกใช้งาน Helper เพื่อสแกนและโชว์พืชแนะนำ
  void _recommendPlantsFromWeather() async {
    setState(() {
      isRecommending = true;
    });

    // เรียกฟังก์ชันจาก Helper สั้นๆ แค่นี้เลย!
    await PlantRecommendationHelper.showRecommendations(
      context: context,
      cachedPlants: _cachedPlants,
      temp: currentTemp,
      humidity: currentHumidity.toDouble(),
      customTitle:
          "พืชแนะนำตามสภาพอากาศ\n(อุณหภูมิ $currentTemp°C, ความชื้น $currentHumidity%)",
    );

    if (mounted) {
      setState(() {
        isRecommending = false;
      });
    }
  }

  String getWeatherStatus(int code) {
    if (code == 0) return "ท้องฟ้าโปร่ง";
    if (code <= 3) return "ท้องฟ้าแจ่มใส มีเมฆบางส่วน";
    if (code <= 48) return "หมอกลง";
    if (code <= 67) return "ฝนตกปรอยๆ";
    if (code <= 82) return "ฝนตกหนัก";
    return "พายุฝนฟ้าคะนอง";
  }

  String thaiMonth(int month) {
    const months = [
      '',
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม'
    ];
    return months[month];
  }

  IconData getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.cloud;
    if (code <= 48) return Icons.cloud_queue;
    if (code <= 67) return Icons.umbrella;
    return Icons.thunderstorm;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3A9CED), Color(0xFF76C2F9)],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 15),
                      Text(
                        errorMessage.isEmpty
                            ? "กำลังค้นหาตำแหน่งของคุณ..."
                            : "กำลังเปิดระบบพิกัดสำรอง...",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25.0, vertical: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios,
                                  color: Colors.white, size: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "สภาพอากาศ",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Text(
                                  "พิกัด: ${displayLat.toStringAsFixed(4)}, ${displayLon.toStringAsFixed(4)}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 15, top: 5),
                            child: Text(
                              "ℹ️ ใช้พื้นที่สำรองเนื่องจาก: $errorMessage",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        const SizedBox(height: 25),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "วันนี้",
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              currentDate,
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        Text(
                          "${currentTemp.round()}°",
                          style: const TextStyle(
                              fontSize: 90,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1.0),
                        ),

                        Text(
                          weatherCondition,
                          style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(Icons.arrow_upward,
                                color: Colors.white, size: 18),
                            Text("${maxTemperature.round()}°",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18)),
                            const Icon(Icons.arrow_downward,
                                color: Colors.white, size: 18),
                            Text("${minTemperature.round()}°",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 35),

                        SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: hourlyForecast.length,
                            itemBuilder: (context, index) {
                              final item = hourlyForecast[index];
                              bool isCurrent = item['isCurrent'];
                              return Container(
                                width: 75,
                                margin: const EdgeInsets.only(right: 12),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.white.withOpacity(0.25)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                  border: isCurrent
                                      ? Border.all(color: Colors.white38)
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      "${item['temp'].round()}°C",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Icon(getWeatherIcon(item['code']),
                                        color: Colors.white, size: 24),
                                    Text(item['time'],
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 35),

                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailCard(
                                  icon: Icons.water_drop,
                                  title: "ความชื้น",
                                  value: "$currentHumidity%"),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildDetailCard(
                                  icon: Icons.air,
                                  title: "ลม",
                                  value: "${windSpeed.round()} กม/ชม"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // 🟢 ปุ่มแนะนำพืชที่เหมาะสม
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: isRecommending
                                ? null
                                : _recommendPlantsFromWeather,
                            icon: isRecommending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF2E5A36),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.eco,
                                    color: Color(0xFF2E5A36),
                                    size: 26,
                                  ),
                            label: Text(
                              isRecommending
                                  ? "กำลังคำนวณ..."
                                  : "แนะนำพืชที่เหมาะสม",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E5A36),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
      {required IconData icon,
      required String title,
      required String value}) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}