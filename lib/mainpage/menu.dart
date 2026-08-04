import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:project/navbar/navbars.dart'; 
import 'package:project/mainpage/datawarehouse.dart'; 
import 'package:project/mainpage/recommentplants.dart'; 

// ไฟล์ปลายทางที่ต้องการให้เปลี่ยนหน้าไป
import 'package:project/reccomment/adjust.dart';
import 'package:project/reccomment/earth.dart';
import 'package:project/reccomment/earthtype.dart';
import 'package:project/reccomment/plants.dart';
import 'package:project/reccomment/soil.dart';
import 'package:project/mainpage/weather.dart';

import 'package:project/service/user_service.dart'; // นำเข้า UserService เพื่อเรียก API

class MenuPage extends StatefulWidget {
  final bool isLoggedIn;
  const MenuPage({super.key, this.isLoggedIn = false});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;
  final ScrollController _cardScrollController = ScrollController();
  int _currentCardIndex = 0;

  // ตัวแปรเก็บจำนวนสมาชิก
  int _userCount = 0;

  // 🌤️ ตัวแปรเก็บข้อมูลสภาพอากาศจาก Open-Meteo API
  bool _isLoadingWeather = true;
  int _currentTemp = 0;
  int _todayMaxTemp = 0;
  int _todayMinTemp = 0;
  int _humidity = 0;
  double _windSpeed = 0.0;
  List<Map<String, dynamic>> _dailyForecast = [];

  @override
  void initState() {
    super.initState();
    
    _fetchUserCount();
    _fetchWeatherData(); // 🌤️ ดึงข้อมูลสภาพอากาศทันทีเมื่อเปิดหน้า

    _cardScrollController.addListener(() {
      double itemWidth = 280.0 + 15.0;
      int newIndex = (_cardScrollController.offset / itemWidth).round();
      
      if (newIndex < 0) newIndex = 0;
      if (newIndex > 4) newIndex = 4;

      if (newIndex != _currentCardIndex) {
        setState(() {
          _currentCardIndex = newIndex;
        });
      }
    });
  }

