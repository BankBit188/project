import 'package:flutter/material.dart';
import 'package:project/service/plants_service.dart';
import 'package:flutter/foundation.dart'; // จำเป็นต้องใช้สำหรับตรวจสอบ kIsWeb

import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  List<dynamic> _allRawItems = []; // เก็บข้อมูลทั้งหมดที่ได้จาก API
  List<dynamic> _currentPageItems =
      []; // เก็บข้อมูลเฉพาะ 3 ชิ้นที่จะแสดงในหน้านั้นๆ
  bool _isLoading = false;

  int _currentPage = 1; // หน้าปัจจุบัน
  int _lastPage = 1; // จำนวนหน้าทั้งหมด
  final int _itemsPerPage = 3; // กำหนดให้แสดงหน้าละ 3 ข้อมูลคงที่

  // 🔹 เปลี่ยนมาใช้ String แทน int? เพื่อแก้บั๊ก PopupMenuButton ไม่ยอมทำงานตอนเป็น null
  // 'all' = แสดงทั้งหมด, '1' = พืชไร่, '2' = พืชสวน, '3' = พืชเศรษฐกิจ
  String _selectedFilter = 'all';

  // 🟩 เพิ่ม Controller และ ตัวแปรสำหรับเก็บคำค้นหา
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // เพิ่มลิงก์ทางผ่านหลักของ Ngrok สำหรับจัดการ URL รูปภาพพืชให้เป็นศูนย์กลาง
  static const String ngrokUrl =
      'https://uselessly-disclose-stingray.ngrok-free.dev';

  @override
  void initState() {
    super.initState();
    _loadDataFromAPI();
  }

  @override
  void dispose() {
    _searchController.dispose(); // 🟩 คืนคืนหน่วยความจำ controller
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

  // ฟังก์ชันดึงข้อมูลจาก API รอบเดียว
  Future<void> _loadDataFromAPI() async {
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

  // 🔹 ฟังก์ชันสำหรับกรองข้อมูลและตัดแบ่งข้อมูล (วนกลับมาแสดงทั้งหมดเมื่อค่าเป็น 'all')
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

      // 🟩 3. กรองตามคำค้นหา (normal_name, scientific_name, other_name)
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        filteredItems = filteredItems.where((item) {
          final normalName = (item['normal_name'] ?? '').toString().toLowerCase();
          final scientificName = (item['scientific_name'] ?? '').toString().toLowerCase();
          final otherName = (item['other_name'] ?? '').toString().toLowerCase();

          return normalName.contains(query) ||
                 scientificName.contains(query) ||
                 otherName.contains(query);
        }).toList();
      }

      // 4. คำนวณจำนวนหน้าใหม่ตามจำนวนข้อมูลที่ผ่านการกรอง
      _lastPage = (filteredItems.length / _itemsPerPage).ceil();
      if (_lastPage < 1) _lastPage = 1;

      // ป้องกันกรณีที่หน้าปัจจุบันเกินจำนวนหน้าทั้งหมด
      if (_currentPage > _lastPage) {
        _currentPage = _lastPage;
      }

      int startIndex = (_currentPage - 1) * _itemsPerPage;

      // 5. ตัดแบ่งข้อมูลมาแสดงแค่ 3 ชิ้นตามหน้าปัจจุบัน
      _currentPageItems = filteredItems
          .skip(startIndex)
          .take(_itemsPerPage)
          .toList();
    });
  }

  // ฟังก์ชันแสดงหน้าจอ Popup รายละเอียดข้อมูลของพืชเมื่อคลิกเลือกการ์ด
  void _showPlantDetailDialog(Map<String, dynamic> item) {
    String normalName = item['normal_name'] ?? 'ไม่มีชื่อพืช';
    String scientificName = item['scientific_name'] ?? 'ไม่มีชื่อวิทยาศาสตร์';
    String otherName = item['other_name'] ?? 'ไม่มีชื่ออื่นๆ';
    String imgUrl = _formatImgUrl(item['img_cloudinary'] ?? item['img'] ?? '');
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

                // 🟩 ปรับแก้ไข TextField สำหรับรับค่าคำค้นหา
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
                        _currentPage = 1; // เมื่อพิมพ์ค้นหาให้เริ่มที่หน้า 1
                        _updateDisplayedItems();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ค้นหา เช่น ชื่อพืช',
                      border: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.black),
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
                                  onTap: () => _showPlantDetailDialog(item),
                                  child: _buildItemCard(
                                    item['normal_name'] ?? 'ไม่มีชื่อพืช',
                                    item['img_cloudinary'] ??
                                        'https://via.placeholder.com/150',
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
    String formattedImgUrl = _formatImgUrl(imgUrl);

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
            child: Image.network(
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