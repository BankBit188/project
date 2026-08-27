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

  // เช็คว่าเลือกครบทุกอันหรือไม่
  bool get _isAllSelected => _selectedParams.values.every((val) => val);

  // 🟢 ฟังก์ชันดึงค่าปัจจุบันจาก toolData มาแสดงผลบน UI
  String _getDisplayValue(String key) {
    final Map<String, List<String>> keyMap = {
      'ph': ['PH', 'ph'],
      'humidity': ['humid'],
      'temp': ['temperature'],
      'salty': ['salty'],
      'n': ['N', 'n'],
      'p': ['P', 'p'],
      'k': ['K', 'k'],
      'ca': ['Ca', 'ca'],
      'mg': ['Mg', 'mg'],
      's': ['S', 's'],
    };

    final possibleKeys = keyMap[key] ?? [];
    for (var k in possibleKeys) {
      if (widget.toolData?.containsKey(k) == true &&
          widget.toolData![k] != null) {
        return "${widget.toolData![k]}";
      }
    }
    return "-";
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

    final navigator = Navigator.of(context);

    double? getValue(String key, List<String> possibleKeys) {
      if (_selectedParams[key] != true) return null;
      for (var k in possibleKeys) {
        if (widget.toolData?.containsKey(k) == true &&
            widget.toolData![k] != null) {
          return double.tryParse(widget.toolData![k].toString());
        }
      }
      return null;
    }

    final ph = getValue('ph', ['PH', 'ph']);
    final humidity = getValue('humidity', ['humid']);
    final temp = getValue('temp', ['temperature']);
    final salty = getValue('salty', ['salty']);
    final n = getValue('n', ['N', 'n']);
    final p = getValue('p', ['P', 'p']);
    final k = getValue('k', ['K', 'k']);
    final ca = getValue('ca', ['Ca', 'ca']);
    final mg = getValue('mg', ['Mg', 'mg']);
    final s = getValue('s', ['S', 's']);

    // 1. ปิด Modal เลือกค่า
    navigator.pop();

    // 2. แสดง Dialog Loading
    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
        ),
      ),
    );

    // 3. หน่วงเวลาเล็กน้อย (300ms) ให้ UI แสดงภาพกำลังโหลดที่นุ่มนวล
    await Future.delayed(const Duration(milliseconds: 300));

    // 4. ปิด Dialog Loading และเปิดหน้าคำแนะนำพืช
    if (navigator.context.mounted) {
      Navigator.of(navigator.context).pop();

      PlantRecommendationHelper.showRecommendations(
        context: navigator.context,
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