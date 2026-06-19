import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; 
import 'dart:convert';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  double currentTemp = 24.0;
  int currentHumidity = 87;
  double windSpeed = 4.0;
  String weatherCondition = "กำลังโหลดข้อมูล...";
  List<Map<String, dynamic>> hourlyForecast = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _determinePositionAndFetchWeather();
  }

  // 🛰️ ฟังก์ชันขอสิทธิ์ระบุตำแหน่ง (ตั้งเวลาดักไว้ 10 วินาทีตามมาตรฐาน)
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

      // ⏱️ ปรับการดักเวลาเป็น 10 วินาที เพื่อเสถียรภาพสูงสุดบนมือถือจริง
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low 
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw 'ระบบค้นหาพิกัดใช้เวลานานเกินไป (ใช้พิกัดสำรอง)';
        },
      );

      await fetchWeatherData(position.latitude, position.longitude);

    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        fetchWeatherData(13.7563, 100.5018); // ส่งพิกัดกรุงเทพฯ เป็น Fallback
      });
    }
  }

  Future<void> fetchWeatherData(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&hourly=temperature_2m,weather_code&timezone=Asia%2FBangkok');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final current = data['current'];
        final hourly = data['hourly'];
        final List<dynamic> times = hourly['time'];
        final List<dynamic> temps = hourly['temperature_2m'];
        final List<dynamic> codes = hourly['weather_code'];

        int currentHourIndex = DateTime.now().hour;
        List<Map<String, dynamic>> tempHourly = [];
        
        for (int i = -2; i <= 2; i++) {
          int index = currentHourIndex + i;
          if (index >= 0 && index < times.length) {
            String timeStr = times[index].toString().split('T')[1].substring(0, 5);
            tempHourly.add({
              'time': timeStr,
              'temp': temps[index],
              'code': codes[index],
              'isCurrent': i == 0,
            });
          }
        }

        setState(() {
          currentTemp = (current['temperature_2m'] as num).toDouble();
          currentHumidity = (current['relative_humidity_2m'] as num).toInt();
          windSpeed = (current['wind_speed_10m'] as num).toDouble();
          weatherCondition = getWeatherStatus(current['weather_code']);
          hourlyForecast = tempHourly;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        weatherCondition = "ดึงข้อมูลล้มเหลว";
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

  IconData getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.cloud;
    if (code <= 48) return Icons.cloud_queue;
    if (code <= 67) return Icons.umbrella;
    return Icons.thunderstorm;
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = "${DateTime.now().day} มกราคม";

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
                        errorMessage.isEmpty ? "กำลังค้นหาตำแหน่งของคุณ..." : "กำลังเปิดระบบพิกัดสำรอง...",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView( // 🛠️ ครอบด้วยฟังก์ชันนี้เพื่อแก้บั๊กแถบเหลืองดำด้านล่างจอ
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              "สภาพอากาศ",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        if (errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 15, top: 5),
                            child: Text(
                              "ℹ️ ใช้พื้นที่สำรองเนื่องจาก: $errorMessage", 
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)
                            ),
                          ),
                        const SizedBox(height: 25),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("วันนี้", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(formattedDate, style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 15),

                        Text(
                          "${currentTemp.round()}°",
                          style: const TextStyle(fontSize: 90, fontWeight: FontWeight.w300, color: Colors.white, height: 1.0),
                        ),
                        
                        Text(
                          weatherCondition,
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                            Text(" ${(currentTemp + 4).round()}° / ", style: const TextStyle(color: Colors.white, fontSize: 18)),
                            const Icon(Icons.arrow_downward, color: Colors.white, size: 18),
                            Text(" ${(currentTemp - 5).round()}°", style: const TextStyle(color: Colors.white, fontSize: 18)),
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isCurrent ? Colors.white.withOpacity(0.25) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                  border: isCurrent ? Border.all(color: Colors.white38) : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Text("${item['temp'].round()}°C", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    Icon(getWeatherIcon(item['code']), color: Colors.white, size: 24),
                                    Text(item['time'], style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
                              child: _buildDetailCard(icon: Icons.water_drop, title: "ความชื้น", value: "$currentHumidity%"),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildDetailCard(icon: Icons.air, title: "ลม", value: "${windSpeed.round()} กม/ชม"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({required IconData icon, required String title, required String value}) {
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
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}