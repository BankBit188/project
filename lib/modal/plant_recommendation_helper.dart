import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:project/service/plants_service.dart';

class PlantRecommendationHelper {
  static const String ngrokUrl =
      'https://uselessly-disclose-stingray.ngrok-free.dev';

  /// 🟢 ฟังก์ชันหลักสำหรับประมวลผลและเปิด BottomSheet พืชแนะนำ
  static Future<void> showRecommendations({
    required BuildContext context,
    List<dynamic>? cachedPlants,
    String? customTitle,
    // ปัจจัยสภาพอากาศ / ดิน (ส่งเฉพาะค่าที่มีได้ ค่าไหน null จะไม่ถูกนำมาคิดคะแนน)
    double? temp,
    double? humidity,
    double? n,
    double? p,
    double? k,
    double? ca,
    double? mg,
    double? s,
    double? ph,
    double? salty,
  }) async {
    try {
      List<dynamic> plantsToUse = cachedPlants ?? [];
      if (plantsToUse.isEmpty) {
        plantsToUse = await PlantsService.getplants();
      }

      List<Map<String, dynamic>> scoredPlants = [];

      for (var plant in plantsToUse) {
        double totalScore = 0.0;
        int activeCriteriaCount = 0;
        List<String> matchedTags = [];

        // ฟังก์ชันช่วยตรวจเช็กและคำนวณทีละปัจจัย
        void checkFactor(
            double? inputVal, dynamic minVal, dynamic maxVal, String label) {
          if (inputVal != null) {
            activeCriteriaCount++;
            totalScore += _evaluateFuzzyMatch(
              inputVal,
              minVal,
              maxVal,
              label,
              matchedTags,
            );
          }
        }

        // ตรวจสอบปัจจัยทั้งหมด (ถ้ารับค่ามา จะนำมาคำนวณ)
        checkFactor(humidity, plant['minhumid'], plant['maxhumid'], "ความชื้น");
        checkFactor(temp, plant['mintemperature'], plant['maxtemperature'], "อุณหภูมิ");
        checkFactor(n, plant['minN'], plant['maxN'], "N");
        checkFactor(p, plant['minP'], plant['maxP'], "P");
        checkFactor(k, plant['minK'], plant['maxK'], "K");
        checkFactor(ca, plant['minCa'], plant['maxCa'], "Ca");
        checkFactor(mg, plant['minMg'], plant['maxMg'], "Mg");
        checkFactor(s, plant['minS'], plant['maxS'], "S");
        checkFactor(ph, plant['minPH'], plant['maxPH'], "pH");
        checkFactor(salty, plant['minsalty'], plant['maxsalty'], "ความเค็ม");

        double matchPercentage = activeCriteriaCount > 0
            ? (totalScore / activeCriteriaCount) * 100
            : 0.0;
        if (matchPercentage > 100) matchPercentage = 100;

        scoredPlants.add({
          'plantData': plant,
          'matchPercentage': matchPercentage,
          'matchedTags': matchedTags,
        });
      }

      // เรียงลำดับจาก % สูงไปต่ำ และคัด Top 5
      scoredPlants.sort((a, b) =>
          b['matchPercentage'].compareTo(a['matchPercentage']));
      List<Map<String, dynamic>> top5Plants = scoredPlants.take(5).toList();

      if (context.mounted) {
        _showResultsBottomSheet(
          context,
          top5Plants,
          customTitle ?? "พืชแนะนำที่เหมาะสม 5 อันดับแรก",
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการประมวลผล: $e")),
        );
      }
    }
  }

  // 🟩 ฟังก์ชันประเมินคะแนนความเหมาะสม (Fuzzy Matching)
  static double _evaluateFuzzyMatch(
    double? input,
    dynamic minVal,
    dynamic maxVal,
    String factorName,
    List<String> matchedTags,
  ) {
    if (input == null || minVal == null || maxVal == null) return 0.0;
    double min = double.tryParse(minVal.toString()) ?? 0.0;
    double max = double.tryParse(maxVal.toString()) ?? double.infinity;

    if (input >= min && input <= max) {
      matchedTags.add(factorName);
      return 1.0;
    }

    double range = (max - min).abs();
    if (range == 0) range = 1.0;
    double margin = range * 0.20;

    if ((input < min && (min - input) <= margin) ||
        (input > max && (input - max) <= margin)) {
      matchedTags.add("$factorName (ใกล้เคียง)");
      return 0.5;
    }

    return 0.0;
  }

  // 🟩 แสดง Bottom Sheet รายชื่อพืชแนะนำ 5 อันดับแรก
  static void _showResultsBottomSheet(
    BuildContext context,
    List<Map<String, dynamic>> items,
    String title,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: const BoxDecoration(
            color: Color(0xFFF1E6C9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E5A36),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var plant = items[index]['plantData'];
                    double matchPercentage = items[index]['matchPercentage'];
                    List<String> matchedTags = items[index]['matchedTags'];

                    String plantName = plant['normal_name'] ?? 'ไม่ระบุชื่อ';
                    String rawImageUrl =
                        plant['img_cloudinary'] ?? plant['img'] ?? '';
                    String formattedImgUrl = _formatImgUrl(rawImageUrl);

                    Color badgeColor = matchPercentage >= 80
                        ? Colors.green.shade800
                        : (matchPercentage >= 50
                            ? Colors.orange.shade800
                            : Colors.red.shade800);

                    return GestureDetector(
                      onTap: () => showPlantDetailDialog(
                          context, Map<String, dynamic>.from(plant)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F8E5F),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF2E5A36), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${index + 1}. $plantName",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "ความเหมาะสม ${matchPercentage.toStringAsFixed(0)}%",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: formattedImgUrl.isNotEmpty
                                      ? Image.network(
                                          formattedImgUrl,
                                          width: 100,
                                          height: 85,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            width: 100,
                                            height: 85,
                                            color: Colors.white24,
                                            child: const Icon(Icons.eco,
                                                color: Colors.white, size: 40),
                                          ),
                                        )
                                      : Container(
                                          width: 100,
                                          height: 85,
                                          color: Colors.white24,
                                          child: const Icon(Icons.eco,
                                              color: Colors.white, size: 40),
                                        ),
                                ),
                              ],
                            ),
                            if (matchedTags.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(color: Colors.white30, height: 10),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: matchedTags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.white54, width: 0.5),
                                    ),
                                    child: Text(
                                      "✓ $tag",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🟩 Dialog แสดงรายละเอียดพืช (เปิดแยกเป็น Public Static เพื่อให้เรียกใช้ที่อื่นได้ด้วย)
  static void showPlantDetailDialog(
      BuildContext context, Map<String, dynamic> item) {
    String normalName = item['normal_name'] ?? 'ไม่มีชื่อพืช';
    String scientificName = item['scientific_name'] ?? 'ไม่มีชื่อวิทยาศาสตร์';
    String otherName = item['other_name'] ?? 'ไม่มีชื่ออื่นๆ';
    String imgUrl = _formatImgUrl(item['img_cloudinary'] ?? item['img'] ?? '');
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

  // 🛠️ Helpers ต่างๆ
  static String _formatImgUrl(String imgUrl) {
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