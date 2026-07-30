import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

// 🛠️ นำเข้า Service สำหรับดึงข้อมูลพืช
import 'package:project/service/plants_service.dart';

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

  // 🟩 ตัวแปรสำหรับ Cache ข้อมูลพืช และ Ngrok URL
  List<dynamic> _cachedPlants = [];
  static const String ngrokUrl =
      'https://uselessly-disclose-stingray.ngrok-free.dev';

  @override
  void initState() {
    super.initState();
    _determinePositionAndFetchWeather();
    _preloadPlantsData(); // 🟩 พรีโหลดข้อมูลพืชเตรียมไว้
  }

  // 🟩 ฟังก์ชันโหลดและแคชข้อมูลพืช
  Future<void> _preloadPlantsData() async {
    try {
      _cachedPlants = await PlantsService.getplants();
    } catch (e) {
      debugPrint("Error preloading plants: $e");
    }
  }

  // 🛰️ ฟังก์ชันค้นหาพิกัด
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

  // ☁️ ฟังก์ชันดึงข้อมูลสภาพอากาศ
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

  // 🟩 ฟังก์ชันแปลงรูปภาพ URL
  String _formatImgUrl(String imgUrl) {
    String cleanImgUrl = imgUrl.replaceAll(r'\/', '/');
    if (cleanImgUrl.contains('10.0.2.2:8000')) {
      return cleanImgUrl.replaceAll('http://10.0.2.2:8000', ngrokUrl);
    } else if (cleanImgUrl.contains('127.0.0.1:8000')) {
      return cleanImgUrl.replaceAll('http://127.0.0.1:8000', ngrokUrl);
    } else if (cleanImgUrl.contains('localhost:8000')) {
      return cleanImgUrl.replaceAll('http://localhost:8000', ngrokUrl);
    }
    return cleanImgUrl;
  }

  // 🟩 ฟังก์ชันฟอร์แมตช่วงตัวเลข
  String _formatRange(dynamic minVal, dynamic maxVal) {
    if (minVal == null && maxVal == null) return '-';
    if (minVal != null && maxVal == null) return '$minVal';
    if (minVal == null && maxVal != null) return '$maxVal';
    if (minVal.toString() == maxVal.toString()) return '$minVal';
    return '$minVal - $maxVal';
  }

  // 🟩 ฟังก์ชันประเมินคะแนนความเหมาะสม (Fuzzy Matching)
  double _evaluateFuzzyMatch(
    double? input,
    dynamic minVal,
    dynamic maxVal,
    String factorName,
    List<String> matchedTags,
  ) {
    if (input == null || minVal == null || maxVal == null) return 0.0;
    double min = double.tryParse(minVal.toString()) ?? 0.0;
    double max = double.tryParse(maxVal.toString()) ?? double.infinity;

    if (input >= min && input <= max) {
      matchedTags.add(factorName);
      return 1.0;
    }

    double range = (max - min).abs();
    if (range == 0) range = 1.0;
    double margin = range * 0.20;

    if ((input < min && (min - input) <= margin) ||
        (input > max && (input - max) <= margin)) {
      matchedTags.add("$factorName (ใกล้เคียง)");
      return 0.5;
    }

    return 0.0;
  }

  // 🟩 ฟังก์ชันเปิด URL ลิงก์
  Future<void> _openUrl(String? link) async {
    if (link != null && link.isNotEmpty) {
      final Uri url = Uri.parse(link);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("ไม่สามารถเปิดลิงก์นี้ได้");
      }
    } else {
      _showSnackBar("ไม่มีข้อมูลลิงก์รายละเอียด");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 🟩 ฟังก์ชันค้นหาพืชที่เหมาะสมจากค่า "อุณหภูมิ" และ "ความชื้น" สภาพอากาศ
  void _recommendPlantsFromWeather() async {
    setState(() {
      isRecommending = true;
    });

    try {
      List<dynamic> plantsToUse = _cachedPlants;
      if (plantsToUse.isEmpty) {
        plantsToUse = await PlantsService.getplants();
        _cachedPlants = plantsToUse;
      }

      List<Map<String, dynamic>> scoredPlants = [];
      const int activeCriteriaCount = 2; // คำนวณจาก 2 ปัจจัย: ความชื้น + อุณหภูมิ

      for (var plant in plantsToUse) {
        double totalScore = 0.0;
        List<String> matchedTags = [];

        // คำนวณคะแนน ความชื้น
        totalScore += _evaluateFuzzyMatch(
          currentHumidity.toDouble(),
          plant['minhumid'],
          plant['maxhumid'],
          "ความชื้น",
          matchedTags,
        );

        // คำนวณคะแนน อุณหภูมิ
        totalScore += _evaluateFuzzyMatch(
          currentTemp,
          plant['mintemperature'],
          plant['maxtemperature'],
          "อุณหภูมิ",
          matchedTags,
        );

        double matchPercentage = (totalScore / activeCriteriaCount) * 100;
        if (matchPercentage > 100) matchPercentage = 100;

        scoredPlants.add({
          'plantData': plant,
          'matchPercentage': matchPercentage,
          'matchedTags': matchedTags,
        });
      }

      // เรียงลำดับจาก % สูงไปต่ำ และคัด Top 5
      scoredPlants.sort((a, b) => b['matchPercentage'].compareTo(a['matchPercentage']));
      List<Map<String, dynamic>> top5Plants = scoredPlants.take(5).toList();

      if (mounted) {
        _showResultsBottomSheet(top5Plants);
      }
    } catch (e) {
      _showSnackBar("เกิดข้อผิดพลาดในการประมวลผล: $e");
    } finally {
      if (mounted) {
        setState(() {
          isRecommending = false;
        });
      }
    }
  }

  // 🟩 แสดง Bottom Sheet รายชื่อพืชแนะนำ 5 อันดับแรก
  void _showResultsBottomSheet(List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: const BoxDecoration(
            color: Color(0xFFF1E6C9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E5A36),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "พืชแนะนำตามสภาพอากาศ\n(อุณหภูมิ $currentTemp°C, ความชื้น $currentHumidity%)",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var plant = items[index]['plantData'];
                    double matchPercentage = items[index]['matchPercentage'];
                    List<String> matchedTags = items[index]['matchedTags'];

                    String plantName = plant['normal_name'] ?? 'ไม่ระบุชื่อ';
                    String rawImageUrl =
                        plant['img_cloudinary'] ?? plant['img'] ?? '';
                    String formattedImgUrl = _formatImgUrl(rawImageUrl);

                    Color badgeColor = matchPercentage >= 80
                        ? Colors.green.shade800
                        : (matchPercentage >= 50
                            ? Colors.orange.shade800
                            : Colors.red.shade800);

                    return GestureDetector(
                      onTap: () =>
                          _showPlantDetailDialog(Map<String, dynamic>.from(plant)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F8E5F),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF2E5A36), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${index + 1}. $plantName",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "ความเหมาะสม ${matchPercentage.toStringAsFixed(0)}%",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: formattedImgUrl.isNotEmpty
                                      ? Image.network(
                                          formattedImgUrl,
                                          width: 100,
                                          height: 85,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              Container(
                                            width: 100,
                                            height: 85,
                                            color: Colors.white24,
                                            child: const Icon(Icons.eco,
                                                color: Colors.white, size: 40),
                                          ),
                                        )
                                      : Container(
                                          width: 100,
                                          height: 85,
                                          color: Colors.white24,
                                          child: const Icon(Icons.eco,
                                              color: Colors.white, size: 40),
                                        ),
                                ),
                              ],
                            ),
                            if (matchedTags.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(color: Colors.white30, height: 10),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: matchedTags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white54, width: 0.5),
                                    ),
                                    child: Text(
                                      "✓ $tag",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🟩 Dialog แสดงรายละเอียดพืชเมื่อกดเลือก
  void _showPlantDetailDialog(Map<String, dynamic> item) {
    String normalName = item['normal_name'] ?? 'ไม่มีชื่อพืช';
    String scientificName = item['scientific_name'] ?? 'ไม่มีชื่อวิทยาศาสตร์';
    String otherName = item['other_name'] ?? 'ไม่มีชื่ออื่นๆ';
    String imgUrl = _formatImgUrl(item['img_cloudinary'] ?? item['img'] ?? '');
    String detaill = item['detaill'] ?? 'ไม่มีข้อมูลรายละเอียดพืช';
    String nature = item['nature'] ?? 'ไม่มีข้อมูลลักษณะทั่วไป';
    String plant = item['plant'] ?? 'ไม่มีข้อมูลการปลูก';
    String care = item['care'] ?? 'ไม่มีข้อมูลการดูแล';
    String harvest = item['harvest'] ?? 'ไม่มีข้อมูลการเก็บเกี่ยว';
    String? supplyLink = item['supplyLink'] ?? item['link'];
    String? demandLink = item['demandLink'] ?? item['link'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          backgroundColor: const Color(0xFFEFE8CE),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 680),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        normalName,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 28, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      imgUrl,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 220,
                        height: 220,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ชื่อสามัญ : $normalName",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        Text("ชื่อวิทยาศาสตร์ : $scientificName",
                            style: const TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                color: Colors.black)),
                        Text("ชื่ออื่นๆ : $otherName",
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black)),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 5),

                        HtmlWidget(detaill,
                            textStyle: const TextStyle(
                                fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("ลักษณะทั่วไป",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        HtmlWidget(nature,
                            textStyle: const TextStyle(
                                fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("ข้อมูลการปลูก",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        HtmlWidget(plant,
                            textStyle: const TextStyle(
                                fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("การดูแลรักษา",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        HtmlWidget(care,
                            textStyle: const TextStyle(
                                fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("การเก็บเกี่ยว",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        HtmlWidget(harvest,
                            textStyle: const TextStyle(
                                fontSize: 14, height: 1.4, color: Colors.black)),

                        const Divider(color: Colors.black26, height: 25),
                        const Center(
                          child: Text("สภาพดินและธาตุอาหารในดินที่เหมาะสม",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ),
                        const SizedBox(height: 15),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              _buildNutrientText("N (ไนโตรเจน)",
                                  _formatRange(item['minN'], item['maxN'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("P (ฟอสฟอรัส)",
                                  _formatRange(item['minP'], item['maxP'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("K (โพแทสเซียม)",
                                  _formatRange(item['minK'], item['maxK'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("Ca (แคลเซียม)",
                                  _formatRange(item['minCa'], item['maxCa'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("Mg (แมกนีเซียม)",
                                  _formatRange(item['minMg'], item['maxMg'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("S (กำมะถัน)",
                                  _formatRange(item['minS'], item['maxS'])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              _buildEnvGridRow(
                                iconLeft: Icons.opacity,
                                colorLeft: Colors.blue,
                                titleLeft: "ความชื้น",
                                valueLeft:
                                    "${_formatRange(item['minhumid'], item['maxhumid'])} %",
                                iconRight: Icons.grid_3x3,
                                colorRight: Colors.black87,
                                titleRight: "pH",
                                valueRight:
                                    _formatRange(item['minPH'], item['maxPH']),
                              ),
                              const SizedBox(height: 16),
                              _buildEnvGridRow(
                                iconLeft: Icons.thermostat,
                                colorLeft: Colors.black87,
                                titleLeft: "อุณหภูมิ",
                                valueLeft:
                                    "${_formatRange(item['mintemperature'], item['maxtemperature'])} °C",
                                iconRight: Icons.waves,
                                colorRight: Colors.brown,
                                titleRight: "ความเค็ม",
                                valueRight:
                                    "${_formatRange(item['minsalty'], item['maxsalty'])} mS/cm",
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.black26, height: 30),

                        // 🟢 ส่วน Supply และ Demand
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                "ความต้องการและปริมาณการผลิต",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                "ปริมาณการผลิต",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: 'คลิกเพื่อดูรายละเอียด',
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: 'เพิ่มเติม',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => _openUrl(supplyLink),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                "ความต้องการ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: 'คลิกเพื่อดูรายละเอียด',
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: 'เพิ่มเติม',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => _openUrl(demandLink),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutrientText(String label, String value,
      {String unit = 'mg/kg'}) {
    bool hasValue = !(value == '-' || value.trim().isEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label :",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (hasValue)
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvGridRow({
    required IconData? iconLeft,
    required Color colorLeft,
    required String titleLeft,
    required String valueLeft,
    required IconData? iconRight,
    required Color colorRight,
    required String titleRight,
    required String valueRight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              if (iconLeft != null)
                Icon(iconLeft, color: colorLeft, size: 28)
              else
                const SizedBox(width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    Text("$titleLeft : ",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    Text(valueLeft,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              if (iconRight != null)
                Icon(iconRight, color: colorRight, size: 28)
              else
                const SizedBox(width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    Text("$titleRight : ",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    Text(valueRight,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

                        // 🟢 ปุ่มแนะนำพืชที่เหมาะสม (เพิ่มใหม่ด้านล่างสุด)
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