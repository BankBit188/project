import 'package:flutter/material.dart';
import 'package:project/service/plants_service.dart';
import 'package:project/modal/plant_detail.dart';
import 'package:project/style/reccomment/style_soil.dart'; // 🟢 Import ไฟล์ส่วนตกแต่ง UI

class SoilPage extends StatefulWidget {
  const SoilPage({super.key});

  @override
  State<SoilPage> createState() => _SoilPageState();
}

class _SoilPageState extends State<SoilPage> {
  List<dynamic> _allRawItems = []; // 🔹 เก็บข้อมูลพืชทั้งหมดที่ได้จาก API
  List<dynamic> _filteredItems = []; // 🔹 เก็บข้อมูลพืชที่ผ่านการกรองแล้ว
  List<dynamic> _currentPageItems = []; // 🔹 เก็บข้อมูลที่จะแบ่งมาแสดงในหน้าปัจจุบัน

  bool _isLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  final int _itemsPerPage = 3;

  String _selectedNutrient = "ไนโตรเจน";
  int _selectedPlantType = 0;

  // 🟩 Controller & ตัวแปรสำหรับเก็บข้อความค้นหา
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchDataFromAPI();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataFromAPI() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await PlantsService.getplants();

      final List<dynamic> fetchedData = response is List
          ? response
          : (response['data'] ?? []);

      if (mounted) {
        setState(() {
          _allRawItems = fetchedData;
          _applyFilterAndPagination();
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

  String _getNutrientKey(String nutrientName) {
    switch (nutrientName) {
      case "ไนโตรเจน":
        return "N";
      case "ฟอสฟอรัส":
        return "P";
      case "โพแทสเซียม":
        return "K";
      case "แคลเซียม":
        return "Ca";
      case "แมกนีเซียม":
        return "Mg";
      case "กำมะถัน":
        return "S";
      default:
        return "N";
    }
  }

  String _getPlantTypeName(int typeCode) {
    switch (typeCode) {
      case 1:
        return "พืชไร่";
      case 2:
        return "พืชสวน";
      case 3:
        return "พืชเศรษฐกิจ";
      default:
        return "พืชทั้งหมด";
    }
  }

  void _applyFilterAndPagination() {
    String targetKey = _getNutrientKey(_selectedNutrient);

    _filteredItems = _allRawItems.where((item) {
      String soilValue = item['soil'] ?? '';
      bool matchesNutrient = soilValue.trim().toUpperCase() == targetKey.toUpperCase();

      bool matchesType = _selectedPlantType == 0 ||
          (item['plantsTypeCode'] != null &&
              int.tryParse(item['plantsTypeCode'].toString()) == _selectedPlantType);

      String normalName = (item['normal_name'] ?? '').toString().toLowerCase();
      String scientificName = (item['scientific_name'] ?? '').toString().toLowerCase();
      String otherName = (item['other_name'] ?? '').toString().toLowerCase();

      bool matchesSearch = _searchQuery.isEmpty ||
          normalName.contains(_searchQuery) ||
          scientificName.contains(_searchQuery) ||
          otherName.contains(_searchQuery);

      return matchesNutrient && matchesType && matchesSearch;
    }).toList();

    _lastPage = (_filteredItems.length / _itemsPerPage).ceil();
    if (_lastPage < 1) _lastPage = 1;

    if (_currentPage > _lastPage) _currentPage = 1;

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

                // 🟢 1. Header Widget
                SoilHeaderWidget(
                  onBackPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 14),

                // 🟢 2. Search Widget
                SoilSearchWidget(
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                      _currentPage = 1;
                      _applyFilterAndPagination();
                    });
                  },
                  onClearSearch: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                      _currentPage = 1;
                      _applyFilterAndPagination();
                    });
                  },
                ),

                const SizedBox(height: 12),

                // 🟢 3. Filter Section Widget
                SoilFilterSection(
                  selectedNutrient: _selectedNutrient,
                  selectedPlantType: _selectedPlantType,
                  onNutrientSelected: (nutrient) {
                    setState(() {
                      _selectedNutrient = nutrient;
                      _currentPage = 1;
                      _applyFilterAndPagination();
                    });
                  },
                  onPlantTypeSelected: (typeCode) {
                    setState(() {
                      _selectedPlantType = typeCode;
                      _currentPage = 1;
                      _applyFilterAndPagination();
                    });
                  },
                ),

                if (_selectedPlantType != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "ประเภทพืช: ${_getPlantTypeName(_selectedPlantType)}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A7C59),
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // 🟢 4. List Item Widget
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4A7C59),
                          ),
                        )
                      : _currentPageItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 50,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "ไม่มีพืชที่ตรงตามเงื่อนไขนี้",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _currentPageItems.length,
                              itemBuilder: (context, index) {
                                final item = _currentPageItems[index];
                                return SoilItemCard(
                                  item: Map<String, dynamic>.from(item),
                                  onTap: () => PlantDetailDialog.show(
                                    context,
                                    Map<String, dynamic>.from(item),
                                  ),
                                );
                              },
                            ),
                ),

                const SizedBox(height: 8),

                // 🟢 5. Pagination Widget
                SoilPaginationWidget(
                  currentPage: _currentPage,
                  lastPage: _lastPage,
                  onPageChanged: (newPage) {
                    setState(() {
                      _currentPage = newPage;
                      _applyFilterAndPagination();
                    });
                  },
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}