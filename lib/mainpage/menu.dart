import 'package:flutter/material.dart';
import 'package:project/navbar/navbars.dart'; 
import 'package:project/mainpage/datawarehouse.dart'; 
import 'package:project/mainpage/recommentplants.dart'; 

// ไฟล์ปลายทางที่ต้องการให้เปลี่ยนหน้าไป
import 'package:project/reccomment/adjust.dart';
import 'package:project/reccomment/earth.dart';
import 'package:project/reccomment/earthtype.dart';
import 'package:project/reccomment/plants.dart';
import 'package:project/reccomment/soil.dart';

import 'package:project/mainpage/weather.dart';

class MenuPage extends StatefulWidget {
  final bool isLoggedIn;
  const MenuPage({super.key, this.isLoggedIn = false});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;
  
  // 🛠️ เพิ่ม ScrollController และตัวแปรเก็บตำแหน่ง Dot ปัจจุบัน
  final ScrollController _cardScrollController = ScrollController();
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    // 🛠️ ตรวจจับการเลื่อนของการ์ดเพื่อเปลี่ยนจุด Dot ด้านล่างตามจริง
    _cardScrollController.addListener(() {
      // คำนวณจากความกว้างของการ์ด (280) + ระยะห่าง (15) = 295
      double itemWidth = 280.0 + 15.0;
      int newIndex = (_cardScrollController.offset / itemWidth).round();
      
      // ควบคุมไม่ให้อินเด็กซ์หลุดขอบ (มีทั้งหมด 5 การ์ด คือ index 0 ถึง 4)
      if (newIndex < 0) newIndex = 0;
      if (newIndex > 4) newIndex = 4;

      if (newIndex != _currentCardIndex) {
        setState(() {
          _currentCardIndex = newIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    // 🛠️ คืนหน่วยความจำคืนเมื่อไม่ได้ใช้งานหน้าเพจนี้แล้ว
    _cardScrollController.dispose();
    super.dispose();
  }

  // 💡 ฟังก์ชันเปิด Dialog แสดงสิทธิของสมาชิก (ถอดแบบโครงสร้างและสไตล์จากรูปภาพ)
  void _showMembershipRightsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF4EFC9), // สีพื้นหลังเหลืองครีมตามรูปภาพ
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0), // มุมโค้งมนเด่นชัด
            side: const BorderSide(color: Colors.black87, width: 1.2), // ขอบเส้นบางรอบกล่อง
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min, // ให้กล่องขยายตามความยาวข้อความจริง
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ❌ แถวบนสุด: ปุ่มปิดกากบาทชิดขวา
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.black, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // 🏷️ หัวข้อเรื่อง
                const Text(
                  "สิทธิของสมาชิก",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                // 📝 รายละเอียดข้อที่ 1
                _buildRightItem(
                  "1. ",
                  "สามารถใช้ฟังก์ชันแนะนำพืชที่เหมาะสมได้ โดยไม่ต้องกรอกค่าลงไป โดยจะนำค่าจากอุปกรณ์ไปประมวลผลและแนะนำให้",
                ),
                const SizedBox(height: 10),
                // 📝 รายละเอียดข้อที่ 2
                _buildRightItem(
                  "2. ",
                  "สามารถบันทึกข้อมูลค่าในดินแต่ละพื้นที่ได้",
                ),
                const SizedBox(height: 10),
                // 📝 รายละเอียดข้อที่ 3
                _buildRightItem(
                  "3. ",
                  "สามารถใช้แชตบอทได้",
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

  // คอมโพเนนต์จัดระเบียบตัวเลขและข้อความอธิบายให้เยื้องสวยงาม
  Widget _buildRightItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16, 
              color: Colors.black87, 
              height: 1.3,
            ),
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
            colors: [
              Color(0xFFDCEAF1), 
              Color(0xFFD2E0C4), 
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 25),
                  _buildHorizontalCards(),
                  const SizedBox(height: 15),
                  _buildDotsIndicator(), 
                  const SizedBox(height: 25),
                  const Text(
                    "สภาพอากาศ",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildWeatherCard(),
                  const SizedBox(height: 25),
                  _buildMembershipSection(), // เรียกใช้ส่วนแสดงผลด้านล่าง
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.isLoggedIn 
          ? const AuthNavBar(currentIndex: 0) 
          : const GuestNavBar(currentIndex: 0),
    );
  }

  // 1. ส่วนหัว (โลโก้ + ข้อความ)
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6B9077), 
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: const Center(
            child: Icon(
              Icons.eco,
              color: Colors.white,
              size: 35,
            ), 
          ),
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Text(
            "อุปกรณ์วัดคุณภาพของดินและ\nแนะนำพืชที่เหมาะสม",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // 2. ส่วนการ์ดเลื่อนแนวนอน
  Widget _buildHorizontalCards() {
    return SizedBox(
      height: 140,
      child: ListView(
        controller: _cardScrollController, 
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildSingleCard("พืชปลูก", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PlantsPage()));
          }),
          const SizedBox(width: 15),
          _buildSingleCard("ดิน", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EarthPage()));
          }),
          const SizedBox(width: 15),
          _buildSingleCard("การปรับสภาพดิน", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdjustPage()));
          }),
          const SizedBox(width: 15),
          _buildSingleCard("แนะนำพืชปลูกตามประเภทของดิน", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const EarthTypePage()));
          }),
          const SizedBox(width: 15),
          _buildSingleCard("แนะนำพืชปลูกตามปริมาณธาตุอาหารในดิน", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SoilPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildSingleCard(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDB4), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black87, width: 1.5), 
        ),
        child: Stack(
          children: [
            Positioned(
              top: 15,
              left: 20,
              right: 20, 
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2, 
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5E34), 
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(13),
                    bottomRight: Radius.circular(13),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.energy_savings_leaf, color: Color(0xFF8CC152), size: 20),
                    Icon(Icons.energy_savings_leaf, color: Color(0xFF8CC152), size: 28),
                    Icon(Icons.energy_savings_leaf, color: Color(0xFF8CC152), size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. ส่วนจุดไข่ปลาบอกตำแหน่งหน้า
  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        bool isActive = index == _currentCardIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250), 
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: isActive ? 24 : 6, 
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  // 4. การ์ดสภาพอากาศ
  Widget _buildWeatherCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeatherPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF88C0FA), Color(0xFF5A94ED)], 
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "24°",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                      const Text(" 28° / ", style: TextStyle(color: Colors.white, fontSize: 16)),
                      const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                      const Text(" 13°", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.white, size: 16),
                      const Text(" 87%   ", style: TextStyle(color: Colors.white, fontSize: 14)),
                      const Icon(Icons.air, color: Colors.white, size: 16),
                      const Text(" 4 กม/ชม", style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildWeatherDayRow("อ.", "28°", "13°", Icons.cloud),
                  _buildWeatherDayRow("พ.", "28°", "13°", Icons.cloud),
                  _buildWeatherDayRow("พฤ", "28°", "13°", Icons.cloud),
                  _buildWeatherDayRow("ศ.", "28°", "13°", Icons.cloud),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDayRow(String day, String high, String low, IconData icon) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(day, style: const TextStyle(color: Colors.white, fontSize: 16)),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.white, size: 12),
                  Text(" $high ", style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const Icon(Icons.arrow_downward, color: Colors.white, size: 12),
                  Text(" $low", style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
              Icon(icon, color: Colors.white54, size: 20),
            ],
          ),
        ),
        const Divider(color: Colors.white30, height: 1, thickness: 1),
      ],
    );
  }

  // 5. ส่วนสมาชิกและแบนเนอร์ของขวัญ (ปรับปรุงให้กดแสดงหน้าต่าง Pop-up ได้ทั้งหมด)
  Widget _buildMembershipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🛠️ ห่อหุ้มแถวหัวข้อสมาชิกด้วย GestureDetector เพื่อรองรับการคลิก
        GestureDetector(
          onTap: _showMembershipRightsDialog, // เมื่อคลิกจะเรียกฟังก์ชันเปิดหน้าต่างสิทธิ
          behavior: HitTestBehavior.opaque, // ช่วยให้กดติดง่ายขึ้นแม้จะกดโดนช่องว่างระหว่างข้อความ
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "จำนวนผู้ที่เป็นสมาชิก",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF91CF9D), 
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "32",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        // 🛠️ ส่วนของแบนเนอร์สิทธิของสมาชิกด้านล่าง ก็รองรับการคลิกเปิดป๊อปอัปเช่นกันเพื่อ UX ที่ดี
        GestureDetector(
          onTap: _showMembershipRightsDialog,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFF5A9031), 
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 50), 
                const SizedBox(height: 5),
                Transform.rotate(
                  angle: -0.05, 
                  child: const Text(
                    "สิทธิของสมาชิก",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ], 
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}