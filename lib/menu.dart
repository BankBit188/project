import 'package:flutter/material.dart';
import 'package:project/navbars.dart'; // นำเข้าไฟล์ navbars.dart ที่เราสร้างไว้
import 'package:project/datawarehouse.dart'; // เผื่อไว้ใช้ตอนเปลี่ยนหน้าไปคลังข้อมูล
import 'package:project/recommentplants.dart'; // เผื่อไว้ใช้ตอนเปลี่ยนหน้าไปแนะนำพืชปลูก

class MenuPage extends StatefulWidget {
  final bool isLoggedIn;
  const MenuPage({super.key, this.isLoggedIn = false});
  

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ใช้ Container สร้างพื้นหลังแบบไล่สี (Gradient)
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDCEAF1), // สีฟ้าอ่อนด้านบน
              Color(0xFFD2E0C4), // สีเขียวอ่อนด้านล่าง
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
                  _buildMembershipSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      // เรียกใช้แถบเมนูด้านล่างที่ Import มาจาก navbars.dart
      bottomNavigationBar: widget.isLoggedIn 
          ? const AuthNavBar(currentIndex: 0) // 0 คือตำแหน่งของหน้าโฮม/เมนูหลัก
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
            color: const Color(0xFF6B9077), // สีเขียวหม่น
            border: Border.all(color: Colors.white54, width: 2),
            // หากคุณมีรูปภาพโลโก้ ให้นำคอมเมนต์ออกและใส่ Path รูปของคุณ
            // image: const DecorationImage(
            //   image: AssetImage("assets/images/logo.png"),
            //   fit: BoxFit.cover,
            // ),
          ),
          child: const Center(
            child: Icon(
              Icons.eco,
              color: Colors.white,
              size: 35,
            ), // ไอคอนชั่วคราว
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
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildSingleCard("พืชปลูก"),
          const SizedBox(width: 15),
          _buildSingleCard("ดิน"),
          const SizedBox(width: 15),
          _buildSingleCard("การปรับสภาพดิน"),
          const SizedBox(width: 15),
          _buildSingleCard("แนะนำพืชปลูกตามประเภทของดิน"),
          const SizedBox(width: 15),
          _buildSingleCard("แนะนำพืชปลูกตามปริมาณธาตุอาหารในดิน"),
        ],
      ),
    );
  }

  Widget _buildSingleCard(String title) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDB4), // สีเหลืองอ่อน
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black87, width: 1.5), // กรอบสีดำ
      ),
      child: Stack(
        children: [
          Positioned(
            top: 15,
            left: 20,
            right: 20, // เพิ่มข้อจำกัดความกว้างให้ Text ไม่ล้น
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 2, // ให้ตัดคำขึ้นบรรทัดใหม่ได้ถ้าชื่อยาว
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ส่วนตกแต่งด้านล่างการ์ด (จำลองกราฟิกรูปดิน)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 45,
              decoration: const BoxDecoration(
                color: Color(0xFF8B5E34), // สีน้ำตาลดิน
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(13),
                  bottomRight: Radius.circular(13),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.energy_savings_leaf,
                    color: Color(0xFF8CC152),
                    size: 20,
                  ),
                  Icon(
                    Icons.energy_savings_leaf,
                    color: Color(0xFF8CC152),
                    size: 28,
                  ),
                  Icon(
                    Icons.energy_savings_leaf,
                    color: Color(0xFF8CC152),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. จุดไข่ปลาบอกตำแหน่งหน้า (Dots Indicator)
  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 5),
        _buildDot(),
        const SizedBox(width: 5),
        _buildDot(),
        const SizedBox(width: 5),
        _buildDot(),
        const SizedBox(width: 5),
        _buildDot(),
      ],
    );
  }

  Widget _buildDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
      ),
    );
  }

  // 4. การ์ดสภาพอากาศ
  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF88C0FA), Color(0xFF5A94ED)], // ไล่สีฟ้า
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // ฝั่งซ้าย (Today)
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
                    const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 16,
                    ),
                    const Text(
                      " 28° / ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                      size: 16,
                    ),
                    const Text(
                      " 13°",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.white, size: 16),
                    const Text(
                      " 87%   ",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Icon(Icons.air, color: Colors.white, size: 16),
                    const Text(
                      " 4 กม/ชม",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ฝั่งขวา (พยากรณ์วันถัดไป)
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
    );
  }

  Widget _buildWeatherDayRow(
    String day,
    String high,
    String low,
    IconData icon,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.white, size: 12),
                  Text(
                    " $high ",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                    size: 12,
                  ),
                  Text(
                    " $low",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
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

  // 5. ส่วนสมาชิกและแบนเนอร์ของขวัญ
  Widget _buildMembershipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                color: const Color(0xFF91CF9D), // สีเขียวมิ้นต์
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
        const SizedBox(height: 15),
        // แบนเนอร์ของขวัญ
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: const Color(
              0xFF5A9031,
            ), // สีพื้นหลังชั่วคราว (ใช้รูปหญ้าแทนได้)
            // หากมีรูปหญ้า นำคอมเมนต์ออกและใส่ Path ตรงนี้
            // image: const DecorationImage(
            //   image: AssetImage("assets/images/grass_bg.png"),
            //   fit: BoxFit.cover,
            // ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.card_giftcard,
                color: Color(0xFFFFD700),
                size: 50,
              ), // ไอคอนกล่องของขวัญสีทอง
              const SizedBox(height: 5),
              Transform.rotate(
                angle: -0.05, // เอียงข้อความเล็กน้อยให้เหมือนในรูป
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
                    ], // เพิ่มเงาให้ตัวหนังสือลอยขึ้นมา
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
