import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 📍 เพิ่มเพื่อใช้ kIsWeb ตรวจสอบการรันบน Web
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

// 🛠️ นำเข้า Service และ Helper
import 'package:project/service/plants_service.dart';
import 'package:project/modal/plant_recommendation_helper.dart';

// 🛠️ นำเข้าสไตล์ Weather Theme
import 'package:project/style/style_weather.dart';

// 📍 คลาสสำหรับเก็บปีและเดือนที่เลือก
class MonthYear {
  final int year;
  final int month;

  MonthYear(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYear &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}

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
  List<Map<String, dynamic>> dailyForecast = [];
  
  bool isLoading = true;
  bool isRecommending = false;
  bool isRecommendingMonth = false;

  double displayLat = 19.9880;
  double displayLon = 99.8580;
  String locationName = "ตำบลบ้านดู่ อำเภอเมืองเชียงราย จังหวัดเชียงราย";
  bool isGpsLocation = false; 

  static MonthYear _getPreviousMonthInitial() {
    final now = DateTime.now();
    final prevDate = DateTime(now.year, now.month - 1);
    return MonthYear(prevDate.year, prevDate.month);
  }

  List<MonthYear> selectedMonths = [_getPreviousMonthInitial()];
  double? monthAvgTemp;
  double? monthAvgHumidity;
  bool isLoadingMonthAvg = false;

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

  // 📍 ปรับปรุงการดึง GPS ให้รองรับทั้ง Mobile และ Web
  Future<void> _determinePositionAndFetchWeather() async {
    bool serviceEnabled;
    LocationPermission permission;
    double lat = 19.9880;
    double lon = 99.8580;
    bool gpsSuccess = false;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position? position;

          // 🌐 ข้ามการดึง LastKnownPosition บน Web เพราะไม่รองรับ
          if (!kIsWeb) {
            position = await Geolocator.getLastKnownPosition();
          }

          // ดึงตำแหน่งปัจจุบัน และขยาย Timeout เป็น 15 วินาทีสำหรับ Web
          position ??= await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).timeout(const Duration(seconds: 15));

