import 'package:flutter/material.dart';

/// -----------------------------------------------------------------
/// 1. HISTORY THEME (โทนสีธรรมชาติละมุน ถนอมสายตา ไม่ขาวจ้า)
/// -----------------------------------------------------------------
class HistoryTheme {
  static const Color bgGradientStart = Color(0xFFDCEAF1);
  static const Color bgGradientEnd = Color(0xFFD2E0C4);

  // สีโทนอุ่นละมุน ถนอมสายตา
  static const Color cardBg = Color(0xFFE3ECE1);        // สีเขียวซอฟต์พาสเทล
  static const Color modalBg = Color(0xFFE8EFE6);       // พื้นหลัง Modal โทนเขียวอุ่นละมุน
  static const Color primaryGreen = Color(0xFF4A7C59);
  static const Color darkGreen = Color(0xFF2E5A39);
  static const Color textColor = Color(0xFF212522);     // สีตัวอักษรเข้มพอดี ไม่ดำกระด้างเกินไป

  static const BoxDecoration pageDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bgGradientStart, bgGradientEnd],
    ),
  );
}

/// -----------------------------------------------------------------
/// 2. HEADER WIDGET (เพิ่มไอคอนข้างๆ คำว่า "ประวัติการบันทึก")
/// -----------------------------------------------------------------
class HistoryHeaderWidget extends StatelessWidget {
  final VoidCallback onBackPressed;

  const HistoryHeaderWidget({
    super.key,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBackPressed,
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/backpage.png',
            width: 35,
            height: 35,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: HistoryTheme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: HistoryTheme.textColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        const Text(
          "ประวัติการบันทึก",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: HistoryTheme.textColor,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.history_rounded, // ไอคอนประวัติการบันทึก
          size: 30,
          color: HistoryTheme.textColor,
        ),
      ],
    );
  }
}

