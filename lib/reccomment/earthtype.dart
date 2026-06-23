import 'package:flutter/material.dart';
import 'package:project/service/plants_service.dart'; // 👈 Import แพ็กเกจของ PlantsService เข้ามาใช้งาน

class EarthTypePage extends StatefulWidget {
  const EarthTypePage({super.key});

  @override
  State<EarthTypePage> createState() => _EarthTypePageState();
}

class _EarthTypePageState extends State<EarthTypePage> {
  List<dynamic> _allRawItems = []; // 🔹 เก็บข้อมูลพืชดิบทั้งหมดจากหลังบ้าน
  List<dynamic> _filteredItems = []; // 🔹 เก็บข้อมูลพืชที่กรองแยกประเภทดินแล้ว
  List<dynamic> _currentPageItems = []; // 🔹 เก็บข้อมูลพืชที่จะเฉือนแสดงเฉพาะในหน้าปัจจุบัน
  
  bool _isLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  final int _itemsPerPage = 3; // แสดงหน้าละ 3 ชิ้นตามโครงสร้างเดิม
  String _selectedSoilType = "ดินร่วน"; // ค่าเริ่มต้นจำลองการคัดเลือกเป็นประเภทดินร่วน

  // 🔹 ตัวแปรเก็บค่าประเภทพืชสำหรับปุ่มตัวกรอง (Icon)
  String _selectedPlantType = "ทั้งหมด"; // ตัวเลือก: ทั้งหมด, พืชไร่, พืชสวน, พืชเศรษฐกิจ

  // 🔹 เพิ่มตัวแปร Ngrok สำหรับแปลงที่อยู่รูปภาพ
  static const String ngrokUrl = 'https://uselessly-disclose-stungray.ngrok-free.dev';

  @override
  void initState() {
    super.initState();
    _fetchDataFromAPI();
  }

  // ฟังก์ชันช่วยจัดฟอร์แมตสลับหัว IP รูปภาพเข้าสู่อุโมงค์ Ngrok ป้องกันลิงก์ตาย
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

  // 🔹 ฟังก์ชันติดต่อรับข้อมูลพืชทั้งหมดจากคลาสพืชบริการ
  Future<void> _fetchDataFromAPI() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await PlantsService.getplants(); // ดึงข้อมูลโครงสร้างพืช

      final List<dynamic> fetchedData = response is List 
          ? response 
          : (response['data'] ?? []);

