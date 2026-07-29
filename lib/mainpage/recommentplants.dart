import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:project/navbar/navbars.dart'; 
import 'package:project/mainpage/menu.dart'; 
import 'package:project/mainpage/datawarehouse.dart'; 

// 🛠️ นำเข้า Service สำหรับดึงข้อมูลพืช
import 'package:project/service/plants_service.dart'; 

class RecommendPlantsPage extends StatefulWidget {
  final bool isLoggedIn;
  const RecommendPlantsPage({super.key, this.isLoggedIn = false});

  @override
  State<RecommendPlantsPage> createState() => _RecommendPlantsPageState();
}

class _RecommendPlantsPageState extends State<RecommendPlantsPage> {
  int _selectedIndex = 2;
  bool _isLoading = false;

  // 🟩 ข้อ 2: ตัวแปรสำหรับ Cache ข้อมูลพืช ป้องกันการเรียก API ซ้ำซ้อน
  List<dynamic> _cachedPlants = [];

  // สถานะเปิด/ปิด การใช้งานกลุ่มธาตุอาหารหลัก และ ธาตุอาหารรอง
  bool _isPrimaryNutrientEnabled = false;
  bool _isSecondaryNutrientEnabled = false;

  static const String ngrokUrl =
      'https://uselessly-disclose-stingray.ngrok-free.dev';

