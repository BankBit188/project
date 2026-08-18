import 'package:flutter/material.dart';
import 'package:project/service/plants_service.dart';
import 'package:project/modal/plant_detail.dart';
import 'package:project/style/reccomment/style_earthtype.dart'; // 🟢 Import ไฟล์ส่วนตกแต่ง UI

class EarthTypePage extends StatefulWidget {
  const EarthTypePage({super.key});

  @override
  State<EarthTypePage> createState() => _EarthTypePageState();
}

class _EarthTypePageState extends State<EarthTypePage> {
  List<dynamic> _allRawItems = []; // 🔹 เก็บข้อมูลพืชดิบทั้งหมดจากหลังบ้าน
  List<dynamic> _filteredItems = []; // 🔹 เก็บข้อมูลพืชที่ผ่านการกรองแล้ว
  List<dynamic> _currentPageItems = []; // 🔹 เก็บข้อมูลพืชที่จะแสดงในหน้าปัจจุบัน

  bool _isLoading = false;
  int _currentPage = 1;
  int _lastPage = 1;
  final int _itemsPerPage = 3;
  String _selectedSoilType = "ดินร่วน";
  String _selectedPlantType = "ทั้งหมด";

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
      print("เกิดข้อผิดพลาดในการดึงข้อมูลประเภทดินพืช: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _getSoilTypeCode(String soilName) {
    switch (soilName) {
      case "ดินร่วน":
        return 1;
      case "ดินเหนียว":
        return 2;
      case "ดินทราย":
        return 3;
      default:
        return 1;
    }
  }

  int _getPlantTypeCode(String plantTypeName) {
    switch (plantTypeName) {
      case "พืชไร่":
        return 1;
      case "พืชสวน":
        return 2;
      case "พืชเศรษฐกิจ":
        return 3;
      default:
        return 0;
    }
  }

  void _applyFilterAndPagination() {
    int targetSoilCode = _getSoilTypeCode(_selectedSoilType);

    List<dynamic> tempFiltered = _allRawItems.where((item) {
      var codeValue = item['earthTypeCode'];
      if (codeValue == null) return false;

      int currentCode = codeValue is int
          ? codeValue
          : int.tryParse(codeValue.toString()) ?? 0;
      return currentCode == targetSoilCode;
    }).toList();

    if (_selectedPlantType != "ทั้งหมด") {
      int targetPlantCode = _getPlantTypeCode(_selectedPlantType);

      tempFiltered = tempFiltered.where((item) {
        var typeValue = item['plantsTypeCode'];
        if (typeValue == null) return false;

        int currentPlantCode = typeValue is int
            ? typeValue
            : int.tryParse(typeValue.toString()) ?? 0;
        return currentPlantCode == targetPlantCode;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      tempFiltered = tempFiltered.where((item) {
        String normalName = (item['normal_name'] ?? '').toString().toLowerCase();
        String scientificName = (item['scientific_name'] ?? '').toString().toLowerCase();
        String otherName = (item['other_name'] ?? '').toString().toLowerCase();

        return normalName.contains(_searchQuery) ||
            scientificName.contains(_searchQuery) ||
            otherName.contains(_searchQuery);
      }).toList();
    }

    _filteredItems = tempFiltered;

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
                EarthTypeHeaderWidget(
                  onBackPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 14),

                // 🟢 2. Search Widget
                EarthTypeSearchWidget(
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
                EarthTypeFilterSection(
                  selectedSoilType: _selectedSoilType,
                  selectedPlantType: _selectedPlantType,
                  onSoilTypeSelected: (soil) {
                    setState(() {
                      _selectedSoilType = soil;
                      _currentPage = 1;
                      _applyFilterAndPagination();
                    });
                  },
                  onPlantTypeSelected: (plantType) {
                    setState(() {
                      _selectedPlantType = plantType;
                      _currentPage = 1;
                      _applyFilterAndPagination();
                    });
                  },
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
                                return EarthTypeItemCard(
                                  title: item['normal_name'] ?? 'ไม่มีชื่อพืช',
                                  imgUrl: item['img_cloudinary'] ?? item['img'] ?? '',
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
                EarthTypePaginationWidget(
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