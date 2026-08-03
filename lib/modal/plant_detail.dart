import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

class PlantDetailDialog {
  /// 🟢 Dialog แสดงรายละเอียดพืช
  static void show(BuildContext context, Map<String, dynamic> item) {
    String normalName = item['normal_name'] ?? 'ไม่มีชื่อพืช';
    String scientificName = item['scientific_name'] ?? 'ไม่มีชื่อวิทยาศาสตร์';
    String otherName = item['other_name'] ?? 'ไม่มีชื่ออื่นๆ';
    String imgUrl = formatImgUrl(item['img_cloudinary'] ?? item['img'] ?? '');
    String detaill = item['detaill'] ?? 'ไม่มีข้อมูลรายละเอียดพืช';
    String nature = item['nature'] ?? 'ไม่มีข้อมูลลักษณะทั่วไป';
    String plant = item['plant'] ?? 'ไม่มีข้อมูลการปลูก';
    String care = item['care'] ?? 'ไม่มีข้อมูลการดูแล';
    String harvest = item['harvest'] ?? 'ไม่มีข้อมูลการเก็บเกี่ยว';
    String? supplyLink = item['supplyLink'] ?? item['link'];
    String? demandLink = item['demandLink'] ?? item['link'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                            color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 28, color: Colors.black),
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
                        child: const Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey),
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
                        Text("ชื่อสามัญ : $normalName",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        Text("ชื่อวิทยาศาสตร์ : $scientificName",
                            style: const TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                color: Colors.black)),
                        Text("ชื่ออื่นๆ : $otherName",
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black)),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 5),

                        HtmlWidget(detaill,
                            textStyle: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("ลักษณะทั่วไป",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        HtmlWidget(nature,
                            textStyle: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("ข้อมูลการปลูก",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        HtmlWidget(plant,
                            textStyle: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("การดูแลรักษา",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        HtmlWidget(care,
                            textStyle: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.black)),
                        const SizedBox(height: 12),
                        const Text("การเก็บเกี่ยว",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        HtmlWidget(harvest,
                            textStyle: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.black)),

                        const Divider(color: Colors.black26, height: 25),
                        const Center(
                          child: Text("สภาพดินและธาตุอาหารในดินที่เหมาะสม",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ),
                        const SizedBox(height: 15),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              _buildNutrientText("N (ไนโตรเจน)",
                                  _formatRange(item['minN'], item['maxN'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("P (ฟอสฟอรัส)",
                                  _formatRange(item['minP'], item['maxP'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("K (โพแทสเซียม)",
                                  _formatRange(item['minK'], item['maxK'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("Ca (แคลเซียม)",
                                  _formatRange(item['minCa'], item['maxCa'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("Mg (แมกนีเซียม)",
                                  _formatRange(item['minMg'], item['maxMg'])),
                              const SizedBox(height: 8),
                              _buildNutrientText("S (กำมะถัน)",
                                  _formatRange(item['minS'], item['maxS'])),
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
                                valueRight:
                                    _formatRange(item['minPH'], item['maxPH']),
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

                        // 🟢 ส่วน Supply และ Demand
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
                              const SizedBox(height: 16),

                              const Text(
                                "ปริมาณการผลิต",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: 'คลิกเพื่อดูรายละเอียด',
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: 'เพิ่มเติม',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () =>
                                            _openUrl(context, supplyLink),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                "ความต้องการ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: 'คลิกเพื่อดูรายละเอียด',
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: 'เพิ่มเติม',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () =>
                                            _openUrl(context, demandLink),
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

  // 🛠️ Helper จัดการ URL ภาพ (ลบ ngrok ออกแล้ว)
  static String formatImgUrl(String imgUrl) {
    return imgUrl.replaceAll(r'\/', '/');
  }

  static String _formatRange(dynamic minVal, dynamic maxVal) {
    if (minVal == null && maxVal == null) return '-';
    if (minVal != null && maxVal == null) return '$minVal';
    if (minVal == null && maxVal != null) return '$maxVal';
    if (minVal.toString() == maxVal.toString()) return '$minVal';
    return '$minVal - $maxVal';
  }

  static Future<void> _openUrl(BuildContext context, String? link) async {
    if (link != null && link.isNotEmpty) {
      final Uri url = Uri.parse(link);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar(context, "ไม่สามารถเปิดลิงก์นี้ได้");
      }
    } else {
      _showSnackBar(context, "ไม่มีข้อมูลลิงก์รายละเอียด");
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Widget _buildNutrientText(String label, String value,
      {String unit = 'mg/kg'}) {
    bool hasValue = !(value == '-' || value.trim().isEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label :",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (hasValue)
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildEnvGridRow({
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
          child: Row(
            children: [
              if (iconLeft != null)
                Icon(iconLeft, color: colorLeft, size: 28)
              else
                const SizedBox(width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    Text("$titleLeft : ",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    Text(valueLeft,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              if (iconRight != null)
                Icon(iconRight, color: colorRight, size: 28)
              else
                const SizedBox(width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    Text("$titleRight : ",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    Text(valueRight,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}