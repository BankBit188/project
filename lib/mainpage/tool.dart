import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'
hide ImageSource;

import 'package:project/navbar/navbars.dart';
import 'package:project/mainpage/history.dart';
import 'package:project/mainpage/menu.dart';
import 'package:project/mainpage/profile.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/service/reports_service.dart';
import 'package:project/service/user_service.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:project/service/tool_service.dart';
import 'package:project/service/plants_service.dart';

class ToolPage extends StatefulWidget {
  const ToolPage({super.key});

  @override
  State<ToolPage> createState() => _ToolPageState();
}

class _ToolPageState extends State<ToolPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _authToken;
  String? _userId;

  Map<String, dynamic>? _toolData;
  bool _isLoadingTool = false;

  String _currentDateTimeString = "";

  // ลิงก์ทางผ่านหลักของ Ngrok สำหรับจัดการ URL รูปภาพพืช
  static const String ngrokUrl =
      'https://uselessly-disclose-stingray.ngrok-free.dev';

  // ตัวแปรสำหรับเก็บข้อมูลจังหวัด อำเภอ ตำบล ที่โหลดจาก JSON
  List<dynamic> _thailandData = [];

  @override
  void initState() {
    super.initState();
    _initThaiDateTime();
    _loadToken();
    _loadAddressData();
  }

  // ฟังก์ชันสลับ IP รูปภาพพืชเพื่อวิ่งเข้าอุโมงค์ Ngrok ป้องกันลิงก์ตาย
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

  // ฟังก์ชันจัดรูปช่วงข้อมูล (min - max)
  String _formatRange(dynamic minVal, dynamic maxVal) {
    if (minVal == null && maxVal == null) return '-';
    if (minVal != null && maxVal == null) return '$minVal';
    if (minVal == null && maxVal != null) return '$maxVal';
    if (minVal.toString() == maxVal.toString()) return '$minVal';
    return '$minVal - $maxVal';
  }

  Future<void> _loadAddressData() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/data/thailand_data.json',
      );
      if (!mounted) return;
      setState(() {
        _thailandData = jsonDecode(jsonString);
      });
      print(
        "โหลดข้อมูลที่อยู่ Thailand Data สำเร็จ: ${_thailandData.length} จังหวัด",
      );
    } catch (e) {
      debugPrint("Error loading JSON: $e");
    }
  }

  // 🔹 ฟังก์ชันสำหรับเปิด URL (ใส่ไว้ในตัว Class เดียวกันกับ Widget)
  Future<void> _openUrl(BuildContext context, String? link) async {
    if (link != null && link.isNotEmpty) {
      final Uri url = Uri.parse(link);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเปิดลิงก์นี้ได้')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลลิงก์รายละเอียด')),
      );
    }
  }

  void _initThaiDateTime() {
    initializeDateFormatting('th', null).then((_) {
      final now = DateTime.now();
      final dateNew = DateFormat('d MMMM', 'th').format(now);
      final thaiYear = now.year + 543;
      final timeNew = DateFormat('HH.mm').format(now);

      if (!mounted) return;
      setState(() {
        _currentDateTimeString = "$dateNew $thaiYear   $timeNew";
      });
    });
  }

  Future<void> _loadToken() async {
    String? token = await _secureStorage.read(key: "auth_token");
    String? userId = await _secureStorage.read(key: "Userid");

    if (!mounted) return;
    setState(() {
      _authToken = token;
      _userId = userId;
    });

    if (_userId != null && _authToken != null) {
      _fetchToolData();
    }
  }

  Future<void> _fetchToolData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTool = true;
    });
    try {
      final response = await ToolService.gettoolbyuser(_userId!, _authToken!);
      if (response != null && response['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _toolData = response['data'];
          _isLoadingTool = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingTool = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTool = false;
      });
    }
  }

  String _getName(dynamic item) {
    if (item is Map) {
      return item['name_th'] ?? item['name'] ?? item['name_en'] ?? '';
    }
    return item.toString();
  }

  List<dynamic> _getAmphures(dynamic provinceObj) {
    if (provinceObj is Map) {
      return provinceObj['amphure'] ??
          provinceObj['amphur'] ??
          provinceObj['districts'] ??
          [];
    }
    return [];
  }

  List<dynamic> _getTambons(dynamic amphurObj) {
    if (amphurObj is Map) {
      return amphurObj['tambon'] ??
          amphurObj['district'] ??
          amphurObj['subdistricts'] ??
          [];
    }
    return [];
  }

  //บันทึกข้อมูลสถานที่และที่ตั้ง
  void _showSaveLocationDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();

    String? selectedProvince;
    String? selectedAmphur;
    String? selectedDistrict;

    List<dynamic> amphurList = [];
    List<dynamic> districtList = [];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFF5EFCB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: const BorderSide(color: Colors.black87, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 25.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "ระบุสถานที่และที่ตั้ง",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 25),

                    _buildLocationInputRow(
                      label: "สถานที่ :",
                      child: TextField(
                        controller: titleController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: InputBorder.none,
                          hintText: "เช่น แปลงนาที่ 1",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildLocationInputRow(
                      label: "จังหวัด :",
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedProvince,
                          hint: const Text(
                            "เลือกจังหวัด",
                            style: TextStyle(fontSize: 14),
                          ),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black,
                          ),
                          items: _thailandData.map<DropdownMenuItem<String>>((
                            prov,
                          ) {
                            String name = _getName(prov);
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedProvince = val;
                              selectedAmphur = null;
                              selectedDistrict = null;
                              districtList = [];

                              var provObj = _thailandData.firstWhere(
                                (element) => _getName(element) == val,
                                orElse: () => null,
                              );
                              amphurList = provObj != null
                                  ? _getAmphures(provObj)
                                  : [];
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildLocationInputRow(
                      label: "อำเภอ :",
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAmphur,
                          hint: const Text(
                            "เลือกอำเภอ",
                            style: TextStyle(fontSize: 14),
                          ),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black,
                          ),
                          items: amphurList.map<DropdownMenuItem<String>>((
                            amp,
                          ) {
                            String name = _getName(amp);
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedAmphur = val;
                              selectedDistrict = null;

                              var ampObj = amphurList.firstWhere(
                                (element) => _getName(element) == val,
                                orElse: () => null,
                              );
                              districtList = ampObj != null
                                  ? _getTambons(ampObj)
                                  : [];
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildLocationInputRow(
                      label: "ตำบล :",
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDistrict,
                          hint: const Text(
                            "เลือกตำบล",
                            style: TextStyle(fontSize: 14),
                          ),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black,
                          ),
                          items: districtList.map<DropdownMenuItem<String>>((
                            dt,
                          ) {
                            String name = _getName(dt);
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedDistrict = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () async {
                            if (_authToken == null ||
                                _userId == null ||
                                _authToken!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "ไม่พบข้อมูลการเข้าสู่ระบบ กรุณาเข้าสู่ระบบใหม่อีกครั้ง",
                                  ),
                                ),
                              );
                              return;
                            }

                            if (titleController.text.trim().isEmpty ||
                                selectedProvince == null ||
                                selectedAmphur == null ||
                                selectedDistrict == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "กรุณากรอกข้อมูลสถานที่และเลือกที่ตั้งให้ครบถ้วน",
                                  ),
                                ),
                              );
                              return;
                            }

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              await ToolService.createhistory(
                                userId: _userId!,
                                token: _authToken!,
                                title: titleController.text.trim(),
                                province: selectedProvince!,
                                Amphur: selectedAmphur!,
                                district: selectedDistrict!,
                                toolData: _toolData,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                Navigator.pop(dialogContext);
                                titleController.dispose();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("บันทึกข้อมูลเรียบร้อยแล้ว"),
                                  ),
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HistoryPage(),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("บันทึกข้อมูลไม่สำเร็จ: $e"),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            width: 110,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6BBA90),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.black87,
                                width: 1.2,
                              ),
                            ),
                            child: const Text(
                              "ยืนยัน",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        InkWell(
                          onTap: () {
                            titleController.dispose();
                            Navigator.pop(dialogContext);
                          },
                          child: Container(
                            width: 110,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE26A6A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.black87,
                                width: 1.2,
                              ),
                            ),
                            child: const Text(
                              "ยกเลิก",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLocationInputRow({
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE8C8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black87, width: 1),
            ),
            child: Center(child: child),
          ),
        ),
      ],
    );
  }

  void _recommendPlantsFromToolData() async {
    if (_toolData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ยังไม่มีข้อมูลสภาพดิน กรุณารอโหลดข้อมูลสักครู่"),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      List<dynamic> allPlants = await PlantsService.getplants();

      double? inputPH = double.tryParse(
        _toolData?['pH']?.toString() ?? _toolData?['ph']?.toString() ?? '',
      );
      double? inputHumid = double.tryParse(
        _toolData?['humid']?.toString() ?? '',
      );
      double? inputTemp = double.tryParse(
        _toolData?['temperature']?.toString() ?? '',
      );
      double? inputSalty = double.tryParse(
        _toolData?['salty']?.toString() ?? '',
      );
      double? inputN = double.tryParse(_toolData?['N']?.toString() ?? '');
      double? inputP = double.tryParse(_toolData?['P']?.toString() ?? '');
      double? inputK = double.tryParse(_toolData?['K']?.toString() ?? '');
      double? inputCa = double.tryParse(_toolData?['Ca']?.toString() ?? '');
      double? inputMg = double.tryParse(_toolData?['Mg']?.toString() ?? '');
      double? inputS = double.tryParse(_toolData?['S']?.toString() ?? '');

      List<Map<String, dynamic>> scoredPlants = [];

      for (var plant in allPlants) {
        int score = 0;

        bool checkRange(double? input, dynamic minVal, dynamic maxVal) {
          if (input == null || minVal == null || maxVal == null) return false;
          double min = double.tryParse(minVal.toString()) ?? 0.0;
          double max = double.tryParse(maxVal.toString()) ?? double.infinity;
          return input >= min && input <= max;
        }

        if (checkRange(inputPH, plant['minPH'], plant['maxPH'])) score++;
        if (checkRange(inputHumid, plant['minhumid'], plant['maxhumid']))
          score++;
        if (checkRange(
          inputTemp,
          plant['mintemperature'],
          plant['maxtemperature'],
        ))
          score++;
        if (checkRange(inputSalty, plant['minsalty'], plant['maxsalty']))
          score++;
        if (checkRange(inputN, plant['minN'], plant['maxN'])) score++;
        if (checkRange(inputP, plant['minP'], plant['maxP'])) score++;
        if (checkRange(inputK, plant['minK'], plant['maxK'])) score++;
        if (checkRange(inputCa, plant['minCa'], plant['maxCa'])) score++;
        if (checkRange(inputMg, plant['minMg'], plant['maxMg'])) score++;
        if (checkRange(inputS, plant['minS'], plant['maxS'])) score++;

        scoredPlants.add({'plantData': plant, 'score': score});
      }

      scoredPlants.sort((a, b) => b['score'].compareTo(a['score']));
      List<Map<String, dynamic>> top5Plants = scoredPlants.take(5).toList();

      if (mounted) {
        Navigator.pop(context);
        _showResultsBottomSheet(top5Plants);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาดในการคำนวณ: $e")));
      }
    }
  }

  void _showResultsBottomSheet(List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
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
                      "แนะนำพืชปลูกที่เหมาะสมกับดิน",
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
                    String plantName = plant['normal_name'] ?? 'ไม่ระบุชื่อ';
                    String rawImageUrl =
                        plant['img_cloudinary'] ?? plant['img'] ?? '';
                    String formattedImgUrl = _formatImgUrl(rawImageUrl);

                    // 🟩 เพิ่ม GestureDetector ให้สามารถคลิกการ์ดพืชแล้วเปิด Modal ดูรายละเอียดได้
                    return GestureDetector(
                      onTap: () => _showPlantDetailDialog(
                        Map<String, dynamic>.from(plant),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F8E5F),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF2E5A36),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${index + 1} $plantName",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: formattedImgUrl.isNotEmpty
                                  ? Image.network(
                                      formattedImgUrl,
                                      width: 110,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 110,
                                                height: 90,
                                                color: Colors.white24,
                                                child: const Icon(
                                                  Icons.eco,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                              ),
                                    )
                                  : Container(
                                      width: 110,
                                      height: 90,
                                      color: Colors.white24,
                                      child: const Icon(
                                        Icons.eco,
                                        color: Colors.white,
                                        size: 40,
                                      ),
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
        );
      },
    );
  }

  // 🟩 ฟังก์ชันสำหรับเปิด Dialog แสดงข้อมูลรายละเอียดพืช (สไตล์ plants.dart)
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

    String? supplylink = item['link_supply'] ?? 'ไม่มีลิงก์แหล่งซื้อ';
    String? demandlink = item['link_demand'] ?? 'ไม่มีลิงก์แหล่งขาย';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
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
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 28,
                        color: Colors.black,
                      ),
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
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
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
                        Text(
                          "ชื่อสามัญ : $normalName",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "ชื่อวิทยาศาสตร์ : $scientificName",
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "ชื่ออื่นๆ : $otherName",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 5),

                        HtmlWidget(
                          detaill,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.black,
                          ),
                          onTapUrl: (url) async {
                            final Uri uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                              return true;
                            }
                            return false;
                          },
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          "ลักษณะทั่วไป",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        HtmlWidget(
                          nature,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.black,
                          ),
                          onTapUrl: (url) async {
                            final Uri uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                              return true;
                            }
                            return false;
                          },
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          "ข้อมูลการปลูก",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        HtmlWidget(
                          plant,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.black,
                          ),
                          onTapUrl: (url) async {
                            final Uri uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                              return true;
                            }
                            return false;
                          },
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          "การดูแลรักษา",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        HtmlWidget(
                          care,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.black,
                          ),
                          onTapUrl: (url) async {
                            final Uri uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                              return true;
                            }
                            return false;
                          },
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          "การเก็บเกี่ยว",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        HtmlWidget(
                          harvest,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.black,
                          ),
                          onTapUrl: (url) async {
                            final Uri uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                              return true;
                            }
                            return false;
                          },
                        ),

                        const Divider(color: Colors.black26, height: 25),

                        const Center(
                          child: Text(
                            "สภาพดินและธาตุอาหารในดินที่เหมาะสม",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        Center(
                          child: Wrap(
                            spacing: 15,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildNutrientText(
                                "N",
                                _formatRange(item['minN'], item['maxN']),
                              ),
                              _buildNutrientText(
                                "P",
                                _formatRange(item['minP'], item['maxP']),
                              ),
                              _buildNutrientText(
                                "K",
                                _formatRange(item['minK'], item['maxK']),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: Wrap(
                            spacing: 15,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildNutrientText(
                                "Ca",
                                _formatRange(item['minCa'], item['maxCa']),
                              ),
                              _buildNutrientText(
                                "Mg",
                                _formatRange(item['minMg'], item['maxMg']),
                              ),
                              _buildNutrientText(
                                "S",
                                _formatRange(item['minS'], item['maxS']),
                              ),
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
                                valueRight: _formatRange(
                                  item['minPH'],
                                  item['maxPH'],
                                ),
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
                        Center(
                          child: Column(
                            children: [
                              // 🟢 หัวข้อหลัก
                              const Text(
                                "ความต้องการและปริมาณการผลิต",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 📦 1. หัวข้อย่อย: ปริมาณการผลิต (Supply)
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
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
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
                                        ..onTap = () => _openUrl(
                                          context,
                                          supplylink,
                                        ), // 🔗 เรียกใช้ supplyLink
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 📈 2. หัวข้อย่อย: ความต้องการ (Demand)
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
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
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
                                        ..onTap = () => _openUrl(
                                          context,
                                          demandlink,
                                        ), // 🔗 เรียกใช้ demandLink
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

  // 🟩 Helper สำหรับสร้างข้อความธาตุอาหาร
  Widget _buildNutrientText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: [
          TextSpan(
            text: "$label ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const TextSpan(
            text: ": ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // 🟩 Helper สำหรับสร้างแถวแสดงค่าสภาพแวดล้อม
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
          flex: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (iconLeft != null)
                Icon(iconLeft, color: colorLeft, size: 28)
              else
                const SizedBox(width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "$titleLeft : ",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      valueLeft,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (iconRight != null)
                Icon(iconRight, color: colorRight, size: 28)
              else
                const SizedBox(width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "$titleRight : ",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      valueRight,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "อุปกรณ์",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isLoadingTool
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black87,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  size: 28,
                                  color: Colors.black87,
                                ),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _fetchToolData();
                                  _initThaiDateTime();
                                },
                              ),
                      ],
                    ),

                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.black54),
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.menu,
                          size: 35,
                          color: Colors.black,
                        ),
                        offset: const Offset(0, 45),
                        color: const Color(0xFFFCEEBA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                            color: Colors.black54,
                            width: 1,
                          ),
                        ),
                        onSelected: (String value) async {
                          if (value == 'profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
                          } else if (value == 'report') {
                            _showReportDialog(context);
                          } else if (value == 'history') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryPage(),
                              ),
                            );
                          } else if (value == 'logout') {
                            await _secureStorage.delete(key: "auth_token");
                            await _secureStorage.delete(key: "Userid");

                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MenuPage(isLoggedIn: false),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              _buildPopupMenuItem('profile', 'โปรไฟล์'),
                              const PopupMenuDivider(height: 1),
                              _buildPopupMenuItem(
                                'history',
                                'ประวัติการบันทึก',
                              ),
                              const PopupMenuDivider(height: 1),
                              _buildPopupMenuItem('report', 'รายงานปัญหา'),
                              const PopupMenuDivider(height: 1),
                              _buildPopupMenuItem('logout', 'ออกจากระบบ'),
                            ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Text(
                  _currentDateTimeString.isNotEmpty
                      ? _currentDateTimeString
                      : "กำลังโหลดเวลา...",
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 35),

                _buildElementRow(
                  "N",
                  _toolData?['N']?.toString() ?? "-",
                  "P",
                  _toolData?['P']?.toString() ?? "-",
                  "K",
                  _toolData?['K']?.toString() ?? "-",
                ),
                const SizedBox(height: 20),

                _buildElementRow(
                  "Ca",
                  _toolData?['Ca']?.toString() ?? "-",
                  "Mg",
                  _toolData?['Mg']?.toString() ?? "-",
                  "S",
                  _toolData?['S']?.toString() ?? "-",
                ),
                const SizedBox(height: 40),

                _buildDetailRow(
                  Icons.water_drop,
                  "ความชื้น",
                  _toolData != null
                      ? "${_toolData!['humid']} %"
                      : "กำลังโหลด...",
                  Colors.lightBlue,
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  Icons.science,
                  "ค่า pH",
                  _toolData != null ? "${_toolData!['PH']}" : "กำลังโหลด...",
                  Colors.purple,
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  Icons.thermostat,
                  "อุณหภูมิ",
                  _toolData != null
                      ? "${_toolData!['temperature']} C°"
                      : "กำลังโหลด...",
                  Colors.black54,
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  Icons.waves,
                  "ความเค็ม",
                  _toolData != null
                      ? "${_toolData!['salty']} us/cm"
                      : "กำลังโหลด...",
                  Colors.black54,
                ),

                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomButton(
                      "บันทึกข้อมูล",
                      onTap: () => _showSaveLocationDialog(context),
                    ),
                    _buildBottomButton(
                      "พืชปลูกที่เหมาะสม",
                      onTap: _recommendPlantsFromToolData,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AuthNavBar(currentIndex: 4),
    );
  }

  //แจ้งปัญหา
  void _showReportDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailController = TextEditingController();
    File? selectedImageFile;
    final ImagePicker picker = ImagePicker();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFFCEEBA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.black87, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Text(
                              "แจ้งปัญหา",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () {
                                titleController.dispose();
                                detailController.dispose();
                                Navigator.of(context).pop();
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text(
                            "หัวข้อ : ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 35,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black54),
                              ),
                              child: TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "รายละเอียด",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black54),
                        ),
                        child: TextField(
                          controller: detailController,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Text(
                            "รูปภาพ : ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              selectedImageFile != null
                                  ? selectedImageFile!.path.split('/').last
                                  : "ยังไม่เลือกรูปภาพ",
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.black54),
                            ),
                            child: TextButton(
                              onPressed: () async {
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (image != null) {
                                  setDialogState(() {
                                    selectedImageFile = File(image.path);
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                "เลือกรูปภาพ",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 40,
                          width: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6BBA90),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black87),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              if (titleController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('กรุณากรอกหัวข้อแจ้งปัญหา'),
                                  ),
                                );
                                return;
                              }

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                              try {
                                String currentUsername = "ไม่ระบุชื่อผู้ใช้";
                                if (_userId != null && _authToken != null) {
                                  try {
                                    final userData =
                                        await UserService.getUserById(
                                          _userId!,
                                          _authToken,
                                        );
                                    currentUsername =
                                        userData['username'] ??
                                        "ไม่ระบุชื่อผู้ใช้";
                                  } catch (userError) {
                                    print("ดึงชื่อผู้ใช้ล้มเหลว: $userError");
                                  }
                                }

                                Map<String, String> reportData = {
                                  'username': currentUsername,
                                  'reporttitle': titleController.text.trim(),
                                  'reportdetail': detailController.text.trim(),
                                };

                                final response =
                                    await ReportsService.createReport(
                                      reportData: reportData,
                                      imageFile: selectedImageFile,
                                    );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response['message'] ??
                                            'ส่งรายงานสำเร็จ',
                                      ),
                                    ),
                                  );
                                  titleController.dispose();
                                  detailController.dispose();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'ส่งข้อมูลล้มเหลวเนื่องจาก: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "ส่ง",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildElementRow(
    String l1,
    String v1,
    String l2,
    String v2,
    String l3,
    String v3,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _elementText(l1, v1),
        _elementText(l2, v2),
        _elementText(l3, v3),
      ],
    );
  }

  Widget _elementText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 20),
        children: [
          TextSpan(
            text: "$label ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
          ),
          TextSpan(text: ": $value"),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 35, color: iconColor),
        const SizedBox(width: 15),
        Text("$label   : $value", style: const TextStyle(fontSize: 20)),
      ],
    );
  }

  Widget _buildBottomButton(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF4D9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black87),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
