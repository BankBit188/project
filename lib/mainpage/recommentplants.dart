import 'package:flutter/material.dart';

import 'package:project/navbar/navbars.dart'; 
import 'package:project/service/plants_service.dart'; 
// 🛠️ นำเข้า Helper สำหรับคำนวณและแสดงผลพืชแนะนำ
import 'package:project/modal/plant_recommendation_helper.dart';

class RecommendPlantsPage extends StatefulWidget {
  final bool isLoggedIn;
  const RecommendPlantsPage({super.key, this.isLoggedIn = false});

  @override
  State<RecommendPlantsPage> createState() => _RecommendPlantsPageState();
}

class _RecommendPlantsPageState extends State<RecommendPlantsPage> {
  bool _isLoading = false;

  // ตัวแปรสำหรับ Cache ข้อมูลพืช ป้องกันการเรียก API ซ้ำซ้อน
  List<dynamic> _cachedPlants = [];

  // สถานะเปิด/ปิด การใช้งานกลุ่มธาตุอาหารหลัก และ ธาตุอาหารรอง
  bool _isPrimaryNutrientEnabled = false;
  bool _isSecondaryNutrientEnabled = false;

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

  // โหลดและแคชข้อมูลพืชล่วงหน้า
  Future<void> _preloadPlantsData() async {
    try {
      _cachedPlants = await PlantsService.getplants();
    } catch (e) {
      debugPrint("Error preloading plants: $e");
    }
  }

  // ฟังก์ชันล้างข้อมูลทั้งหมด (Reset)
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

  // 🛠️ Pop-up Dialog ปรับแต่งดีไซน์สวยงาม โมเดิร์น
  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5), // สีครีมอ่อนมินิมอล
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: const Color(0xFFE5DECF), width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. ไอคอนแจ้งเตือนพร้อมวงกลมแบบมีมิติ/Glow Effect
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.18),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFE53935),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),

                // 2. หัวข้อแจ้งเตือน
                const Text(
                  "ข้อมูลไม่ถูกต้อง",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // 3. รายละเอียดข้อความ
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF5A626A),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // 4. ปุ่มตกลง/รับทราบ แบบ Gradient สวยงาม
                Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF424242), Color(0xFF212121)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "เข้าใจแล้ว",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
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

  // 🛠️ ฟังก์ชันตรวจเช็กเงื่อนไขและส่งค่าให้ Helper คำนวณ
  void _searchSuitablePlants() async {
    // 1. ตรวจสอบความถูกต้องและขอบเขตตัวเลข (Value Range Guard)
    double? ph = double.tryParse(_phController.text.trim());
    if (_phController.text.isNotEmpty && (ph == null || ph < 0 || ph > 14)) {
      _showWarningDialog("ค่า pH ต้องอยู่ระหว่าง 0.0 ถึง 14.0");
      return;
    }

    double? humid = double.tryParse(_humidController.text.trim());
    if (_humidController.text.isNotEmpty && (humid == null || humid < 0 || humid > 100)) {
      _showWarningDialog("ค่าความชื้นต้องอยู่ระหว่าง 0% ถึง 100%");
      return;
    }

    double? temp = double.tryParse(_tempController.text.trim());
    if (_tempController.text.isNotEmpty && (temp == null || temp < -10 || temp > 60)) {
      _showWarningDialog("ค่าอุณหภูมิต้องอยู่ระหว่าง -10°C ถึง 60°C");
      return;
    }

    double? salty = double.tryParse(_saltyController.text.trim());
    if (_saltyController.text.isNotEmpty && (salty == null || salty < 0)) {
      _showWarningDialog("ค่าความเค็มต้องมากกว่าหรือเท่ากับ 0");
      return;
    }

    // 2. ตรวจสอบเงื่อนไขการติ๊กเปิด Checkbox
    if (_isPrimaryNutrientEnabled) {
      if (_nController.text.trim().isEmpty ||
          _pController.text.trim().isEmpty ||
          _kController.text.trim().isEmpty) {
        _showWarningDialog("กรุณากรอกค่าธาตุอาหารหลัก (N, P, K) ให้ครบ หรือปิด Checkbox");
        return;
      }
    }

    if (_isSecondaryNutrientEnabled) {
      if (_caController.text.trim().isEmpty ||
          _mgController.text.trim().isEmpty ||
          _sController.text.trim().isEmpty) {
        _showWarningDialog("กรุณากรอกค่าธาตุอาหารรอง (Ca, Mg, S) ให้ครบ หรือปิด Checkbox");
        return;
      }
    }

    // 3. ตรวจสอบว่ามีการกรอกข้อมูลอย่างน้อย 1 ช่องหรือไม่
    int activeCriteriaCount = 0;
    if (_phController.text.isNotEmpty) activeCriteriaCount++;
    if (_humidController.text.isNotEmpty) activeCriteriaCount++;
    if (_tempController.text.isNotEmpty) activeCriteriaCount++;
    if (_saltyController.text.isNotEmpty) activeCriteriaCount++;
    if (_isPrimaryNutrientEnabled) activeCriteriaCount += 3;
    if (_isSecondaryNutrientEnabled) activeCriteriaCount += 3;

    if (activeCriteriaCount == 0) {
      _showWarningDialog("กรุณากรอกข้อมูลสภาพดินอย่างน้อย 1 รายการเพื่อค้นหา");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 🟢 4. ส่งข้อมูลไปยัง Helper เพื่อประมวลผล Fuzzy Match และแสดง Bottom Sheet
    await PlantRecommendationHelper.showRecommendations(
      context: context,
      cachedPlants: _cachedPlants,
      customTitle: "พืชที่แนะนำตามค่าดินที่คุณกรอก",
      ph: _phController.text.isNotEmpty ? ph : null,
      humidity: _humidController.text.isNotEmpty ? humid : null,
      temp: _tempController.text.isNotEmpty ? temp : null,
      salty: _saltyController.text.isNotEmpty ? salty : null,
      n: _isPrimaryNutrientEnabled ? double.tryParse(_nController.text.trim()) : null,
      p: _isPrimaryNutrientEnabled ? double.tryParse(_pController.text.trim()) : null,
      k: _isPrimaryNutrientEnabled ? double.tryParse(_kController.text.trim()) : null,
      ca: _isSecondaryNutrientEnabled ? double.tryParse(_caController.text.trim()) : null,
      mg: _isSecondaryNutrientEnabled ? double.tryParse(_mgController.text.trim()) : null,
      s: _isSecondaryNutrientEnabled ? double.tryParse(_sController.text.trim()) : null,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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

  // Widget สร้างช่องกรอกพร้อมแสดงหน่วย
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