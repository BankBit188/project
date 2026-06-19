import 'package:flutter/material.dart';
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
    } finally { // 🛠️ แก้ไขคำสะกดเป็น "finally" เพื่อป้องกันการเกิด Error
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🛠️ UI Modal เปิดป๊อปอัปแสดงผลลัพธ์พืช 5 อันดับ (ลอกเลียนแบบดีไซน์จากรูปที่ 1 ทั้งหมด)
  void _showResultsBottomSheet(List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // ทำให้ขอบนอกโปร่งใสเพื่อโชว์ส่วนโค้งมน
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.95, // สูงประมาณ 80% ของจอ
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
                    String imageUrl = plant['img_url'] ?? ''; // ลิงก์รูปภาพพืชจากฐานข้อมูล

                    return Container(
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
                            ),
                          ),
                          // กรอบรูปภาพพืชขอบมนด้านขวา
                          Container(
                            width: 110,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(15),
                              image: imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.eco, color: Colors.white, size: 40)
                                : null,
                          ),
                        ],
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