          lat = position.latitude;
          lon = position.longitude;
          gpsSuccess = true;
        }
      }
    } catch (e) {
      debugPrint("GPS Error: $e");
    }

    if (!mounted) return;
    setState(() {
      displayLat = lat;
      displayLon = lon;
      isGpsLocation = gpsSuccess;
    });

    await _fetchLocationName(lat, lon, gpsSuccess);
    await fetchWeatherData(lat, lon);
    await fetchMultiMonthAverage(lat, lon, selectedMonths);
  }

  // 📍 ปรับแก้ Header ไม่ให้บล็อกการทำงานบน Web
  Future<void> _fetchLocationName(double lat, double lon, bool isGps) async {
    if (!isGps) {
      setState(() {
        locationName = "ตำบลบ้านดู่ อำเภอเมืองเชียงราย จังหวัดเชียงราย";
      });
      return;
    }

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=th',
      );
      
      // Web Browser ไม่อนุญาตให้กำหนด User-Agent Custom Header
      final headers = kIsWeb ? <String, String>{} : {'User-Agent': 'FlutterWeatherApp'};
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];

        String subdistrict = address['subdistrict'] ?? address['village'] ?? address['neighbourhood'] ?? '';
        String district = address['district'] ?? address['city_district'] ?? address['county'] ?? '';
        String province = address['state'] ?? address['province'] ?? '';

        List<String> parts = [];
        if (subdistrict.isNotEmpty) parts.add(subdistrict.startsWith("ตำบล") ? subdistrict : "ตำบล$subdistrict");
        if (district.isNotEmpty) parts.add(district.startsWith("อำเภอ") || district.startsWith("เขต") ? district : "อำเภอ$district");
        if (province.isNotEmpty) parts.add(province.startsWith("จังหวัด") ? province : "จังหวัด$province");

        setState(() {
          locationName = parts.isNotEmpty ? parts.join(" ") : "ตำแหน่งปัจจุบัน";
        });
      }
    } catch (e) {
      setState(() {
        locationName = "ตำแหน่งปัจจุบัน";
      });
    }
  }

  Future<void> fetchWeatherData(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat'
        '&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'
        '&hourly=temperature_2m,weather_code'
        '&daily=temperature_2m_max,temperature_2m_min,weather_code'
        '&timezone=Asia%2FBangkok',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) throw Exception();

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

      final currentHourIndex = times.indexWhere((e) => e.toString() == currentHourString);

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

      List<Map<String, dynamic>> tempDaily = [];
      List<dynamic> dailyTimes = daily['time'];
      List<dynamic> dailyMaxs = daily['temperature_2m_max'];
      List<dynamic> dailyMins = daily['temperature_2m_min'];
      List<dynamic> dailyCodes = daily['weather_code'];
      final dayNames = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];

      for (int i = 0; i < dailyTimes.length && i < 5; i++) {
        DateTime date = DateTime.parse(dailyTimes[i]);
        String dayName = i == 0 ? "วันนี้" : dayNames[date.weekday % 7];
        tempDaily.add({
          "day": dayName,
          "date": "${date.day}/${date.month}",
          "max": (dailyMaxs[i] as num).round(),
          "min": (dailyMins[i] as num).round(),
          "code": dailyCodes[i],
          "status": getWeatherStatus(dailyCodes[i]),
        });
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
        currentDate = "${apiTime.day} ${thaiMonth(apiTime.month)} ${apiTime.year + 543}";
        hourlyForecast = tempHourly;
        dailyForecast = tempDaily;
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

  Future<void> fetchMultiMonthAverage(double lat, double lon, List<MonthYear> items) async {
    if (items.isEmpty) return;

    setState(() {
      isLoadingMonthAvg = true;
    });

    double totalTempSum = 0;
    int totalTempCount = 0;
    double totalHumSum = 0;
    int totalHumCount = 0;

    for (var item in items) {
      try {
        String monthStr = item.month.toString().padLeft(2, '0');
        int lastDay = DateTime(item.year, item.month + 1, 0).day;

        final url = Uri.parse(
          'https://archive-api.open-meteo.com/v1/archive'
          '?latitude=$lat'
          '&longitude=$lon'
          '&start_date=${item.year}-$monthStr-01'
          '&end_date=${item.year}-$monthStr-$lastDay'
          '&daily=temperature_2m_mean,relative_humidity_2m_mean'
          '&timezone=Asia%2FBangkok',
        );

        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final daily = data['daily'];

          List<dynamic> temps = daily['temperature_2m_mean'] ?? [];
          List<dynamic> humidities = daily['relative_humidity_2m_mean'] ?? [];

          for (var t in temps) {
            if (t != null) {
              totalTempSum += (t as num).toDouble();
              totalTempCount++;
            }
          }

          for (var h in humidities) {
            if (h != null) {
              totalHumSum += (h as num).toDouble();
              totalHumCount++;
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching month ${item.month}/${item.year}: $e");
      }
    }

    setState(() {
      monthAvgTemp = totalTempCount > 0 ? (totalTempSum / totalTempCount) : 28.5;
      monthAvgHumidity = totalHumCount > 0 ? (totalHumSum / totalHumCount) : 70.0;
      isLoadingMonthAvg = false;
    });
  }

  void _showMonthSelectionDialog() {
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    int selectedYearInDialog = selectedMonths.isNotEmpty ? selectedMonths.first.year : currentYear;
    List<MonthYear> tempSelected = List.from(selectedMonths);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: kWeatherDialogShape,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("เลือกเดือนและปี", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text("ปี: ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      DropdownButton<int>(
                        value: selectedYearInDialog,
                        underline: Container(height: 1.5, color: const Color(0xFF2E5A36)),
                        items: [currentYear, currentYear - 1, currentYear - 2, currentYear - 3].map((y) {
                          return DropdownMenuItem<int>(
                            value: y,
                            child: Text(" พ.ศ. ${y + 543} ($y)"),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedYearInDialog = val;
                              if (selectedYearInDialog == currentYear) {
                                tempSelected.removeWhere((item) => item.year == currentYear && item.month >= currentMonth);
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedYearInDialog == currentYear
                          ? "เลือกได้เฉพาะเดือนย้อนหลัง (ม.ค. - ${thaiMonthShort(currentMonth - 1 > 0 ? currentMonth - 1 : 1)}):"
                          : "เลือกเดือนที่ต้องการ (เลือกได้มากกว่า 1 เดือน):",
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.1,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          int monthNum = index + 1;
                          MonthYear currentItem = MonthYear(selectedYearInDialog, monthNum);
                          
                          bool isDisabled = (selectedYearInDialog == currentYear) && (monthNum >= currentMonth);
                          bool isChecked = tempSelected.contains(currentItem);

                          return InkWell(
                            onTap: isDisabled
                                ? null
                                : () {
                                    setDialogState(() {
                                      if (isChecked) {
                                        tempSelected.remove(currentItem);
                                      } else {
                                        tempSelected.add(currentItem);
                                      }
                                    });
                                  },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? Colors.grey[300]
                                    : (isChecked ? const Color(0xFF2E5A36) : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isChecked && !isDisabled ? const Color(0xFF2E5A36) : Colors.black12,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isDisabled
                                        ? Icons.block
                                        : (isChecked ? Icons.check_box : Icons.check_box_outline_blank),
                                    size: 15,
                                    color: isDisabled ? Colors.grey[500] : (isChecked ? Colors.white : Colors.black54),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    thaiMonthShort(monthNum),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDisabled ? Colors.grey[500] : (isChecked ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5A36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: tempSelected.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          setState(() {
                            selectedMonths = tempSelected;
                          });
                          fetchMultiMonthAverage(displayLat, displayLon, tempSelected);
                        },
                  child: Text(
                    "ยืนยัน (${tempSelected.length})",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _recommendPlantsFromWeather() async {
    setState(() => isRecommending = true);

    await PlantRecommendationHelper.showRecommendations(
      context: context,
      cachedPlants: _cachedPlants,
      temp: currentTemp,
      humidity: currentHumidity.toDouble(),
      customTitle: "พืชแนะนำตามสภาพอากาศปัจจุบัน\n(อุณหภูมิ ${currentTemp.round()}°C, ความชื้น $currentHumidity%)",
    );

    if (mounted) setState(() => isRecommending = false);
  }

  void _recommendPlantsFromMonthlyAvg() async {
    if (monthAvgTemp == null || monthAvgHumidity == null) return;

    setState(() => isRecommendingMonth = true);

    await PlantRecommendationHelper.showRecommendations(
      context: context,
      cachedPlants: _cachedPlants,
      temp: monthAvgTemp!,
      humidity: monthAvgHumidity!,
      customTitle: "พืชแนะนำตามค่าเฉลี่ยสภาพอากาศ\n(${_getSelectedMonthsLabel()})\n(อุณหภูมิเฉลี่ย ${monthAvgTemp!.toStringAsFixed(1)}°C, ความชื้นเฉลี่ย ${monthAvgHumidity!.round()}%)",
    );

    if (mounted) setState(() => isRecommendingMonth = false);
  }

  String _getSelectedMonthsLabel() {
    if (selectedMonths.isEmpty) return "ยังไม่ได้เลือกเดือน";
    if (selectedMonths.length == 1) {
      var item = selectedMonths.first;
      int yearShort = (item.year + 543) % 100;
      return "เดือน${thaiMonth(item.month)} $yearShort";
    }
    return "เฉลี่ยรวม ${selectedMonths.length} เดือนที่เลือก";
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
    const months = ['', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];
    return months[month];
  }

  String thaiMonthShort(int month) {
    const months = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
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
        decoration: kWeatherBackgroundDecoration,
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 15),
                      Text("กำลังโหลดข้อมูลสภาพอากาศ...", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "สภาพอากาศ",
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        isGpsLocation ? Icons.location_on : Icons.location_off,
                                        color: isGpsLocation ? Colors.lightGreenAccent : Colors.orangeAccent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          locationName,
                                          style: const TextStyle(fontSize: 13, color: Colors.white),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("วันนี้", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(currentDate, style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Text("${currentTemp.round()}°", style: const TextStyle(fontSize: 85, fontWeight: FontWeight.w300, color: Colors.white, height: 1.0)),
                        Text(weatherCondition, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                            Text("${maxTemperature.round()}°", style: const TextStyle(color: Colors.white, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_downward, color: Colors.white, size: 18),
                            Text("${minTemperature.round()}°", style: const TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 25),

                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: hourlyForecast.length,
                            itemBuilder: (context, index) {
                              final item = hourlyForecast[index];
                              bool isCurrent = item['isCurrent'];
                              return buildHourlyForecastCard(
                                tempText: "${item['temp'].round()}°C",
                                icon: getWeatherIcon(item['code']),
                                timeText: item['time'],
                                isCurrent: isCurrent,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 25),

                        Row(
                          children: [
                            Expanded(child: buildWeatherDetailCard(icon: Icons.water_drop, title: "ความชื้น", value: "$currentHumidity%")),
                            const SizedBox(width: 15),
                            Expanded(child: buildWeatherDetailCard(icon: Icons.air, title: "ลม", value: "${windSpeed.round()} กม/ชม")),
                          ],
                        ),
                        const SizedBox(height: 20),

                        buildPrimaryActionButton(
                          onPressed: isRecommending ? null : _recommendPlantsFromWeather,
                          isLoading: isRecommending,
                          defaultText: "แนะนำพืชจากสภาพอากาศตอนนี้",
                          loadingText: "กำลังคำนวณ...",
                          icon: Icons.eco,
                        ),
                        const SizedBox(height: 30),

                        const Text("พยากรณ์อากาศ 5 วันข้างหน้า", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        buildGlassCard(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: dailyForecast.map((dayData) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(dayData['day'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                          Text(dayData['date'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(getWeatherIcon(dayData['code']), color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(dayData['status'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.arrow_upward, color: Colors.white70, size: 14),
                                        Text("${dayData['max']}° ", style: const TextStyle(color: Colors.white, fontSize: 14)),
                                        const Icon(Icons.arrow_downward, color: Colors.white70, size: 14),
                                        Text("${dayData['min']}°", style: const TextStyle(color: Colors.white, fontSize: 14)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 30),

                        buildGlassCard(
                          padding: const EdgeInsets.all(18),
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
                                        const Text("สภาพอากาศเฉลี่ย", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                        Text(_getSelectedMonthsLabel(), style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _showMonthSelectionDialog,
                                    icon: const Icon(Icons.calendar_month, size: 18, color: Colors.white),
                                    label: const Text("เลือกเดือน/ปี", style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E5A36),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              isLoadingMonthAvg
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(15.0),
                                        child: CircularProgressIndicator(color: Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            const Text("อุณหภูมิเฉลี่ย", style: TextStyle(color: Colors.white70, fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${monthAvgTemp?.toStringAsFixed(1) ?? '-'} °C",
                                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Container(width: 1, height: 40, color: Colors.white30),
                                        Column(
                                          children: [
                                            const Text("ความชื้นเฉลี่ย", style: TextStyle(color: Colors.white70, fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${monthAvgHumidity?.round() ?? '-'} %",
                                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 15),

                              buildPrimaryActionButton(
                                onPressed: (isRecommendingMonth || isLoadingMonthAvg) ? null : _recommendPlantsFromMonthlyAvg,
                                isLoading: isRecommendingMonth,
                                defaultText: "แนะนำพืชตามค่าเฉลี่ยที่เลือก",
                                loadingText: "กำลังคำนวณ...",
                                icon: Icons.eco,
                                height: 45,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}