/// -----------------------------------------------------------------
/// 3. SEARCH BAR WIDGET
/// -----------------------------------------------------------------
class HistorySearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const HistorySearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white, // เปลี่ยนเป็นสีขาว คมชัด ไม่กลืนกับพื้นหลัง
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black54,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // เงาให้ช่องค้นหาลอยเด่นขึ้น
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 16, 
          color: HistoryTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "ค้นหา เช่น ชื่อสวน",
          hintStyle: TextStyle(
            color: Colors.grey[600], // ข้อความตัวอย่างเข้มอ่านง่าย
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          prefixIcon: const Icon(
            Icons.search,
            color: HistoryTheme.primaryGreen, // ไอคอนสีเขียวเข้ม มองเห็นชัด
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 4. HISTORY CARD TILE (ปรับขอบการ์ดเป็นสีดำ)
/// -----------------------------------------------------------------
class HistoryCardTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String dateTimeStr;
  final VoidCallback onTap;

  const HistoryCardTile({
    super.key,
    required this.item,
    required this.dateTimeStr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String gardenName = item['title'] ?? 'ไม่ระบุชื่อ';
    final n = item['N'] ?? 0;
    final p = item['P'] ?? 0;
    final k = item['K'] ?? 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: HistoryTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black54, width: 1), // 👈 ปรับเป็นกรอบสีดำ
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    gardenName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HistoryTheme.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateTimeStr,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "ไนโตรเจน ( N ) : $n ฟอสฟอรัส ( P ) : $p",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              "โพแทสเซียม ( K ) : $k ......",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 5. HISTORY DETAIL MODAL (ปรับขอบป๊อปอัปเป็นสีดำ)
/// -----------------------------------------------------------------
class HistoryDetailModal extends StatelessWidget {
  final Map<String, dynamic> item;
  final String dateTimeStr;

  const HistoryDetailModal({
    super.key,
    required this.item,
    required this.dateTimeStr,
  });

  @override
  Widget build(BuildContext context) {
    final String gardenName = item['title'] ?? 'ไม่ระบุชื่อ';

    final n = item['N'] ?? 0;
    final p = item['P'] ?? 0;
    final k = item['K'] ?? 0;
    final ca = item['Ca'] ?? 0;
    final mg = item['Mg'] ?? 0;
    final s = item['S'] ?? 0;
    final humid = item['humid'] ?? 0;
    final salty = item['salty'] ?? 0;
    final temp = item['temperature'] ?? 0;
    final ph = item['PH'] ?? 0;

    final province = item['province'] ?? '-';
    final amphur = item['Amphur'] ?? '-';
    final district = item['district'] ?? '-';
    final region = item['Region'] ?? '-';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      backgroundColor: HistoryTheme.modalBg,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: HistoryTheme.modalBg,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.black54, width: 1), // 👈 ปรับเป็นกรอบสีดำ
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      gardenName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: HistoryTheme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28, color: HistoryTheme.textColor),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.history, size: 24, color: HistoryTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateTimeStr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HistoryTheme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // กล่องรวมธาตุอาหาร
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: HistoryTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black38, width: 1), // 👈 ปรับเป็นกรอบสีดำจางๆ
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text.rich(TextSpan(children: [const TextSpan(text: "N: ", style: TextStyle(fontWeight: FontWeight.bold, color: HistoryTheme.darkGreen)), TextSpan(text: "$n", style: const TextStyle(color: HistoryTheme.textColor))]), style: const TextStyle(fontSize: 17)),
                        Text.rich(TextSpan(children: [const TextSpan(text: "P: ", style: TextStyle(fontWeight: FontWeight.bold, color: HistoryTheme.darkGreen)), TextSpan(text: "$p", style: const TextStyle(color: HistoryTheme.textColor))]), style: const TextStyle(fontSize: 17)),
                        Text.rich(TextSpan(children: [const TextSpan(text: "K: ", style: TextStyle(fontWeight: FontWeight.bold, color: HistoryTheme.darkGreen)), TextSpan(text: "$k", style: const TextStyle(color: HistoryTheme.textColor))]), style: const TextStyle(fontSize: 17)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text.rich(TextSpan(children: [const TextSpan(text: "Ca: ", style: TextStyle(fontWeight: FontWeight.bold, color: HistoryTheme.darkGreen)), TextSpan(text: "$ca", style: const TextStyle(color: HistoryTheme.textColor))]), style: const TextStyle(fontSize: 17)),
                        Text.rich(TextSpan(children: [const TextSpan(text: "Mg: ", style: TextStyle(fontWeight: FontWeight.bold, color: HistoryTheme.darkGreen)), TextSpan(text: "$mg", style: const TextStyle(color: HistoryTheme.textColor))]), style: const TextStyle(fontSize: 17)),
                        Text.rich(TextSpan(children: [const TextSpan(text: "S: ", style: TextStyle(fontWeight: FontWeight.bold, color: HistoryTheme.darkGreen)), TextSpan(text: "$s", style: const TextStyle(color: HistoryTheme.textColor))]), style: const TextStyle(fontSize: 17)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.water_drop, color: Color(0xFF62B4E6), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "ความชื้น : $humid %",
                      style: const TextStyle(fontSize: 17, color: HistoryTheme.textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.science, color: Colors.purple, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: "pH ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: HistoryTheme.textColor)),
                        TextSpan(text: ": $ph", style: const TextStyle(fontSize: 17, color: HistoryTheme.textColor)),
                      ]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.thermostat, color: Colors.deepOrange, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "อุณหภูมิ : $temp C°",
                      style: const TextStyle(fontSize: 17, color: HistoryTheme.textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.opacity, color: Colors.teal, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "ความเค็ม : $salty mS/cm",
                      style: const TextStyle(fontSize: 17, color: HistoryTheme.textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("สถานที่", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: HistoryTheme.textColor)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ภาค: $region", style: const TextStyle(fontSize: 16, color: HistoryTheme.textColor)),
                    const SizedBox(height: 4),
                    Text("ตำบล: $district", style: const TextStyle(fontSize: 16, color: HistoryTheme.textColor)),
                    const SizedBox(height: 4),
                    Text("อำเภอ: $amphur", style: const TextStyle(fontSize: 16, color: HistoryTheme.textColor)),
                    const SizedBox(height: 4),
                    Text("จังหวัด: $province", style: const TextStyle(fontSize: 16, color: HistoryTheme.textColor)),
                  ],
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 6. PAGINATION BAR WIDGET
/// -----------------------------------------------------------------
class HistoryPaginationBar extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final Function(int) onPageSelected;

  const HistoryPaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    pageButtons.add(
      _buildPageBtn(
        "<",
        disabled: currentPage == 1,
        onTap: () => onPageSelected(currentPage - 1),
      ),
    );

    bool showLeftDots = false;
    bool showRightDots = false;

    for (int i = 1; i <= lastPage; i++) {
      if (i == 1 || i == lastPage || (i - currentPage).abs() <= 1) {
        pageButtons.add(
          _buildPageBtn(
            i.toString(),
            isActive: currentPage == i,
            onTap: () => onPageSelected(i),
          ),
        );
      } else if (i < currentPage && !showLeftDots) {
        showLeftDots = true;
        pageButtons.add(_buildDotsBtn());
      } else if (i > currentPage && !showRightDots) {
        showRightDots = true;
        pageButtons.add(_buildDotsBtn());
      }
    }

    pageButtons.add(
      _buildPageBtn(
        ">",
        disabled: currentPage == lastPage,
        onTap: () => onPageSelected(currentPage + 1),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: pageButtons,
          ),
        ),
      ),
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
              ? HistoryTheme.primaryGreen
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
                  : (disabled ? Colors.grey : Colors.black87),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}