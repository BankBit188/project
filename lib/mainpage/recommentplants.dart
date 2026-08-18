import 'package:flutter/material.dart';

import 'package:project/navbar/navbars.dart'; 
import 'package:project/service/plants_service.dart'; 
import 'package:project/modal/plant_recommendation_helper.dart';

import 'package:project/style/style_recommentplants.dart';

class RecommendPlantsPage extends StatefulWidget {
  final bool isLoggedIn;
  const RecommendPlantsPage({super.key, this.isLoggedIn = false});

  @override
  State<RecommendPlantsPage> createState() => _RecommendPlantsPageState();
}

class _RecommendPlantsPageState extends State<RecommendPlantsPage> {
  bool _isLoading = false;

  List<dynamic> _cachedPlants = [];

  bool _isPrimaryNutrientEnabled = false;
  bool _isSecondaryNutrientEnabled = false;

  final TextEditingController _phController = TextEditingController();
  final TextEditingController _humidController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _saltyController = TextEditingController();
  final TextEditingController _nController = TextEditingController();
  final TextEditingController _pController = TextEditingController();
  final TextEditingController _kController = TextEditingController();
  final TextEditingController _caController = TextEditingController();
  final TextEditingController _mgController = TextEditingController();
  final TextEditingController _sController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _preloadPlantsData();
  }

  @override
  void dispose() {
    _phController.dispose();
    _humidController.dispose();
    _tempController.dispose();
    _saltyController.dispose();
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _caController.dispose();
    _mgController.dispose();
    _sController.dispose();
    super.dispose();
  }

  Future<void> _preloadPlantsData() async {
    try {
      _cachedPlants = await PlantsService.getplants();
    } catch (e) {
      debugPrint("Error preloading plants: $e");
    }
  }

  void _resetAllFields() {
    _phController.clear();
    _humidController.clear();
    _tempController.clear();
    _saltyController.clear();
    _nController.clear();
    _pController.clear();
    _kController.clear();
    _caController.clear();
    _mgController.clear();
    _sController.clear();

    setState(() {
      _isPrimaryNutrientEnabled = false;
      _isSecondaryNutrientEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("ล้างข้อมูลเรียบร้อยแล้ว"),
        backgroundColor: Color(0xFF1B4332),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CustomWarningDialog(message: message);
      },
    );
  }

  void _searchSuitablePlants() async {
    double? ph = double.tryParse(_phController.text.trim());
    if (_phController.text.isNotEmpty && (ph == null || ph < 0 || ph > 14)) {
      _showWarningDialog("ค่า pH ต้องอยู่ระหว่าง 0.0 ถึง 14.0");
      return;
    }

    double? humid = double.tryParse(_humidController.text.trim());
    if (_humidController.text.isNotEmpty && (humid == null || humid < 0 || humid > 100)) {
      _showWarningDialog("ค่าความชื้นต้องอยู่ระหว่าง 0% ถึง 100%");
      return;
    }

    double? temp = double.tryParse(_tempController.text.trim());
    if (_tempController.text.isNotEmpty && (temp == null || temp < -10 || temp > 60)) {
      _showWarningDialog("ค่าอุณหภูมิต้องอยู่ระหว่าง -10°C ถึง 60°C");
      return;
    }

    double? salty = double.tryParse(_saltyController.text.trim());
    if (_saltyController.text.isNotEmpty && (salty == null || salty < 0)) {
      _showWarningDialog("ค่าความเค็มต้องมากกว่าหรือเท่ากับ 0");
      return;
    }

    if (_isPrimaryNutrientEnabled) {
      if (_nController.text.trim().isEmpty ||
          _pController.text.trim().isEmpty ||
          _kController.text.trim().isEmpty) {
        _showWarningDialog("กรุณากรอกค่าธาตุอาหารหลัก (N, P, K) ให้ครบ หรือปิดสวิตช์");
        return;
      }
    }

    if (_isSecondaryNutrientEnabled) {
      if (_caController.text.trim().isEmpty ||
          _mgController.text.trim().isEmpty ||
          _sController.text.trim().isEmpty) {
        _showWarningDialog("กรุณากรอกค่าธาตุอาหารรอง (Ca, Mg, S) ให้ครบ หรือปิดสวิตช์");
        return;
      }
    }

    int activeCriteriaCount = 0;
    if (_phController.text.isNotEmpty) activeCriteriaCount++;
    if (_humidController.text.isNotEmpty) activeCriteriaCount++;
    if (_tempController.text.isNotEmpty) activeCriteriaCount++;
    if (_saltyController.text.isNotEmpty) activeCriteriaCount++;
    if (_isPrimaryNutrientEnabled) activeCriteriaCount += 3;
    if (_isSecondaryNutrientEnabled) activeCriteriaCount += 3;

    if (activeCriteriaCount == 0) {
      _showWarningDialog("กรุณากรอกข้อมูลสภาพดินอย่างน้อย 1 รายการเพื่อค้นหา");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await PlantRecommendationHelper.showRecommendations(
      context: context,
      cachedPlants: _cachedPlants,
      customTitle: "พืชที่แนะนำตามค่าดินที่คุณกรอก",
      ph: _phController.text.isNotEmpty ? ph : null,
      humidity: _humidController.text.isNotEmpty ? humid : null,
      temp: _tempController.text.isNotEmpty ? temp : null,
      salty: _saltyController.text.isNotEmpty ? salty : null,
      n: _isPrimaryNutrientEnabled ? double.tryParse(_nController.text.trim()) : null,
      p: _isPrimaryNutrientEnabled ? double.tryParse(_pController.text.trim()) : null,
      k: _isPrimaryNutrientEnabled ? double.tryParse(_kController.text.trim()) : null,
      ca: _isSecondaryNutrientEnabled ? double.tryParse(_caController.text.trim()) : null,
      mg: _isSecondaryNutrientEnabled ? double.tryParse(_mgController.text.trim()) : null,
      s: _isSecondaryNutrientEnabled ? double.tryParse(_sController.text.trim()) : null,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
            colors: [Color(0xFFE4EFE7), Color(0xFFD0E1D4)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FormHeaderBanner(),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8F5),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFB8CBB9), width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitleCard(
                          title: "สภาพดินและสภาพแวดล้อม",
                          icon: Icons.landscape_rounded,
                        ),

                        PlantInputField(
                          label: "ค่า pH ดิน",
                          icon: Icons.science_outlined,
                          controller: _phController,
                          unit: "pH",
                        ),
                        PlantInputField(
                          label: "ความชื้นดิน",
                          icon: Icons.water_drop_outlined,
                          controller: _humidController,
                          unit: "%",
                        ),
                        PlantInputField(
                          label: "อุณหภูมิดิน",
                          icon: Icons.thermostat_outlined,
                          controller: _tempController,
                          unit: "°C",
                        ),
                        PlantInputField(
                          label: "ความเค็มดิน",
                          icon: Icons.grain_outlined,
                          controller: _saltyController,
                          unit: "mS/cm",
                        ),

                        SectionTitleCard(
                          title: "ธาตุอาหารหลัก (N, P, K)",
                          icon: Icons.eco_outlined,
                          isEnabled: _isPrimaryNutrientEnabled,
                          onChanged: (val) {
                            setState(() {
                              _isPrimaryNutrientEnabled = val ?? false;
                              if (!_isPrimaryNutrientEnabled) {
                                _nController.clear();
                                _pController.clear();
                                _kController.clear();
                              }
                            });
                          },
                        ),

                        PlantInputField(
                          label: "ไนโตรเจน (N)",
                          icon: Icons.grass_rounded,
                          controller: _nController,
                          unit: "mg/kg",
                          enabled: _isPrimaryNutrientEnabled,
                        ),
                        PlantInputField(
                          label: "ฟอสฟอรัส (P)",
                          icon: Icons.local_florist_outlined,
                          controller: _pController,
                          unit: "mg/kg",
                          enabled: _isPrimaryNutrientEnabled,
                        ),
                        PlantInputField(
                          label: "โพแทสเซียม (K)",
                          icon: Icons.park_outlined,
                          controller: _kController,
                          unit: "mg/kg",
                          enabled: _isPrimaryNutrientEnabled,
                        ),

                        SectionTitleCard(
                          title: "ธาตุอาหารรอง (Ca, Mg, S)",
                          icon: Icons.auto_awesome_outlined,
                          isEnabled: _isSecondaryNutrientEnabled,
                          onChanged: (val) {
                            setState(() {
                              _isSecondaryNutrientEnabled = val ?? false;
                              if (!_isSecondaryNutrientEnabled) {
                                _caController.clear();
                                _mgController.clear();
                                _sController.clear();
                              }
                            });
                          },
                        ),

                        PlantInputField(
                          label: "แคลเซียม (Ca)",
                          icon: Icons.shield_outlined,
                          controller: _caController,
                          unit: "mg/kg",
                          enabled: _isSecondaryNutrientEnabled,
                        ),
                        PlantInputField(
                          label: "แมกนีเซียม (Mg)",
                          icon: Icons.bolt_outlined,
                          controller: _mgController,
                          unit: "mg/kg",
                          enabled: _isSecondaryNutrientEnabled,
                        ),
                        PlantInputField(
                          label: "กำมะถัน (S)",
                          icon: Icons.opacity_outlined,
                          controller: _sController,
                          unit: "mg/kg",
                          enabled: _isSecondaryNutrientEnabled,
                        ),

                        const SizedBox(height: 14),

                        FormActionButtons(
                          onReset: _resetAllFields,
                          onSearch: _searchSuitablePlants,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.isLoggedIn
          ? const AuthNavBar(currentIndex: 2)
          : const GuestNavBar(currentIndex: 2),
    );
  }
}