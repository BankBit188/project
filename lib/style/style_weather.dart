import 'package:flutter/material.dart';

// 🎨 พื้นหลังธีมสภาพอากาศ Glassmorphic Sky (ไล่ระดับสีฟ้าเข้มสดใส คลีน โมเดิร์น)
const BoxDecoration kWeatherBackgroundDecoration = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E3C72), // ฟ้าเข้มมิติสูง
      Color(0xFF2A5298), // ฟ้าสดใส
      Color(0xFF3890D8), // ฟ้าสว่าง
    ],
  ),
);

// 🎨 การ์ดครอบสไตล์ Glassmorphic ทรานส์ลูเซนต์
Widget buildGlassCard({
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  EdgeInsetsGeometry? margin,
  double borderRadius = 20,
}) {
  return Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

// 🎨 การ์ดรายละเอียดสภาพอากาศ (ความชื้น, ลม)
Widget buildWeatherDetailCard({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    height: 110,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

// 🎨 ปุ่มแนะนำพืชสไตล์โมเดิร์น คอนทราสต์สูง อ่านง่าย
Widget buildPrimaryActionButton({
  required VoidCallback? onPressed,
  required bool isLoading,
  required String defaultText,
  required String loadingText,
  required IconData icon,
  double height = 52,
}) {
  return SizedBox(
    width: double.infinity,
    height: height,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Color(0xFF2E5A36),
                strokeWidth: 2.2,
              ),
            )
          : Icon(icon, color: const Color(0xFF2E5A36), size: 24),
      label: Text(
        isLoading ? loadingText : defaultText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E5A36),
          letterSpacing: 0.2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

// 🎨 การ์ดพยากรณ์อากาศรายชั่วโมงพร้อมสถานะ Highlight
// 🎨 การ์ดพยากรณ์อากาศรายชั่วโมงพร้อมสถานะ Highlight
Widget buildHourlyForecastCard({
  required String tempText,
  required Widget
  iconWidget, // 👈 เปลี่ยนจาก IconData icon เป็น Widget iconWidget
  required String timeText,
  required bool isCurrent,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: 72,
    margin: const EdgeInsets.only(right: 10),
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: isCurrent
          ? Colors.white.withOpacity(0.32)
          : Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isCurrent
            ? Colors.white.withOpacity(0.8)
            : Colors.white.withOpacity(0.2),
        width: isCurrent ? 1.8 : 1.0,
      ),
      boxShadow: isCurrent
          ? [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ]
          : null,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          tempText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.bold,
          ),
        ),
        iconWidget, // 👈 แสดงผลไอคอนมีลูกเล่นตรงนี้
        Text(
          timeText,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

// 🎨 รูปแบบ Dialog เลือกเดือนและปี
final ShapeBorder kWeatherDialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(24),
);
