import 'package:flutter/material.dart';
import 'package:project/service/adjust_service.dart'; 
import 'package:flutter/foundation.dart';

class AdjustPage extends StatefulWidget {
  const AdjustPage({super.key});

  @override
  State<AdjustPage> createState() => _AdjustPageState();
}

class _AdjustPageState extends State<AdjustPage> {
  List<dynamic> _allRawItems = []; 
  List<dynamic> _currentPageItems = []; 
  bool _isLoading = false;

  int _currentPage = 1; 
  int _lastPage = 1; 
  final int _itemsPerPage = 3; 

  // 🔹 อย่าลืมเปลี่ยนเป็นลิงก์ Ngrok ใหม่ที่ได้จากจุดที่ 2 ด้านล่างนี้นะครับ
  static const String ngrokUrl = 'https://uselessly-disclose-stingray.ngrok-free.dev';

  @override
  void initState() {
    super.initState();
    _fetchDataFromAPI();
  }

  // ฟังก์ชันสลับหัวไอพีรูปภาพ
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
  } // 👈 จุดนี้ต้องปิดปีกกาให้ถูกต้อง ไม่ให้ฟังก์ชันดักข้อมูลหลุดลงไปด้านล่าง

  // 🔹 ฟังก์ชันเรียกข้อมูลปรับสภาพดิน
  Future<void> _fetchDataFromAPI() async {
    setState(() => _isLoading = true);
    try {
      final response = await AdjustService.getAdjustments();

      final List<dynamic> fetchedData = response is List 
          ? response 
          : (response['data'] ?? []);

      setState(() {
        _allRawItems = fetchedData;
        _lastPage = (_allRawItems.length / _itemsPerPage).ceil();
        if (_lastPage < 1) _lastPage = 1;
        _updateDisplayedItems(); 
      });
    } catch (e) {
      print("เกิดข้อผิดพลาดในการดึงข้อมูลปรับสภาพดิน: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันหั่นชิ้นข้อมูลแสดงตามหน้า
  void _updateDisplayedItems() {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    setState(() {
      _currentPageItems = _allRawItems
          .skip(startIndex)
          .take(_itemsPerPage)
          .toList();
    });
  }

  // 🔹 หน้าจอ Popup รายละเอียดวิธีการปรับสภาพดิน (ดีไซน์เดียวกับรูปหน้าดินร่วนของคุณ)
  void _showAdjustDetailDialog(Map<String, dynamic> item) {
    String title = item['adjustName'] ?? 'ไม่มีชื่อข้อมูลปรับสภาพดิน'; 
    String imgUrl = _formatImgUrl(item['img_url'] ?? item['img'] ?? ''); 
    String detail = item['detail'] ?? 'ไม่มีข้อมูลรายละเอียดเพิ่มเติม'; 

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
                    child: Text(
                      detail,
                      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 28, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text("การปรับสภาพดิน", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
                      hintText: 'ค้นหา เช่น สภาพดิน',
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _currentPageItems.isEmpty
                          ? const Center(
                              child: Text(
                                "ไม่พบข้อมูลวิธีการปรับสภาพดิน",
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _currentPageItems.length,
                              itemBuilder: (context, index) {
                                final item = _currentPageItems[index];
                                return GestureDetector(
                                  onTap: () => _showAdjustDetailDialog(item),
                                  child: _buildItemCard(
                                    item['adjustName'] ?? 'ไม่มีชื่อข้อมูลปรับสภาพดิน', 
                                    item['img_url'] ?? item['img'] ?? 'https://via.placeholder.com/150',
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 110, height: 110,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                );
              },
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
        _updateDisplayedItems(); 
      }
    }));
    
    for (int i = 1; i <= _lastPage; i++) {
      pageButtons.add(_buildPageBtn(i.toString(), isActive: _currentPage == i, onTap: () {
        setState(() => _currentPage = i); 
        _updateDisplayedItems();
      }));
    }
    
    pageButtons.add(_buildPageBtn(">", disabled: _currentPage == _lastPage, onTap: () {
      if (_currentPage < _lastPage) { 
        setState(() => _currentPage++); 
        _updateDisplayedItems(); 
      }
    }));
    
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: pageButtons);
  }

  Widget _buildPageBtn(String text, {bool isActive = false, bool disabled = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 32,
        height: 32,
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
              fontSize: 12,
            )
          )
        ),
      ),
    );
  }
} // 👈 ปิดโครงสร้างคลาสหลักทั้งหมดตรงนี้อย่างปลอดภัย