  // ฟังก์ชันสำหรับติดต่อกับ UserService เพื่อดึงยอดสมาชิก
  Future<void> _fetchUserCount() async {
    try {
      final response = await UserService.getUserCount(); 
      if (response != null && response['userCount'] != null) {
        setState(() {
          _userCount = int.parse(response['userCount'].toString());
        });
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการดึงข้อมูลจำนวนสมาชิก: $e");
    }
  }

  // 🌤️ ฟังก์ชันดึงข้อมูลสภาพอากาศ อ.บ้านดู่ จาก open-meteo.com
  Future<void> _fetchWeatherData() async {
    // พิกัด อ.บ้านดู่ จ.เชียงราย: Lat 19.9880, Long 99.8580
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=19.9880&longitude=99.8580&current=temperature_2m,relative_humidity_2m,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min&timezone=Asia%2FBangkok',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final daily = data['daily'];

        // แปลงชื่อวันเป็นภาษาไทย
        final dayNames = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
        List<Map<String, dynamic>> forecast = [];

        List<dynamic> times = daily['time'];
        List<dynamic> maxs = daily['temperature_2m_max'];
        List<dynamic> mins = daily['temperature_2m_min'];

        // ดึงพยากรณ์ล่วงหน้า 4 วันถัดไป
        for (int i = 1; i < times.length && i <= 4; i++) {
          DateTime date = DateTime.parse(times[i]);
          String dayName = dayNames[date.weekday % 7];
          forecast.add({
            'day': dayName,
            'high': '${(maxs[i] as num).round()}°',
            'low': '${(mins[i] as num).round()}°',
          });
        }

        setState(() {
          _currentTemp = (current['temperature_2m'] as num).round();
          _humidity = (current['relative_humidity_2m'] as num).toInt();
          _windSpeed = (current['wind_speed_10m'] as num).toDouble();
          _todayMaxTemp = (daily['temperature_2m_max'][0] as num).round();
          _todayMinTemp = (daily['temperature_2m_min'][0] as num).round();
          _dailyForecast = forecast;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการดึงข้อมูลสภาพอากาศ: $e");
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  @override
  void dispose() {
    _cardScrollController.dispose();
    super.dispose();
  }

  void _showMembershipRightsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF4EFC9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
            side: const BorderSide(color: Colors.black87, width: 1.2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.black, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  "สิทธิของสมาชิก",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                _buildRightItem(
                  "1.",
                  "สามารถใช้ฟังก์ชันแนะนำพืชที่เหมาะสมได้ โดยไม่ต้องกรอกค่าลงไป โดยจะนำค่าจากอุปกรณ์ไปประมวลผลและแนะนำให้",
                ),
                const SizedBox(height: 10),
                _buildRightItem(
                  "2. ",
                  "สามารถบันทึกข้อมูลค่าในดินแต่ละพื้นที่ได้",
                ),
                const SizedBox(height: 10),
                _buildRightItem(
                  "3. ",
                  "สามารถใช้แชตบอทได้",
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRightItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16, 
              color: Colors.black87, 
              height: 1.3,
            ),
          ),
        ),
      ],
    );
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
            colors: [
              Color(0xFFDCEAF1), 
              Color(0xFFD2E0C4), 
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 25),
                  _buildHorizontalCards(),
                  const SizedBox(height: 15),
                  _buildDotsIndicator(), 
                  const SizedBox(height: 25),
                  
                  // 📍 แสดงข้อความหัวข้อสภาพอากาศพร้อมระบุสถานที่กำกับในวงเล็บ
                  const Text(
                    "สภาพอากาศ (ตำบลบ้านดู่ อำเภอเมืองเชียงราย จังหวัดเชียงราย)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildWeatherCard(),
                  const SizedBox(height: 25),
                  _buildMembershipSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.isLoggedIn 
          ? const AuthNavBar(currentIndex: 0) 
          : const GuestNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6B9077), 
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: const Center(
            child: Icon(
              Icons.eco,
              color: Colors.white,
              size: 35,
            ), 
          ),
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Text(
            "อุปกรณ์วัดคุณภาพของดินและ\nแนะนำพืชที่เหมาะสม",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalCards() {
    return SizedBox(
      height: 140,
      child: ListView(
        controller: _cardScrollController, 
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildSingleCard("พืชปลูก", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlantsPage()));
          }),
          const SizedBox(width: 15),
          _buildSingleCard("ดิน", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EarthPage()));
          }),
          const SizedBox(width: 15),
          _buildSingleCard("การปรับสภาพดิน", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdjustPage()));
          }),
          const SizedBox(width: 15),
          _buildSingleCard("แนะนำพืชปลูกตามประเภทของดิน", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EarthTypePage()));
          }),
          const SizedBox(width: 15),
          _buildSingleCard("แนะนำพืชปลูกตามปริมาณธาตุอาหารในดิน", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SoilPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildSingleCard(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDB4), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black87, width: 1.5), 
        ),
        child: Stack(
          children: [
            Positioned(
              top: 15,
              left: 20,
              right: 20, 
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2, 
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5E34), 
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(13),
                    bottomRight: Radius.circular(13),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.energy_savings_leaf, color: Color(0xFF8CC152), size: 20),
                    Icon(Icons.energy_savings_leaf, color: Color(0xFF8CC152), size: 28),
                    Icon(Icons.energy_savings_leaf, color: Color(0xFF8CC152), size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        bool isActive = index == _currentCardIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250), 
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: isActive ? 24 : 6, 
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  // 🌤️ ปรับปรุงการ์ดแสดงผลสภาพอากาศด้วยข้อมูล Dynamic จาก API
  Widget _buildWeatherCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeatherPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF88C0FA), Color(0xFF5A94ED)], 
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoadingWeather
            ? const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "วันนี้",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$_currentTemp°",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                            Text(" $_todayMaxTemp° / ", style: const TextStyle(color: Colors.white, fontSize: 16)),
                            const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                            Text(" $_todayMinTemp°", style: const TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(Icons.water_drop, color: Colors.white, size: 16),
                            Text(" $_humidity%   ", style: const TextStyle(color: Colors.white, fontSize: 14)),
                            const Icon(Icons.air, color: Colors.white, size: 16),
                            Text(" ${_windSpeed.toStringAsFixed(1)} กม/ชม", style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: _dailyForecast.map((item) {
                        return _buildWeatherDayRow(
                          item['day'],
                          item['high'],
                          item['low'],
                          Icons.cloud,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWeatherDayRow(String day, String high, String low, IconData icon) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(day, style: const TextStyle(color: Colors.white, fontSize: 16)),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.white, size: 12),
                  Text(" $high ", style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const Icon(Icons.arrow_downward, color: Colors.white, size: 12),
                  Text(" $low", style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
              Icon(icon, color: Colors.white54, size: 20),
            ],
          ),
        ),
        const Divider(color: Colors.white30, height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildMembershipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showMembershipRightsDialog,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "จำนวนผู้ที่เป็นสมาชิก",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF91CF9D), 
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$_userCount",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _showMembershipRightsDialog,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFF5A9031), 
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 50), 
                const SizedBox(height: 5),
                Transform.rotate(
                  angle: -0.05, 
                  child: const Text(
                    "สิทธิของสมาชิก",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ], 
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}