      if (mounted) {
        setState(() {
          _allRawItems = fetchedData;
          _applyFilterAndPagination(); // คัดกรองและตัดหน้ากระดาษ
        });
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการดึงข้อมูลประเภทดินพืช: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔹 ฟังก์ชันรับค่าชื่อดินภาษาไทย -> แตกยอดคืนค่ารหัสสากล (1, 2, 3)
  int _getSoilTypeCode(String soilName) {
    switch (soilName) {
      case "ดินร่วน": return 1;
      case "ดินเหนียว": return 2;
      case "ดินทราย": return 3;
      default: return 1;
    }
  }

  // 🔹 ฟังก์ชันรับค่าชื่อประเภทพืชภาษาไทย -> คืนค่าเป็นรหัสรหัสสากล (1, 2, 3) ตามที่ API ส่งมา
  int _getPlantTypeCode(String plantTypeName) {
    switch (plantTypeName) {
      case "พืชไร่": return 1;
      case "พืชสวน": return 2;
      case "พืชเศรษฐกิจ": return 3;
      default: return 0;
    }
  }

  // 🔹 ฟังก์ชันคำนวณคัดแยกคุณสมบัติดิน และจัดส่วนการแบ่งหน้า (Pagination)
  void _applyFilterAndPagination() {
    int targetSoilCode = _getSoilTypeCode(_selectedSoilType);

    // 1. กรองข้อมูลจากฟิลด์ "earthTypeCode" ให้ตรงกับประเภทดินที่กดเลือก
    List<dynamic> tempFiltered = _allRawItems.where((item) {
      var codeValue = item['earthTypeCode'];
      if (codeValue == null) return false;
      
      int currentCode = codeValue is int ? codeValue : int.tryParse(codeValue.toString()) ?? 0;
      return currentCode == targetSoilCode;
    }).toList();

    // 2. 🛠️ แก้ไขจุดนี้: ทำการกรองประเภทพืช (plantsTypeCode) ต่อจากที่กรองเรื่องดินเสร็จแล้ว
    if (_selectedPlantType != "ทั้งหมด") {
      int targetPlantCode = _getPlantTypeCode(_selectedPlantType);
      
      tempFiltered = tempFiltered.where((item) {
        var typeValue = item['plantsTypeCode']; // ใช้คีย์ plantsTypeCode ตามที่ API ส่งมา
        if (typeValue == null) return false;

        int currentPlantCode = typeValue is int ? typeValue : int.tryParse(typeValue.toString()) ?? 0;
        return currentPlantCode == targetPlantCode;
      }).toList();
    }

    // กำหนดค่าผลลัพธ์สุดท้ายให้ตัวแปรแสดงผล
    _filteredItems = tempFiltered;

    // 3. ปรับยอดจำนวนหน้าแถบ Pagination ทั้งหมดใหม่
    _lastPage = (_filteredItems.length / _itemsPerPage).ceil();
    if (_lastPage < 1) _lastPage = 1;

    // 4. ป้องกันหน้าปัจจุบันเตลิดกรณีเปลี่ยนชิปแล้วหน้าเกินขอบเขต
    if (_currentPage > _lastPage) _currentPage = 1;

    // 5. หั่นสไลด์ข้อมูลมาฉายในหน้าปัจจุบัน (เช่น หน้าละ 3 ตัว)
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    _currentPageItems = _filteredItems
        .skip(startIndex)
        .take(_itemsPerPage)
        .toList();
  }

  // 🔹 ฟังก์ชันสำหรับจัดรูปช่วงข้อมูล (เช่น min - max)
  String _formatRange(dynamic minVal, dynamic maxVal) {
    if (minVal == null && maxVal == null) return '-';
    if (minVal != null && maxVal == null) return '$minVal';
    if (minVal == null && maxVal != null) return '$maxVal';
    if (minVal.toString() == maxVal.toString()) return '$minVal';
    return '$minVal - $maxVal';
  }

  // 🔹 หน้าต่าง Dialog แสดงผลรายละเอียดคุณสมบัติพืชและการจัดเรียงตามรูปภาพ UI ล่าสุด
  void _showPlantDetailDialog(Map<String, dynamic> item) {
    String normalName = item['normal_name'] ?? 'ไม่มีชื่อพืช';
    String scientificName = item['scientific_name'] ?? 'ไม่มีชื่อวิทยาศาสตร์';
    String otherName = item['other_name'] ?? 'ไม่มีชื่ออื่นๆ';
    String imgUrl = _formatImgUrl(item['img_url'] ?? item['img'] ?? '');
    String detaill = item['detaill'] ?? 'ไม่มีข้อมูลรายละเอียดพืช';
    String nature = item['nature'] ?? 'ไม่มีข้อมูลลักษณะทั่วไป';
    String care = item['care'] ?? 'ไม่มีข้อมูลการดูแล';
    String harvest = item['harvest'] ?? 'ไม่มีข้อมูลการเก็บเกี่ยว';

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
                      imgUrl, width: 220, height: 220, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 220, height: 220, color: Colors.grey.shade300,
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
                        Text(detaill, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("ลักษณะทั่วไป", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(nature, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("การดูแลรักษา", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(care, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("การเก็บเกี่ยว", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(harvest, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
                        
                        const Divider(color: Colors.black26, height: 25),
                        
                        const Center(
                          child: Text(
                            "สภาพดินและธาตุอาหารในดินที่เหมาะสม",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        Center(
                          child: Wrap(
                            spacing: 15, 
                            runSpacing: 10, 
                            alignment: WrapAlignment.center,
                            children: [
                              _buildNutrientText("N", _formatRange(item['minN'], item['maxN'])),
                              _buildNutrientText("P", _formatRange(item['minP'], item['maxP'])),
                              _buildNutrientText("K", _formatRange(item['minK'], item['maxK'])),
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
                              _buildNutrientText("Ca", _formatRange(item['minCa'], item['maxCa'])),
                              _buildNutrientText("Mg", _formatRange(item['minMg'], item['maxMg'])),
                              _buildNutrientText("S", _formatRange(item['minS'], item['maxS'])),
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
                                valueLeft: "${_formatRange(item['minhumid'], item['maxhumid'])} %",
                                iconRight: Icons.grid_3x3, 
                                colorRight: Colors.black87, 
                                titleRight: "pH", 
                                valueRight: _formatRange(item['minPH'], item['maxPH']),
                              ),
                              const SizedBox(height: 16),
                              _buildEnvGridRow(
                                iconLeft: Icons.thermostat, 
                                colorLeft: Colors.black87, 
                                titleLeft: "อุณหภูมิ", 
                                valueLeft: "${_formatRange(item['mintemperature'], item['maxtemperature'])} °C",
                                iconRight: Icons.waves, 
                                colorRight: Colors.brown, 
                                titleRight: "ความเค็ม", 
                                valueRight: "${_formatRange(item['minsalty'], item['maxsalty'])} mS/cm",
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

  Widget _buildNutrientText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: [
          TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const TextSpan(text: ": ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEnvGridRow({
    required IconData iconLeft, required Color colorLeft, required String titleLeft, required String valueLeft,
    required IconData iconRight, required Color colorRight, required String titleRight, required String valueRight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(iconLeft, color: colorLeft, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "$titleLeft : ",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Text(
                      valueLeft,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),
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
              Icon(iconRight, color: colorRight, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "$titleRight : ",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Text(
                      valueRight,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 28, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "แนะนำพืชปลูกตามประเภทดิน",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EAE1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'ค้นหา เช่น ชื่อพืช',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip("ดินร่วน"),
                    _buildFilterChip("ดินเหนียว"),
                    _buildFilterChip("ดินทราย"),
                    const Spacer(),
                    
                    PopupMenuButton<String>(
                      icon: Icon(
                        _selectedPlantType == "ทั้งหมด" ? Icons.filter_alt_outlined : Icons.filter_alt, 
                        size: 28, 
                        color: _selectedPlantType == "ทั้งหมด" ? Colors.black : const Color(0xFF5A45FF)
                      ),
                      tooltip: 'กรองประเภทพืช',
                      onSelected: (String value) {
                        setState(() {
                          _selectedPlantType = value;
                          _currentPage = 1;
                          _applyFilterAndPagination(); 
                        });
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(value: "ทั้งหมด", child: Text("พืชทั้งหมด")),
                        const PopupMenuItem<String>(value: "พืชไร่", child: Text("พืชไร่")),
                        const PopupMenuItem<String>(value: "พืชสวน", child: Text("พืชสวน")),
                        const PopupMenuItem<String>(value: "พืชเศรษฐกิจ", child: Text("พืชเศรษฐกิจ")),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _currentPageItems.isEmpty
                          ? const Center(
                              child: Text(
                                "ไม่มีพืชที่เหมาะกับประเภทดินนี้",
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _currentPageItems.length,
                              itemBuilder: (context, index) {
                                final item = _currentPageItems[index];
                                return GestureDetector(
                                  onTap: () => _showPlantDetailDialog(item),
                                  child: _buildItemCard(
                                    item['normal_name'] ?? 'ไม่มีชื่อพืช',
                                    item['img_url'] ?? 'https://via.placeholder.com/150',
                                  ),
                                );
                              },
                            ),
                ),
                _buildDynamicPagination(),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isActive = _selectedSoilType == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSoilType = label;
          _currentPage = 1; 
          _applyFilterAndPagination();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFC5DC9D) : const Color(0xFFE2EAD2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildItemCard(String title, String imgUrl) {
    String formattedImgUrl = _formatImgUrl(imgUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDB4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title, 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              formattedImgUrl, 
              width: 110, height: 110, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 110, height: 110, color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicPagination() {
    List<Widget> pageButtons = [];

    pageButtons.add(_buildPageBtn("<", disabled: _currentPage == 1, onTap: () {
      if (_currentPage > 1) {
        setState(() => _currentPage--);
        _applyFilterAndPagination();
      }
    }));

    int range = 1; 

    if (_lastPage <= 5) {
      for (int i = 1; i <= _lastPage; i++) {
        pageButtons.add(_buildPageBtn(i.toString(), isActive: _currentPage == i, onTap: () {
          setState(() => _currentPage = i);
          _applyFilterAndPagination();
        }));
      }
    } else {
      pageButtons.add(_buildPageBtn("1", isActive: _currentPage == 1, onTap: () {
        setState(() => _currentPage = 1);
        _applyFilterAndPagination();
      }));

      if (_currentPage > range + 2) {
        pageButtons.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text("...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        );
      }

      int startPage = _currentPage - range;
      int endPage = _currentPage + range;

      if (startPage <= 1) startPage = 2;
      if (endPage >= _lastPage) endPage = _lastPage - 1;

      for (int i = startPage; i <= endPage; i++) {
        pageButtons.add(_buildPageBtn(i.toString(), isActive: _currentPage == i, onTap: () {
          setState(() => _currentPage = i);
          _applyFilterAndPagination();
        }));
      }

      if (_currentPage < _lastPage - range - 1) {
        pageButtons.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text("...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        );
      }

      pageButtons.add(_buildPageBtn(_lastPage.toString(), isActive: _currentPage == _lastPage, onTap: () {
        setState(() => _currentPage = _lastPage);
        _applyFilterAndPagination();
      }));
    }

    pageButtons.add(_buildPageBtn(">", disabled: _currentPage == _lastPage, onTap: () {
      if (_currentPage < _lastPage) {
        setState(() => _currentPage++);
        _applyFilterAndPagination();
      }
    }));

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: pageButtons);
  }

  Widget _buildPageBtn(String text, {bool isActive = false, bool disabled = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5A45FF) : (disabled ? Colors.grey.shade300 : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Center(
          child: Text(
            text, 
            style: TextStyle(
              color: isActive ? Colors.white : (disabled ? Colors.grey : Colors.black), 
              fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal
            )
          )
        ),
      ),
    );
  }
}