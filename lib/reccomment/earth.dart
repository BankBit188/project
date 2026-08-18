import 'package:flutter/material.dart';
import 'package:project/service/earth_service.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:project/style/reccomment/style_earth.dart'; // 🟢 Import ไฟล์ส่วนตกแต่ง UI

class EarthPage extends StatefulWidget {
  const EarthPage({super.key});

  @override
  State<EarthPage> createState() => _EarthPageState();
}

class _EarthPageState extends State<EarthPage> {
  List<dynamic> _allRawItems = []; // 🔹 เก็บข้อมูลดินทั้งหมดจาก API
  List<dynamic> _filteredItems = []; // 🟩 เก็บข้อมูลดินหลังกรองค้นหา
  List<dynamic> _currentPageItems = []; // 🔹 เก็บข้อมูลแสดงหน้าปัจจุบัน
  bool _isLoading = false;

  int _currentPage = 1; // หน้าปัจจุบัน
  int _lastPage = 1; // จำนวนหน้าทั้งหมด
  final int _itemsPerPage = 3; // แสดงหน้าละ 3 ข้อมูล

  // 🟩 Controller & ตัวแปรคำค้นหา
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  static const String ngrokUrl = 'https://uselessly-disclose-stingray.ngrok-free.dev';

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

  Future<void> _fetchDataFromAPI() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await EarthService.getEarthTypes();

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
      print("เกิดข้อผิดพลาดในการดึงข้อมูลดิน: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilterAndPagination() {
    List<dynamic> tempFiltered = _allRawItems;

    if (_searchQuery.isNotEmpty) {
      tempFiltered = tempFiltered.where((item) {
        String earthTypeName = (item['earthTypeName'] ?? '').toString().toLowerCase();
        return earthTypeName.contains(_searchQuery);
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

  void _showEarthDetailDialog(Map<String, dynamic> item) {
    String title = item['earthTypeName'] ?? 'ไม่มีชื่อประเภทดิน';
    String imgUrl = _formatImgUrl(item['img_cloudinary'] ?? item['img'] ?? '');
    String detail = item['detail'] ?? 'ไม่มีข้อมูลรายละเอียดของดินประเภทนี้';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          backgroundColor: const Color(0xFFEFE8CE),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 650),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
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
                      imgUrl,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 220, height: 220,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: HtmlWidget(
                      detail,
                      textStyle: const TextStyle(
                        fontSize: 16, 
                        color: Colors.black87, 
                        height: 1.4,
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
                  ),
                ),
              ],
            ),
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
                EarthHeaderWidget(
                  onBackPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 16),

                // 🟢 2. Search Widget
                EarthSearchWidget(
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

                const SizedBox(height: 16),

                // 🟢 3. List Item Widget
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
                                    "ไม่พบข้อมูลประเภทดิน",
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
                                return EarthItemCard(
                                  title: item['earthTypeName'] ?? 'ไม่มีชื่อประเภทดิน',
                                  formattedImgUrl: _formatImgUrl(
                                    item['img_cloudinary'] ??
                                        item['img'] ??
                                        'https://via.placeholder.com/150',
                                  ),
                                  onTap: () => _showEarthDetailDialog(item),
                                );
                              },
                            ),
                ),

                const SizedBox(height: 8),

                // 🟢 4. Pagination Widget
                EarthPaginationWidget(
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