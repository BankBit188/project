import 'package:flutter/material.dart';
import 'package:project/service/plants_service.dart';
import 'package:project/modal/plant_detail.dart'; // 🟢 Import ไฟล์รายละเอียดพืชมาใช้งาน

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

  // ฟังก์ชันดึงข้อมูลจาก API รอบเดียว
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

  // ฟังก์ชันสำหรับกรองข้อมูลและตัดแบ่งข้อมูล
  void _updateDisplayedItems() {
    setState(() {
      // 1. กำหนดให้ข้อมูลตั้งต้นเป็นข้อมูลทั้งหมดจาก API เสมอ
      List<dynamic> filteredItems = _allRawItems;

      // 2. กรองตามประเภทพืช (ถ้าไม่ใช่ 'all')
      if (_selectedFilter != 'all') {
        filteredItems = filteredItems.where((item) {
          final typeCode = item['plantsTypeCode'].toString();
          return typeCode == _selectedFilter;
        }).toList();
      }

      // 3. กรองตามคำค้นหา (normal_name, scientific_name, other_name)
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

      // 4. คำนวณจำนวนหน้าใหม่ตามจำนวนข้อมูลที่ผ่านการกรอง
      _lastPage = (filteredItems.length / _itemsPerPage).ceil();
      if (_lastPage < 1) _lastPage = 1;

      if (_currentPage > _lastPage) {
        _currentPage = _lastPage;
      }

      int startIndex = (_currentPage - 1) * _itemsPerPage;

      // 5. ตัดแบ่งข้อมูลมาแสดงแค่ 3 ชิ้นตามหน้าปัจจุบัน
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 28,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "พืชปลูก",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // ช่องค้นหา
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EAE1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 1;
                        _updateDisplayedItems();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ค้นหา เช่น ชื่อพืช',
                      border: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon:
                                  const Icon(Icons.clear, color: Colors.black),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _currentPage = 1;
                                  _updateDisplayedItems();
                                });
                              },
                            )
                          : const Icon(Icons.search, color: Colors.black),
                    ),
                  ),
                ),

                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      _selectedFilter == 'all'
                          ? Icons.filter_alt_outlined
                          : Icons.filter_alt,
                      size: 28,
                      color: _selectedFilter == 'all'
                          ? Colors.black
                          : const Color(0xFF5A45FF),
                    ),
                    tooltip: 'กรองประเภทพืช',
                    onSelected: (String value) {
                      setState(() {
                        _selectedFilter = value;
                        _currentPage = 1;
                        _updateDisplayedItems();
                      });
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'all',
                        child: Text('พืชทั้งหมด'),
                      ),
                      const PopupMenuItem<String>(
                        value: '1',
                        child: Text('พืชไร่'),
                      ),
                      const PopupMenuItem<String>(
                        value: '2',
                        child: Text('พืชสวน'),
                      ),
                      const PopupMenuItem<String>(
                        value: '3',
                        child: Text('พืชเศรษฐกิจ'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _currentPageItems.isEmpty
                          ? const Center(
                              child: Text(
                                "ไม่พบข้อมูล",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey),
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
                                  child: _buildItemCard(
                                    item['normal_name'] ?? 'ไม่มีชื่อพืช',
                                    item['img_cloudinary'] ??
                                        item['img'] ??
                                        '',
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

  Widget _buildItemCard(String title, String imgUrl) {
    // 🟢 เรียกใช้ Helper ฟอร์แมต URL รูปจาก PlantDetailDialog
    String formattedImgUrl = PlantDetailDialog.formatImgUrl(imgUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
                    height: 110,
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                    cacheHeight: 300,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    width: 110,
                    height: 110,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicPagination() {
    if (_lastPage <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    pageButtons.add(
      _buildPageBtn(
        "<",
        disabled: _currentPage == 1,
        onTap: () {
          if (_currentPage > 1) {
            _currentPage--;
            _updateDisplayedItems();
          }
        },
      ),
    );

    bool showLeftDots = false;
    bool showRightDots = false;

    for (int i = 1; i <= _lastPage; i++) {
      if (i == 1 || i == _lastPage || (i - _currentPage).abs() <= 1) {
        pageButtons.add(
          _buildPageBtn(
            i.toString(),
            isActive: _currentPage == i,
            onTap: () {
              if (_currentPage != i) {
                _currentPage = i;
                _updateDisplayedItems();
              }
            },
          ),
        );
      } else if (i < _currentPage && !showLeftDots) {
        showLeftDots = true;
        pageButtons.add(_buildDotsBtn());
      } else if (i > _currentPage && !showRightDots) {
        showRightDots = true;
        pageButtons.add(_buildDotsBtn());
      }
    }

    pageButtons.add(
      _buildPageBtn(
        ">",
        disabled: _currentPage == _lastPage,
        onTap: () {
          if (_currentPage < _lastPage) {
            _currentPage++;
            _updateDisplayedItems();
          }
        },
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pageButtons,
    );
  }

  Widget _buildDotsBtn() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 32,
      height: 32,
      child: const Center(
        child: Text(
          "...",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPageBtn(
    String text, {
    bool isActive = false,
    bool disabled = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF5A45FF)
              : (disabled ? Colors.grey.shade300 : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : (disabled ? Colors.grey : Colors.black),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}