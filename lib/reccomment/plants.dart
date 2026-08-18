import 'package:flutter/material.dart';
import 'package:project/service/plants_service.dart';
import 'package:project/modal/plant_detail.dart';
import 'package:project/style/reccomment/style_plants.dart'; // 🟢 Import ไฟล์สไตล์แยกมาใช้งาน

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  List<dynamic> _allRawItems = []; // เก็บข้อมูลทั้งหมดที่ได้จาก API
  List<dynamic> _currentPageItems = []; // เก็บข้อมูลเฉพาะ 3 ชิ้นที่จะแสดงในหน้านั้นๆ
  bool _isLoading = false;

  int _currentPage = 1; // หน้าปัจจุบัน
  int _lastPage = 1; // จำนวนหน้าทั้งหมด
  final int _itemsPerPage = 3; // กำหนดให้แสดงหน้าละ 3 ข้อมูลคงที่

  // 'all' = แสดงทั้งหมด, '1' = พืชไร่, '2' = พืชสวน, '3' = พืชเศรษฐกิจ
  String _selectedFilter = 'all';

  // Controller และ ตัวแปรสำหรับเก็บคำค้นหา
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDataFromAPI();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ฟังก์ชันดึงข้อมูลจาก API
  Future<void> _loadDataFromAPI() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await PlantsService.getplants();

      final List<dynamic> fetchedData =
          response is List ? response : (response['data'] ?? []);

      if (mounted) {
        setState(() {
          _allRawItems = fetchedData;
          _updateDisplayedItems();
        });
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการดึงข้อมูล: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ฟังก์ชันกรองและแบ่งหน้าข้อมูล
  void _updateDisplayedItems() {
    setState(() {
      List<dynamic> filteredItems = _allRawItems;

      // 1. กรองประเภทพืช
      if (_selectedFilter != 'all') {
        filteredItems = filteredItems.where((item) {
          final typeCode = item['plantsTypeCode'].toString();
          return typeCode == _selectedFilter;
        }).toList();
      }

      // 2. กรองตามคำค้นหา
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        filteredItems = filteredItems.where((item) {
          final normalName =
              (item['normal_name'] ?? '').toString().toLowerCase();
          final scientificName =
              (item['scientific_name'] ?? '').toString().toLowerCase();
          final otherName =
              (item['other_name'] ?? '').toString().toLowerCase();

          return normalName.contains(query) ||
              scientificName.contains(query) ||
              otherName.contains(query);
        }).toList();
      }

      // 3. คำนวณการแบ่งหน้า
      _lastPage = (filteredItems.length / _itemsPerPage).ceil();
      if (_lastPage < 1) _lastPage = 1;

      if (_currentPage > _lastPage) {
        _currentPage = _lastPage;
      }

      int startIndex = (_currentPage - 1) * _itemsPerPage;
      _currentPageItems =
          filteredItems.skip(startIndex).take(_itemsPerPage).toList();
    });
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

                // 🟢 1. ส่วนหัว (Header)
                PlantHeaderWidget(
                  onBackPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 16),

                // 🟢 2. ช่องค้นหา + ปุ่มฟิลเตอร์
                PlantSearchFilterWidget(
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  selectedFilter: _selectedFilter,
                  onSearchChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                      _updateDisplayedItems();
                    });
                  },
                  onClearSearch: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                      _updateDisplayedItems();
                    });
                  },
                  onFilterSelected: (String value) {
                    setState(() {
                      _selectedFilter = value;
                      _currentPage = 1;
                      _updateDisplayedItems();
                    });
                  },
                ),

                const SizedBox(height: 16),

                // 🟢 3. รายการพืช
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
                                    "ไม่พบข้อมูลพืชที่ค้นหา",
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
                                return PlantItemCard(
                                  title: item['normal_name'] ?? 'ไม่มีชื่อพืช',
                                  otherName: item['other_name']?.toString(),
                                  imgUrl: item['img_cloudinary'] ??
                                      item['img'] ??
                                      '',
                                  onTap: () => PlantDetailDialog.show(
                                    context,
                                    Map<String, dynamic>.from(item),
                                  ),
                                );
                              },
                            ),
                ),

                const SizedBox(height: 8),

                // 🟢 4. แถบปุ่มแบ่งหน้า (Pagination)
                PlantPaginationWidget(
                  currentPage: _currentPage,
                  lastPage: _lastPage,
                  onPageChanged: (newPage) {
                    setState(() {
                      _currentPage = newPage;
                      _updateDisplayedItems();
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