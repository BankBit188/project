import 'package:flutter/material.dart';
import 'package:project/service/plants_service.dart'; // 👈 1. นำเข้า PlantsService เรียบร้อย

class SoilPage extends StatefulWidget {
  const SoilPage({super.key});

  @override
  State<SoilPage> createState() => _SoilPageState();
}

class _SoilPageState extends State<SoilPage> {
  List<dynamic> _allRawItems = []; // 🔹 เก็บข้อมูลพืชทั้งหมดที่ได้จาก API
  List<dynamic> _filteredItems = []; // 🔹 เก็บข้อมูลพืชที่ผ่านการกรองธาตุอาหารและประเภทพืชแล้ว
  List<dynamic> _currentPageItems = []; // 🔹 เก็บข้อมูลที่จะแบ่งมาแสดงในหน้าปัจจุบัน
  
  bool _isLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  final int _itemsPerPage = 3; // กำหนดให้แสดงหน้าละ 3 ชิ้นคงเดิม
  
  // 🔹 ตัวแปรเก็บธาตุอาหารที่เลือกอยู่ (เริ่มต้นเปลี่ยนเป็น "ไนโตรเจน" ให้ตรงกับข้อมูลกลุ่มแรก)
  String _selectedNutrient = "ไนโตรเจน"; 

  // 🔹 เพิ่มตัวแปรสำหรับคัดกรองประเภทพืช (0 = แสดงทั้งหมด, 1 = พืชไร่, 2 = พืชสวน, 3 = พืชเศรษฐกิจ)
  int _selectedPlantType = 0; 

  // 🔹 เพิ่มลิงก์ทางผ่านหลักของ Ngrok สำหรับจัดการ URL รูปภาพพืช
  static const String ngrokUrl = 'https://uselessly-disclose-stingray.ngrok-free.dev';

