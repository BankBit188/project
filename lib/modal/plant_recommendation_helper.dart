import 'package:flutter/material.dart';
import 'package:project/service/plants_service.dart';
import 'plant_detail.dart';

class PlantRecommendationHelper {
  /// 🟢 ฟังก์ชันหลักสำหรับประมวลผลและเปิด BottomSheet พืชแนะนำ
  static Future<void> showRecommendations({
    required BuildContext context,
    List<dynamic>? cachedPlants,
    String? customTitle,
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
                    String formattedImgUrl = PlantDetailDialog.formatImgUrl(rawImageUrl);

                    Color badgeColor = matchPercentage >= 80
                        ? Colors.green.shade800
                        : (matchPercentage >= 50
                            ? Colors.orange.shade800
                            : Colors.red.shade800);

                    return GestureDetector(
                      onTap: () => PlantDetailDialog.show(
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
}