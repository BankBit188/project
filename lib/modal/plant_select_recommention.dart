import 'package:flutter/material.dart';
import 'package:project/modal/plant_recommendation_helper.dart';

class PlantSelectRecommendationDialog extends StatefulWidget {
  final Map<String, dynamic>? toolData;

  const PlantSelectRecommendationDialog({
    super.key,
    required this.toolData,
  });

  @override
  State<PlantSelectRecommendationDialog> createState() =>
      _PlantSelectRecommendationDialogState();
}

class _PlantSelectRecommendationDialogState
    extends State<PlantSelectRecommendationDialog> {
  // 🎨 ธีมสีสอดคล้องกับหน้าอื่นๆ ในแอป
  static const Color modalBg = Color(0xFFE8EFE6);
  static const Color primaryGreen = Color(0xFF4A7C59);
  static const Color textColor = Color(0xFF212522);

  // 📌 สถานะการเลือกค่า Checkbox แต่ละรายการ (เริ่มต้นเลือกทั้งหมด)
  final Map<String, bool> _selectedParams = {
    'ph': true,
    'humidity': true,
    'temp': true,
    'salty': true,
    'n': true,
    'p': true,
    'k': true,
    'ca': true,
    'mg': true,
    's': true,
  };

  // 📌 ข้อความแสดงผลบน UI
  final Map<String, String> _paramLabels = {
    'ph': 'ค่า pH',
    'humidity': 'ความชื้น (%)',
    'temp': 'อุณหภูมิ (°C)',
    'salty': 'ความเค็ม (us/cm)',
    'n': 'ไนโตรเจน (N)',
    'p': 'ฟอสฟอรัส (P)',
    'k': 'โพแทสเซียม (K)',
    'ca': 'แคลเซียม (Ca)',
    'mg': 'แมกนีเซียม (Mg)',
    's': 'กำมะถัน (S)',
  };

  // 📌 รวมรูปแบบ Key ทั้งหมดที่อาจถูกส่งมาจาก API/Sensor
  static const Map<String, List<String>> _keyMapping = {
    'ph': ['PH', 'ph', 'pH'],
    'humidity': ['humid', 'humidity', 'moisture'],
    'temp': ['temperature', 'temp'],
    'salty': ['salty', 'salt', 'ec', 'EC'],
    'n': ['N', 'n'],
    'p': ['P', 'p'],
    'k': ['K', 'k'],
    'ca': ['Ca', 'ca'],
    'mg': ['Mg', 'mg'],
    's': ['S', 's'],
  };

  // เช็คว่าเลือกครบทุกอันหรือไม่
  bool get _isAllSelected => _selectedParams.values.every((val) => val);

  // 🟢 ฟังก์ชันดึงค่า Raw จาก toolData โดยค้นตาม Key Mapping
  dynamic _getRawValue(String key) {
    final possibleKeys = _keyMapping[key] ?? [];
    for (var k in possibleKeys) {
      if (widget.toolData?.containsKey(k) == true &&
          widget.toolData![k] != null) {
        return widget.toolData![k];
      }
    }
    return null;
  }

  // 🟢 ฟังก์ชันดึงค่าสำหรับแสดงบน UI
  String _getDisplayValue(String key) {
    final val = _getRawValue(key);
    return val != null ? "$val" : "-";
  }

  // ฟังก์ชันเลือก / ยกเลิก ทั้งหมด
  void _toggleSelectAll(bool? value) {
    setState(() {
      final newValue = value ?? false;
      _selectedParams.updateAll((key, _) => newValue);
    });
  }

  // 🟢 ฟังก์ชันส่งค่าที่เลือก + แสดง Dialog Loading
  Future<void> _submitSelection() async {
    if (!_selectedParams.values.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอย่างน้อย 1 รายการ')),
      );
      return;
    }

    // แปลงค่าจาก toolData เป็น double ตามที่เลือกไว้
    double? getParsedValue(String key) {
      if (_selectedParams[key] != true) return null;
      final rawVal = _getRawValue(key);
      if (rawVal == null) return null;
      return double.tryParse(rawVal.toString());
    }

    final ph = getParsedValue('ph');
    final humidity = getParsedValue('humidity');
    final temp = getParsedValue('temp');
    final salty = getParsedValue('salty');
    final n = getParsedValue('n');
    final p = getParsedValue('p');
    final k = getParsedValue('k');
    final ca = getParsedValue('ca');
    final mg = getParsedValue('mg');
    final s = getParsedValue('s');

    // 1. ปิด Modal เลือกค่า
    Navigator.of(context).pop();

    // 2. แสดง Dialog Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
        ),
      ),
    );

    // 3. หน่วงเวลาเล็กน้อย (300ms) ให้ UI นุ่มนวล
    await Future.delayed(const Duration(milliseconds: 300));

    // 4. เช็คสถานะ Context ป้องกัน Exception และเปิดหน้าคำแนะนำพืช
    if (!mounted) return;
    Navigator.of(context).pop(); // ปิด Dialog Loading

    PlantRecommendationHelper.showRecommendations(
      context: context,
      customTitle: "พืชปลูกที่เหมาะสมกับสภาพดินที่เลือก",
      ph: ph,
      humidity: humidity,
      temp: temp,
      salty: salty,
      n: n,
      p: p,
      k: k,
      ca: ca,
      mg: mg,
      s: s,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final dialogMaxWidth =
        mediaQuery.size.width > 600 ? 460.0 : mediaQuery.size.width * 0.90;

    return Dialog(
      backgroundColor: modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.black54, width: 1),
      ),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "เลือกค่าที่ต้องการประมวลผล",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.black26),

              // Checkbox Select All
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black38),
                ),
                child: CheckboxListTile(
                  activeColor: primaryGreen,
                  title: const Text(
                    "เลือกทั้งหมด (Check All)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  value: _isAllSelected,
                  onChanged: _toggleSelectAll,
                ),
              ),
              const SizedBox(height: 10),

              // รายการ Checkbox แต่ละค่า + ค่าปัจจุบัน
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Column(
                      children: _selectedParams.keys.map((key) {
                        return CheckboxListTile(
                          dense: true,
                          activeColor: primaryGreen,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _paramLabels[key] ?? key,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                _getDisplayValue(key),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          value: _selectedParams[key],
                          onChanged: (bool? val) {
                            setState(() {
                              _selectedParams[key] = val ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ปุ่มยืนยัน
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submitSelection,
                  child: const Text(
                    "ค้นหาพืชปลูกที่เหมาะสม",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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