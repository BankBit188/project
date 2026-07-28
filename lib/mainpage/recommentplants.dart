import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:project/navbar/navbars.dart'; 
import 'package:project/mainpage/menu.dart'; 
import 'package:project/mainpage/datawarehouse.dart'; 

// 🛠️ นำเข้า Service เพื่อดึงข้อมูลพืช
import 'package:project/service/plants_service.dart'; 

class RecommendPlantsPage extends StatefulWidget {
  final bool isLoggedIn;
  const RecommendPlantsPage({super.key, this.isLoggedIn = false});

  @override
  State<RecommendPlantsPage> createState() => _RecommendPlantsPageState();
}

class _RecommendPlantsPageState extends State<RecommendPlantsPage> {
  int _selectedIndex = 2;
  bool _isLoading = false; // สำหรับแสดงสถานะกำลังประมวลผล

  // เพิ่มลิงก์ทางผ่านหลักของ Ngrok สำหรับจัดการ URL รูปภาพพืช
  static const String ngrokUrl =
      'https://uselessly-disclose-stingray.ngrok-free.dev';

  // 🛠️ สร้าง Controllers สำหรับดักจับและดึงค่าตัวเลขจากช่องกรอกข้อมูลต่างๆ
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
  void dispose() {
    // ล้างหน่วยความจำเมื่อปิดหน้าเพจ
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

  // ฟังก์ชันจัดฟอร์แมตสลับหัว IP รูปภาพเพื่อวิ่งเข้าอุโมงค์ Ngrok ป้องกันลิงก์ตาย
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

  // ฟังก์ชันสำหรับจัดรูปช่วงข้อมูล (เช่น min - max) ป้องกันค่า null พัง
  String _formatRange(dynamic minVal, dynamic maxVal) {
    if (minVal == null && maxVal == null) return '-';
    if (minVal != null && maxVal == null) return '$minVal';
    if (minVal == null && maxVal != null) return '$maxVal';
    if (minVal.toString() == maxVal.toString()) return '$minVal';
    return '$minVal - $maxVal';
  }

  // 🛠️ ฟังก์ชันคำนวณจับคู่ค่าดินเพื่อหาพืชที่เหมาะสมที่สุด 5 อันดับ
  void _searchSuitablePlants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. ดึงข้อมูลพืชทั้งหมดผ่าน Service ของคุณ
      List<dynamic> allPlants = await PlantsService.getplants();

      // 2. แปลงค่าที่ผู้ใช้กรอกเป็นตัวเลข (หากช่องไหนว่างจะให้ค่าเป็น null)
      double? inputPH = double.tryParse(_phController.text);
      double? inputHumid = double.tryParse(_humidController.text);
      double? inputTemp = double.tryParse(_tempController.text);
      double? inputSalty = double.tryParse(_saltyController.text);
      double? inputN = double.tryParse(_nController.text);
      double? inputP = double.tryParse(_pController.text);
      double? inputK = double.tryParse(_kController.text);
      double? inputCa = double.tryParse(_caController.text);
      double? inputMg = double.tryParse(_mgController.text);
      double? inputS = double.tryParse(_sController.text);

      List<Map<String, dynamic>> scoredPlants = [];

      // 3. วนลูปเปรียบเทียบค่าช่วง Min-Max ของพืชทุกต้นในระบบ
      for (var plant in allPlants) {
        int score = 0;

        // ฟังก์ชันช่วยตรวจสอบว่าค่าอยู่ในช่วงที่พืชต้องการไหม
        bool checkRange(double? input, dynamic minVal, dynamic maxVal) {
          if (input == null || minVal == null || maxVal == null) return false;
          double min = double.tryParse(minVal.toString()) ?? 0.0;
          double max = double.tryParse(maxVal.toString()) ?? double.infinity;
          return input >= min && input <= max;
        }

        // เริ่มต้นคิดคะแนนความเหมาะสม (Matching Score)
        if (checkRange(inputPH, plant['minPH'], plant['maxPH'])) score++;
        if (checkRange(inputHumid, plant['minhumid'], plant['maxhumid'])) score++;
        if (checkRange(inputTemp, plant['mintemperature'], plant['maxtemperature'])) score++;
        if (checkRange(inputSalty, plant['minsalty'], plant['maxsalty'])) score++;
        if (checkRange(inputN, plant['minN'], plant['maxN'])) score++;
        if (checkRange(inputP, plant['minP'], plant['maxP'])) score++;
        if (checkRange(inputK, plant['minK'], plant['maxK'])) score++;
        if (checkRange(inputCa, plant['minCa'], plant['maxCa'])) score++;
        if (checkRange(inputMg, plant['minMg'], plant['maxMg'])) score++;
        if (checkRange(inputS, plant['minS'], plant['maxS'])) score++;

        scoredPlants.add({
          'plantData': plant,
          'score': score,
        });
      }

      // 4. เรียงลำดับพืชจากคะแนนมากไปน้อย และคัดมาเฉพาะ 5 อันดับแรก
      scoredPlants.sort((a, b) => b['score'].compareTo(a['score']));
      List<Map<String, dynamic>> top5Plants = scoredPlants.take(5).toList();

      // 5. เปิดแสดงผลลัพธ์ UI ตามรูปแบบในรูปภาพตัวอย่าง
      if (mounted) {
        _showResultsBottomSheet(top5Plants);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการคำนวณ: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🛠️ UI Modal เปิดป๊อปอัปแสดงผลลัพธ์พืช 5 อันดับ
  void _showResultsBottomSheet(List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // ทำให้ขอบนอกโปร่งใสเพื่อโชว์ส่วนโค้งมน
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.95, // สูงประมาณ 95% ของจอ
          decoration: const BoxDecoration(
            color: Color(0xFFF1E6C9), // พื้นหลังครีมสว่างตามธีมแอปพลิเคชัน
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // 🟩 แถบหัวข้อสีเขียวเข้มด้านบนสุดพร้อมปุ่มปิดกากบาท
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E5A36), // สีเขียวเข้มใบไม้
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
                      onPressed: () => Navigator.pop(context), // คลิกแล้วปิดป๊อปอัป
                    ),
                  ],
                ),
              ),
              
              // 📜 รายการพืช 5 อันดับแบบเลื่อนได้
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var plant = items[index]['plantData'];
                    String plantName = plant['normal_name'] ?? 'ไม่ระบุชื่อ';
                    String rawImageUrl = plant['img_url'] ?? plant['img'] ?? '';
                    String formattedImgUrl = _formatImgUrl(rawImageUrl);

                    // 🟩 ห่อด้วย GestureDetector เพื่อให้คลิกการ์ดแล้วเปิด Dialog เหมือนใน plants.dart
                    return GestureDetector(
                      onTap: () => _showPlantDetailDialog(Map<String, dynamic>.from(plant)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F8E5F), // กล่องการ์ดพืชสีเขียวหม่นสไตล์มินิมอล
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF2E5A36), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ลำดับตามด้วยชื่อพืช
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
                            // กรอบรูปภาพพืชขอบมนด้านขวา
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: formattedImgUrl.isNotEmpty
                                  ? Image.network(
                                      formattedImgUrl,
                                      width: 110,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 110,
                                        height: 90,
                                        color: Colors.white24,
                                        child: const Icon(Icons.eco, color: Colors.white, size: 40),
                                      ),
                                    )
                                  : Container(
                                      width: 110,
                                      height: 90,
                                      color: Colors.white24,
                                      child: const Icon(Icons.eco, color: Colors.white, size: 40),
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

  // 🟩 ฟังก์ชันแสดง Modal รายละเอียดข้อมูลพืช (ถอดแบบจาก plants.dart)
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
                              const Text(
                                "ความต้องการและปริมาณการผลิต",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: 'คลิกเพื่อดูรายละเอียด',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'เพิ่มเติม',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          if (webLink != null &&
                                              webLink.isNotEmpty) {
                                            final Uri url = Uri.parse(webLink);
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(
                                                url,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'ไม่สามารถเปิดลิงก์นี้ได้',
                                                  ),
                                                ),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'ไม่มีข้อมูลลิงก์รายละเอียด',
                                                ),
                                              ),
                                            );
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
                horizontal: 25.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "กรอกข้อมูลสภาพดินเพื่อค้นหา\nพืชปลูกที่เหมาะสม",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.3,
                    ),
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
                        // 🛠️ ผูกตัวแปรรับค่าลงในช่องข้อความแต่ละตำแหน่ง
                        _buildInputField("PH", _phController),
                        _buildInputField("ความชื้น", _humidController),
                        _buildInputField("อุณหภูมิ", _tempController),
                        _buildInputField("ความเค็ม", _saltyController),

                        const SizedBox(height: 15),

                        const Text(
                          "ธาตุอาหารหลัก",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInputField("N", _nController),
                        _buildInputField("P", _pController),
                        _buildInputField("K", _kController),

                        const SizedBox(height: 15),

                        const Text(
                          "ธาตุอาหารรอง",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInputField("Ca", _caController),
                        _buildInputField("Mg", _mgController),
                        _buildInputField("S", _sController),

                        const SizedBox(height: 30),

                        // ปุ่มค้นหาที่จะรันฟังก์ชันคำนวณและแสดงผลลัพธ์
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _searchSuitablePlants,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B3838), 
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      "ค้นหา",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
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

  // 🛠️ ปรับให้ Widget รับพารามิเตอร์ Controller ประจำช่องกรอกด้วย
  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 6,
            child: Container(
              height: 32, 
              decoration: BoxDecoration(
                color: const Color(0xFFF3DFB8), 
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black87, width: 0.8),
              ),
              child: TextField(
                controller: controller, // 🛠️ ใส่คอนโทรลเลอร์ที่นี่เพื่อดึงข้อมูลไปใช้
                keyboardType: const TextInputType.numberWithOptions(decimal: true), // รองรับเลขทศนิยม
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
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