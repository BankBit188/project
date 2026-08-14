import 'package:flutter/material.dart';
import 'package:project/service/plants_service.dart';
import 'package:project/modal/plant_detail.dart';

class SoilPage extends StatefulWidget {
  const SoilPage({super.key});

  @override
  State<SoilPage> createState() => _SoilPageState();
}

class _SoilPageState extends State<SoilPage> {
  List<dynamic> _allRawItems = []; // 🔹 เก็บข้อมูลพืชทั้งหมดที่ได้จาก API
  List<dynamic> _filteredItems = []; // 🔹 เก็บข้อมูลพืชที่ผ่านการกรองธาตุอาหาร ประเภทพืช และการค้นหาแล้ว
  List<dynamic> _currentPageItems = []; // 🔹 เก็บข้อมูลที่จะแบ่งมาแสดงในหน้าปัจจุบัน
  
  bool _isLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  final int _itemsPerPage = 3; // กำหนดให้แสดงหน้าละ 3 ชิ้นคงเดิม
  
  // 🔹 ตัวแปรเก็บธาตุอาหารที่เลือกอยู่
  String _selectedNutrient = "ไนโตรเจน"; 

  // 🔹 ตัวแปรสำหรับคัดกรองประเภทพืช (0 = แสดงทั้งหมด, 1 = พืชไร่, 2 = พืชสวน, 3 = พืชเศรษฐกิจ)
  int _selectedPlantType = 0; 

  // 🟩 เพิ่มตัวแปรสำหรับเก็บข้อความค้นหา (Search Query)
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchDataFromAPI();
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

  // 🔹 ฟังก์ชันคำนวณและจัดรูปแบบช่วงค่าธาตุอาหาร (Min - Max)
  String _formatVal(dynamic minV, dynamic maxV) {
    if (minV == null && maxV == null) return "-";
    if (minV != null && maxV != null) {
      if (minV.toString() == maxV.toString()) return "$minV";
      return "$minV-$maxV";
    }
    return "${minV ?? maxV}";
  }

  // 🔹 ฟังก์ชันคัดกรองข้อมูลตามธาตุอาหาร + ประเภทพืช + คำค้นหา และหั่นชิ้นข้อมูลแบ่งหน้า (Pagination)
  void _applyFilterAndPagination() {
    String targetKey = _getNutrientKey(_selectedNutrient);

    // 1. กรองข้อมูลจากฟิลด์ "soil", "plantsTypeCode" และข้อความค้นหา
    _filteredItems = _allRawItems.where((item) {
      // ตรวจสอบธาตุอาหาร
      String soilValue = item['soil'] ?? '';
      bool matchesNutrient = soilValue.trim().toUpperCase() == targetKey.toUpperCase();

      // ตรวจสอบประเภทพืช (ถ้าเป็น 0 หมายถึงเลือก "ทั้งหมด" ให้ผ่านได้เลย)
      bool matchesType = _selectedPlantType == 0 || 
          (item['plantsTypeCode'] != null && int.tryParse(item['plantsTypeCode'].toString()) == _selectedPlantType);

      // ตรวจสอบการค้นหาจาก normal_name, scientific_name, หรือ other_name
      String normalName = (item['normal_name'] ?? '').toString().toLowerCase();
      String scientificName = (item['scientific_name'] ?? '').toString().toLowerCase();
      String otherName = (item['other_name'] ?? '').toString().toLowerCase();

      bool matchesSearch = _searchQuery.isEmpty ||
          normalName.contains(_searchQuery) ||
          scientificName.contains(_searchQuery) ||
          otherName.contains(_searchQuery);

      return matchesNutrient && matchesType && matchesSearch;
    }).toList();

    // 2. คำนวณจำนวนหน้าทั้งหมดใหม่
    _lastPage = (_filteredItems.length / _itemsPerPage).ceil();
    if (_lastPage < 1) _lastPage = 1;

    // 3. ป้องกันบั๊กหน้าปัจจุบันเกินขอบเขตหลังจากเปลี่ยนตัวกรองหรือคำค้นหา
    if (_currentPage > _lastPage) _currentPage = 1;

    // 4. ทำการตัดข้อมูล (Skip/Take) มาเฉพาะชิ้นที่จะนำมาแสดงในหน้านั้นๆ
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    _currentPageItems = _filteredItems
        .skip(startIndex)
        .take(_itemsPerPage)
        .toList();
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

                // ช่องค้นหาพืช
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EAE1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase(); // แปลงข้อความค้นหาเป็นพิมพ์เล็ก
                        _currentPage = 1; // รีเซ็ตกลับไปหน้าแรกทันทีเมื่อค้นหา
                        _applyFilterAndPagination(); // ประมวลผลตัวกรองใหม่
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'ค้นหา เช่น ชื่อพืช',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // แถบเลือกธาตุอาหาร + ปุ่มกรองประเภทพืช
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
                                  // 🟢 เรียก Dialog แสดงรายละเอียดพืชจากไฟล์ plant_detail.dart
                                  onTap: () => PlantDetailDialog.show(
                                    context,
                                    Map<String, dynamic>.from(item),
                                  ),
                                  child: _buildItemCard(item),
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

  // 🔹 สลับตำแหน่ง: รูปภาพอยู่ซ้าย / ข้อความชื่อพืช + ค่าธาตุอาหารแบ่งเป็น 3 แถวทางขวา
  Widget _buildItemCard(Map<String, dynamic> item) {
    String title = item['normal_name'] ?? 'ไม่มีชื่อพืช';
    String imgUrl = item['img_cloudinary'] ?? item['img'] ?? '';
    String formattedImgUrl = PlantDetailDialog.formatImgUrl(imgUrl);

    // ดึงค่าธาตุอาหารต่างๆ
    String nVal = _formatVal(item['minN'], item['maxN']);
    String pVal = _formatVal(item['minP'], item['maxP']);
    String kVal = _formatVal(item['minK'], item['maxK']);
    String caVal = _formatVal(item['minCa'], item['maxCa']);
    String mgVal = _formatVal(item['minMg'], item['maxMg']);
    String sVal = _formatVal(item['minS'], item['maxS']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDB4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Row(
        children: [
          // 🖼️ รูปภาพอยู่ฝั่งซ้าย
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: formattedImgUrl.isNotEmpty
                ? Image.network(
                    formattedImgUrl, 
                    width: 110, height: 110, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 110, height: 110, color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 110, height: 110, color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 15),
          
          // 📝 ข้อความอยู่ฝั่งขวา (ชื่อพืช + ค่าธาตุอาหาร 3 แถว)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 🔹 แถวที่ 1: N, P
                Text(
                  "N: $nVal  |  P: $pVal",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // 🔹 แถวที่ 2: K, Ca
                Text(
                  "K: $kVal  |  Ca: $caVal",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // 🔹 แถวที่ 3: Mg, S
                Text(
                  "Mg: $mgVal  |  S: $sVal",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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