  // Controllers สำหรับช่องกรอกข้อมูล
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _humidController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _saltyController = TextEditingController();
  final TextEditingController _nController = TextEditingController();
  final TextEditingController _pController = TextEditingController();
  final TextEditingController _kController = TextEditingController();
  final TextEditingController _caController = TextEditingController();
  final TextEditingController _mgController = TextEditingController();
  final TextEditingController _sController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🟩 ข้อ 2: พรีโหลดข้อมูลพืชล่วงหน้าทันทีที่เข้าหน้านี้
    _preloadPlantsData();
  }

  @override
  void dispose() {
    _phController.dispose();
    _humidController.dispose();
    _tempController.dispose();
    _saltyController.dispose();
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _caController.dispose();
    _mgController.dispose();
    _sController.dispose();
    super.dispose();
  }

  // 🟩 ข้อ 2: ฟังก์ชันโหลดและแคชข้อมูลพืช
  Future<void> _preloadPlantsData() async {
    try {
      _cachedPlants = await PlantsService.getplants();
    } catch (e) {
      debugPrint("Error preloading plants: $e");
    }
  }

  // 🟩 ข้อ 4: ฟังก์ชันสำหรับล้างข้อมูลทั้งหมด (Reset)
  void _resetAllFields() {
    _phController.clear();
    _humidController.clear();
    _tempController.clear();
    _saltyController.clear();
    _nController.clear();
    _pController.clear();
    _kController.clear();
    _caController.clear();
    _mgController.clear();
    _sController.clear();

    setState(() {
      _isPrimaryNutrientEnabled = false;
      _isSecondaryNutrientEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("ล้างข้อมูลเรียบร้อยแล้ว"),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 1),
      ),
    );
  }

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

  String _formatRange(dynamic minVal, dynamic maxVal) {
    if (minVal == null && maxVal == null) return '-';
    if (minVal != null && maxVal == null) return '$minVal';
    if (minVal == null && maxVal != null) return '$maxVal';
    if (minVal.toString() == maxVal.toString()) return '$minVal';
    return '$minVal - $maxVal';
  }

  // 🟩 ข้อ 3: ฟังก์ชันให้คะแนนแบบยืดหยุ่น (Fuzzy Scoring)
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

    // 1. ตรงตามช่วงปกติ -> 1.0 คะแนนเต็ม
    if (input >= min && input <= max) {
      matchedTags.add(factorName);
      return 1.0;
    }

    // 2. ใกล้เคียงช่วง (อนุโลมให้ระยะเบี่ยงเบนไม่เกิน 20%) -> 0.5 คะแนน
    double range = (max - min).abs();
    if (range == 0) range = 1.0;
    double margin = range * 0.20; 

    if ((input < min && (min - input) <= margin) || (input > max && (input - max) <= margin)) {
      matchedTags.add("$factorName (ใกล้เคียง)");
      return 0.5;
    }

    return 0.0;
  }

  // 🛠️ ฟังก์ชันประมวลผลค้นหาพืช
  void _searchSuitablePlants() async {
    // 🟩 ข้อ 5: ตรวจสอบความถูกต้องและขอบเขตตัวเลข (Value Range Guard)
    double? ph = double.tryParse(_phController.text.trim());
    if (_phController.text.isNotEmpty && (ph == null || ph < 0 || ph > 14)) {
      _showWarningSnackBar("ค่า pH ต้องอยู่ระหว่าง 0.0 ถึง 14.0");
      return;
    }

    double? humid = double.tryParse(_humidController.text.trim());
    if (_humidController.text.isNotEmpty && (humid == null || humid < 0 || humid > 100)) {
      _showWarningSnackBar("ค่าความชื้นต้องอยู่ระหว่าง 0% ถึง 100%");
      return;
    }

    double? temp = double.tryParse(_tempController.text.trim());
    if (_tempController.text.isNotEmpty && (temp == null || temp < -10 || temp > 60)) {
      _showWarningSnackBar("ค่าอุณหภูมิต้องอยู่ระหว่าง -10°C ถึง 60°C");
      return;
    }

    double? salty = double.tryParse(_saltyController.text.trim());
    if (_saltyController.text.isNotEmpty && (salty == null || salty < 0)) {
      _showWarningSnackBar("ค่าความเค็มต้องมากกว่าหรือเท่ากับ 0");
      return;
    }

    // ตรวจสอบเงื่อนไขการติ๊กเปิด Checkbox
    if (_isPrimaryNutrientEnabled) {
      if (_nController.text.trim().isEmpty ||
          _pController.text.trim().isEmpty ||
          _kController.text.trim().isEmpty) {
        _showWarningSnackBar("กรุณากรอกค่าธาตุอาหารหลัก (N, P, K) ให้ครบ หรือปิด Checkbox");
        return;
      }
    }

    if (_isSecondaryNutrientEnabled) {
      if (_caController.text.trim().isEmpty ||
          _mgController.text.trim().isEmpty ||
          _sController.text.trim().isEmpty) {
        _showWarningSnackBar("กรุณากรอกค่าธาตุอาหารรอง (Ca, Mg, S) ให้ครบ หรือปิด Checkbox");
        return;
      }
    }

    // ตรวจสอบว่ามีการกรอกข้อมูลอย่างน้อย 1 ช่องหรือไม่
    int activeCriteriaCount = 0;
    if (_phController.text.isNotEmpty) activeCriteriaCount++;
    if (_humidController.text.isNotEmpty) activeCriteriaCount++;
    if (_tempController.text.isNotEmpty) activeCriteriaCount++;
    if (_saltyController.text.isNotEmpty) activeCriteriaCount++;
    if (_isPrimaryNutrientEnabled) activeCriteriaCount += 3;
    if (_isSecondaryNutrientEnabled) activeCriteriaCount += 3;

    if (activeCriteriaCount == 0) {
      _showWarningSnackBar("กรุณากรอกข้อมูลสภาพดินอย่างน้อย 1 รายการเพื่อค้นหา");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🟩 ข้อ 2: ใช้ Cache ข้อมูลพืช หากยังไม่มีให้เรียกบริการดึงใหม่
      List<dynamic> plantsToUse = _cachedPlants;
      if (plantsToUse.isEmpty) {
        plantsToUse = await PlantsService.getplants();
        _cachedPlants = plantsToUse;
      }

      double? inputN = _isPrimaryNutrientEnabled ? double.tryParse(_nController.text) : null;
      double? inputP = _isPrimaryNutrientEnabled ? double.tryParse(_pController.text) : null;
      double? inputK = _isPrimaryNutrientEnabled ? double.tryParse(_kController.text) : null;

      double? inputCa = _isSecondaryNutrientEnabled ? double.tryParse(_caController.text) : null;
      double? inputMg = _isSecondaryNutrientEnabled ? double.tryParse(_mgController.text) : null;
      double? inputS = _isSecondaryNutrientEnabled ? double.tryParse(_sController.text) : null;

      List<Map<String, dynamic>> scoredPlants = [];

      for (var plant in plantsToUse) {
        double totalScore = 0.0;
        List<String> matchedTags = []; // 🟩 ข้อ 6: เก็บ Tag ปัจจัยที่ตรง

        if (_phController.text.isNotEmpty) {
          totalScore += _evaluateFuzzyMatch(ph, plant['minPH'], plant['maxPH'], "pH", matchedTags);
        }
        if (_humidController.text.isNotEmpty) {
          totalScore += _evaluateFuzzyMatch(humid, plant['minhumid'], plant['maxhumid'], "ความชื้น", matchedTags);
        }
        if (_tempController.text.isNotEmpty) {
          totalScore += _evaluateFuzzyMatch(temp, plant['mintemperature'], plant['maxtemperature'], "อุณหภูมิ", matchedTags);
        }
        if (_saltyController.text.isNotEmpty) {
          totalScore += _evaluateFuzzyMatch(salty, plant['minsalty'], plant['maxsalty'], "ความเค็ม", matchedTags);
        }

        if (_isPrimaryNutrientEnabled) {
          totalScore += _evaluateFuzzyMatch(inputN, plant['minN'], plant['maxN'], "N", matchedTags);
          totalScore += _evaluateFuzzyMatch(inputP, plant['minP'], plant['maxP'], "P", matchedTags);
          totalScore += _evaluateFuzzyMatch(inputK, plant['minK'], plant['maxK'], "K", matchedTags);
        }

        if (_isSecondaryNutrientEnabled) {
          totalScore += _evaluateFuzzyMatch(inputCa, plant['minCa'], plant['maxCa'], "Ca", matchedTags);
          totalScore += _evaluateFuzzyMatch(inputMg, plant['minMg'], plant['maxMg'], "Mg", matchedTags);
          totalScore += _evaluateFuzzyMatch(inputS, plant['minS'], plant['maxS'], "S", matchedTags);
        }

        // 🟩 ข้อ 1: คำนวณเป็น % ความเหมาะสม (% Match)
        double matchPercentage = (totalScore / activeCriteriaCount) * 100;
        if (matchPercentage > 100) matchPercentage = 100;

        scoredPlants.add({
          'plantData': plant,
          'matchPercentage': matchPercentage,
          'matchedTags': matchedTags,
        });
      }

      // เรียงลำดับจาก % สูงไปต่ำ และคัด 5 อันดับแรก
      scoredPlants.sort((a, b) => b['matchPercentage'].compareTo(a['matchPercentage']));
      List<Map<String, dynamic>> top5Plants = scoredPlants.take(5).toList();

      if (mounted) {
        _showResultsBottomSheet(top5Plants);
      }
    } catch (e) {
      _showWarningSnackBar("เกิดข้อผิดพลาดในการคำนวณ: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // 🛠️ UI แสดงป๊อปอัปผลลัพธ์พืช 5 อันดับ
  void _showResultsBottomSheet(List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.95,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                    const Text(
                      "พืชที่แนะนำตามค่าดินของคุณ",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                    String rawImageUrl = plant['img_url'] ?? plant['img'] ?? '';
                    String formattedImgUrl = _formatImgUrl(rawImageUrl);

                    // เลือกสี Badge ตาม % ความเหมาะสม
                    Color badgeColor = matchPercentage >= 80 
                        ? Colors.green.shade800 
                        : (matchPercentage >= 50 ? Colors.orange.shade800 : Colors.red.shade800);

                    return GestureDetector(
                      onTap: () => _showPlantDetailDialog(Map<String, dynamic>.from(plant)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F8E5F),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF2E5A36), width: 1.5),
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
                                      // 🟩 ข้อ 1: แสดง Badge % ความเหมาะสม
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 100,
                                            height: 85,
                                            color: Colors.white24,
                                            child: const Icon(Icons.eco, color: Colors.white, size: 40),
                                          ),
                                        )
                                      : Container(
                                          width: 100,
                                          height: 85,
                                          color: Colors.white24,
                                          child: const Icon(Icons.eco, color: Colors.white, size: 40),
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // 🟩 ข้อ 6: แสดง Tag ปัจจัยที่ตรง
                            if (matchedTags.isNotEmpty) ...[
                              const Divider(color: Colors.white30, height: 10),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: matchedTags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white54, width: 0.5),
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

  // 🟩 UI Dialog แสดงรายละเอียดพืชแบบเจาะลึก
  void _showPlantDetailDialog(Map<String, dynamic> item) {
    String normalName = item['normal_name'] ?? 'ไม่มีชื่อพืช';
    String scientificName = item['scientific_name'] ?? 'ไม่มีชื่อวิทยาศาสตร์';
    String otherName = item['other_name'] ?? 'ไม่มีชื่ออื่นๆ';
    String imgUrl = _formatImgUrl(item['img_url'] ?? item['img'] ?? '');
    String detaill = item['detaill'] ?? 'ไม่มีข้อมูลรายละเอียดพืช';
    String nature = item['nature'] ?? 'ไม่มีข้อมูลลักษณะทั่วไป';
    String plant = item['plant'] ?? 'ไม่มีข้อมูลการปลูก';
    String care = item['care'] ?? 'ไม่มีข้อมูลการดูแล';
    String harvest = item['harvest'] ?? 'ไม่มีข้อมูลการเก็บเกี่ยว';
    String? webLink = item['link'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 28, color: Colors.black),
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
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
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
                        Text("ชื่อสามัญ : $normalName", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text("ชื่อวิทยาศาสตร์ : $scientificName", style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black)),
                        Text("ชื่ออื่นๆ : $otherName", style: const TextStyle(fontSize: 15, color: Colors.black)),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 5),

                        HtmlWidget(detaill, textStyle: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("ลักษณะทั่วไป", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        HtmlWidget(nature, textStyle: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("ข้อมูลการปลูก", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        HtmlWidget(plant, textStyle: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("การดูแลรักษา", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        HtmlWidget(care, textStyle: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("การเก็บเกี่ยว", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        HtmlWidget(harvest, textStyle: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),

                        const Divider(color: Colors.black26, height: 25),
                        const Center(
                          child: Text("สภาพดินและธาตุอาหารในดินที่เหมาะสม", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        const SizedBox(height: 15),

                        // --- ปรับส่วนธาตุอาหารให้อยู่คนละบรรทัด พร้อมระบุชื่อเต็ม ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              _buildNutrientText("N (ไนโตรเจน)", _formatRange(item['minN'], item['maxN'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("P (ฟอสฟอรัส)", _formatRange(item['minP'], item['maxP'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("K (โพแทสเซียม)", _formatRange(item['minK'], item['maxK'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("Ca (แคลเซียม)", _formatRange(item['minCa'], item['maxCa'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("Mg (แมกนีเซียม)", _formatRange(item['minMg'], item['maxMg'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("S (กำมะถัน)", _formatRange(item['minS'], item['maxS'])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              _buildEnvGridRow(
                                iconLeft: Icons.opacity, colorLeft: Colors.blue, titleLeft: "ความชื้น", valueLeft: "${_formatRange(item['minhumid'], item['maxhumid'])} %",
                                iconRight: Icons.grid_3x3, colorRight: Colors.black87, titleRight: "pH", valueRight: _formatRange(item['minPH'], item['maxPH']),
                              ),
                              const SizedBox(height: 16),
                              _buildEnvGridRow(
                                iconLeft: Icons.thermostat, colorLeft: Colors.black87, titleLeft: "อุณหภูมิ", valueLeft: "${_formatRange(item['mintemperature'], item['maxtemperature'])} °C",
                                iconRight: Icons.waves, colorRight: Colors.brown, titleRight: "ความเค็ม", valueRight: "${_formatRange(item['minsalty'], item['maxsalty'])} mS/cm",
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.black26, height: 30),
                        Center(
                          child: Column(
                            children: [
                              const Text("ความต้องการและปริมาณการผลิต", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                              const SizedBox(height: 4),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: 'คลิกเพื่อดูรายละเอียด',
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: 'เพิ่มเติม',
                                      style: const TextStyle(fontSize: 16, color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          if (webLink != null && webLink.isNotEmpty) {
                                            final Uri url = Uri.parse(webLink);
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url, mode: LaunchMode.externalApplication);
                                            }
                                          }
                                        },
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

  Widget _buildNutrientText(String label, String value, {String unit = 'mg/kg'}) {
  bool hasValue = !(value == '-' || value.trim().isEmpty);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ฝั่งซ้าย: ชื่อธาตุ
        Text(
          "$label :",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        // ฝั่งขวา: ค่า min - max และหน่วยด้านล่าง
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
    required IconData? iconLeft, required Color colorLeft, required String titleLeft, required String valueLeft,
    required IconData? iconRight, required Color colorRight, required String titleRight, required String valueRight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              if (iconLeft != null) Icon(iconLeft, color: colorLeft, size: 28) else const SizedBox(width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    Text("$titleLeft : ", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(valueLeft, style: const TextStyle(fontSize: 14, color: Colors.black)),
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
              if (iconRight != null) Icon(iconRight, color: colorRight, size: 28) else const SizedBox(width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    Text("$titleRight : ", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(valueRight, style: const TextStyle(fontSize: 14, color: Colors.black)),
                  ],
                ),
              ),
            ],
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
            colors: [Color(0xFFDCEAF1), Color(0xFFD2E0C4)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "กรอกข้อมูลสภาพดินเพื่อค้นหา\nพืชปลูกที่เหมาะสม",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, height: 1.3),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E9D6),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black87, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🟩 ใส่หน่วยระบุในช่องกรอกต่างๆ
                        _buildInputField("PH", _phController, unit: "pH"),
                        _buildInputField("ความชื้น", _humidController, unit: "%"),
                        _buildInputField("อุณหภูมิ", _tempController, unit: "°C"),
                        _buildInputField("ความเค็ม", _saltyController, unit: "mS/cm"),

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("ธาตุอาหารหลัก", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Checkbox(
                                  value: _isPrimaryNutrientEnabled,
                                  activeColor: const Color(0xFF2E5A36),
                                  onChanged: (val) {
                                    setState(() {
                                      _isPrimaryNutrientEnabled = val ?? false;
                                      if (!_isPrimaryNutrientEnabled) {
                                        _nController.clear();
                                        _pController.clear();
                                        _kController.clear();
                                      }
                                    });
                                  },
                                ),
                                const Text("ระบุค่า"),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        _buildInputField("N", _nController, subLabel: "ไนโตรเจน", unit: "mg/kg", enabled: _isPrimaryNutrientEnabled),
                        _buildInputField("P", _pController, subLabel: "ฟอสฟอรัส", unit: "mg/kg", enabled: _isPrimaryNutrientEnabled),
                        _buildInputField("K", _kController, subLabel: "โพแทสเซียม", unit: "mg/kg", enabled: _isPrimaryNutrientEnabled),

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("ธาตุอาหารรอง", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Checkbox(
                                  value: _isSecondaryNutrientEnabled,
                                  activeColor: const Color(0xFF2E5A36),
                                  onChanged: (val) {
                                    setState(() {
                                      _isSecondaryNutrientEnabled = val ?? false;
                                      if (!_isSecondaryNutrientEnabled) {
                                        _caController.clear();
                                        _mgController.clear();
                                        _sController.clear();
                                      }
                                    });
                                  },
                                ),
                                const Text("ระบุค่า"),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        _buildInputField("Ca", _caController, subLabel: "แคลเซียม", unit: "mg/kg", enabled: _isSecondaryNutrientEnabled),
                        _buildInputField("Mg", _mgController, subLabel: "แมกนีเซียม", unit: "mg/kg", enabled: _isSecondaryNutrientEnabled),
                        _buildInputField("S", _sController, subLabel: "กำมะถัน", unit: "mg/kg", enabled: _isSecondaryNutrientEnabled),

                        const SizedBox(height: 25),

                        // 🟩 ข้อ 4: ปุ่มคู่ ค้นหา + ล้างข้อมูล (Reset)
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 45,
                                child: OutlinedButton(
                                  onPressed: _resetAllFields,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.black54, width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text("ล้างข้อมูล", style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _searchSuitablePlants,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B3838),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text("ค้นหา", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.isLoggedIn 
          ? const AuthNavBar(currentIndex: 2) 
          : const GuestNavBar(currentIndex: 2),
    );
  }

  // 🟩 ฟังก์ชันสร้างช่องกรอก พร้อมรองรับการแสดงหน่วย (unit)
  Widget _buildInputField(
    String label, 
    TextEditingController controller, {
    String? subLabel, 
    String? unit,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: enabled ? Colors.black87 : Colors.grey,
                  ),
                ),
                if (subLabel != null)
                  Text(
                    "($subLabel)",
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12, 
                      color: enabled ? Colors.black54 : Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 6,
            child: Container(
              height: 38, 
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFF3DFB8) : Colors.grey.shade300, 
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: enabled ? Colors.black87 : Colors.grey.shade400, 
                  width: 0.8,
                ),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  // 🟩 แสดงหน่วยที่มุมขวาของช่องกรอกข้อมูล
                  suffixText: unit,
                  suffixStyle: TextStyle(
                    color: enabled ? Colors.black87 : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}