  @override
  void initState() {
    super.initState();
    _fetchDataFromAPI();
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

  // 🔹 ดึงข้อมูลจากฐานข้อมูลผ่าน PlantsService
  Future<void> _fetchDataFromAPI() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await PlantsService.getplants(); // เรียกข้อมูลพืชทั้งหมด

      final List<dynamic> fetchedData = response is List 
          ? response 
          : (response['data'] ?? []);

      if (mounted) {
        setState(() {
          _allRawItems = fetchedData;
          _applyFilterAndPagination(); // กรองข้อมูลพืชและแบ่งหน้าเพจ
        });
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการดึงข้อมูลพืช: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔹 ฟังก์ชันแปลงชื่อภาษาไทย -> ตัวย่อ Key ในฐานข้อมูล (N, P, K, Ca, Mg, S)
  String _getNutrientKey(String nutrientName) {
    switch (nutrientName) {
      case "ไนโตรเจน": return "N";
      case "ฟอสฟอรัส": return "P";
      case "โพแทสเซียม": return "K";
      case "แคลเซียม": return "Ca";
      case "แมกนีเซียม": return "Mg";
      case "กำมะถัน": return "S";
      default: return "N";
    }
  }

  // 🔹 ฟังก์ชันแปลงตัวเลขรหัสประเภทพืช -> ชื่อภาษาไทยสำหรับแสดงผลที่ UI
  String _getPlantTypeName(int typeCode) {
    switch (typeCode) {
      case 1: return "พืชไร่";
      case 2: return "พืชสวน";
      case 3: return "พืชเศรษฐกิจ";
      default: return "พืชทั้งหมด";
    }
  }

  // 🔹 ฟังก์ชันคัดกรองข้อมูลตามธาตุอาหาร + ประเภทพืช และหั่นชิ้นข้อมูลสลับหน้าเพจ (Pagination)
  void _applyFilterAndPagination() {
    String targetKey = _getNutrientKey(_selectedNutrient);

    // 1. กรองข้อมูลจากฟิลด์ "soil" และ "plantsTypeCode"
    _filteredItems = _allRawItems.where((item) {
      // ตรวจสอบธาตุอาหาร
      String soilValue = item['soil'] ?? '';
      bool matchesNutrient = soilValue.trim().toUpperCase() == targetKey.toUpperCase();

      // ตรวจสอบประเภทพืช (ถ้าเป็น 0 หมายถึงเลือก "ทั้งหมด" ให้ผ่านได้เลย)
      bool matchesType = _selectedPlantType == 0 || 
          (item['plantsTypeCode'] != null && int.tryParse(item['plantsTypeCode'].toString()) == _selectedPlantType);

      return matchesNutrient && matchesType;
    }).toList();

    // 2. คำนวณจำนวนหน้าทั้งหมดใหม่
    _lastPage = (_filteredItems.length / _itemsPerPage).ceil();
    if (_lastPage < 1) _lastPage = 1;

    // 3. ป้องกันบั๊กหน้าปัจจุบันเกินขอบเขตหลังจากเปลี่ยนตัวกรอง
    if (_currentPage > _lastPage) _currentPage = 1;

    // 4. ทำการตัดข้อมูล (Skip/Take) มาเฉพาะชิ้นที่จะนำมาแสดงในหน้านั้นๆ
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

  // 🔹 ฟังก์ชันแสดงหน้าจอ Popup รายละเอียดเชิงลึกของพืชเมื่อคลิกเลือกการ์ด
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
                        const SizedBox(height: 15),
                        
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
    required IconData? iconLeft, required Color colorLeft, required String titleLeft, required String valueLeft,
    required IconData? iconRight, required Color colorRight, required String titleRight, required String valueRight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (iconLeft != null) Icon(iconLeft, color: colorLeft, size: 28) else const SizedBox(width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text("$titleLeft : ", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(valueLeft, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black)),
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
              if (iconRight != null) Icon(iconRight, color: colorRight, size: 28) else const SizedBox(width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text("$titleRight : ", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(valueRight, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black)),
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
                        "แนะนำพืชปลูกตามธาตุอาหาร",
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
                
                // 🔹 แถบเลือกธาตุอาหาร + ปุ่มกรองประเภทพืช (ที่แก้ไขแล้ว)
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip("ไนโตรเจน"),
                            _buildFilterChip("ฟอสฟอรัส"),
                            _buildFilterChip("โพแทสเซียม"),
                            _buildFilterChip("แคลเซียม"),
                            _buildFilterChip("แมกนีเซียม"),
                            _buildFilterChip("กำมะถัน"),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    
                    // 👈 แก้ไขเปลี่ยน Icon เปล่าๆ ให้กลายเป็น PopupMenuButton เพื่อกดกรองประเภทพืชได้
                    PopupMenuButton<int>(
                      initialValue: _selectedPlantType,
                      icon: Icon(
                        _selectedPlantType == 0 ? Icons.filter_alt_outlined : Icons.filter_alt, 
                        size: 28, 
                        color: _selectedPlantType == 0 ? Colors.black : const Color(0xFF5A45FF)
                      ),
                      tooltip: "กรองประเภทพืช",
                      onSelected: (int typeCode) {
                        setState(() {
                          _selectedPlantType = typeCode;
                          _currentPage = 1; // เปลี่ยนตัวกรองแล้วให้กลับไปหน้าแรก
                          _applyFilterAndPagination(); // คัดกรองข้อมูลใหม่ทันที
                        });
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                        const PopupMenuItem<int>(value: 0, child: Text('พืชทั้งหมด')),
                        const PopupMenuItem<int>(value: 1, child: Text('พืชไร่')),
                        const PopupMenuItem<int>(value: 2, child: Text('พืชสวน')),
                        const PopupMenuItem<int>(value: 3, child: Text('พืชเศรษฐกิจ')),
                      ],
                    ),
                  ],
                ),
                
                // แสดงสถานะตัวกรองประเภทพืชปัจจุบันให้ผู้ใช้ทราบ (ถ้าไม่ได้เลือก 'ทั้งหมด')
                if (_selectedPlantType != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "ประเภทพืช: ${_getPlantTypeName(_selectedPlantType)}",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5A45FF)),
                    ),
                  ),
                const SizedBox(height: 15),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _currentPageItems.isEmpty
                          ? const Center(
                              child: Text(
                                "ไม่มีพืชที่ตรงตามเงื่อนไขนี้",
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
    bool isActive = _selectedNutrient == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNutrient = label;
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
          style: TextStyle(
            fontSize: 13, 
            color: Colors.black87, 
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
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
              fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}