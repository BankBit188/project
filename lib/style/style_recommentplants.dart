import 'package:flutter/material.dart';

/// 1. Header ด้านบนสไตล์ มินิมอล สะอาดตา คลีน ไม่รก
class FormHeaderBanner extends StatelessWidget {
  const FormHeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ไอคอนหลักแบบคลีน
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: Color(0xFFD8F3DC),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          // ข้อความหัวข้อกระชับ
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "กรอกข้อมูลสภาพดินที่เหมาะสม",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "เพื่อทำการค้นหาพืชปลูกที่เหมาะสม",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD8F3DC),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. ช่องกรอกข้อมูล คอนทราสต์สูง Responsive
class PlantInputField extends StatelessWidget {
  final String label;
  final String? subLabel;
  final String? unit;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;

  const PlantInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.subLabel,
    this.unit,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? const Color(0xFF1B4332) : const Color(0xFFCBD5E1),
            width: enabled ? 1.6 : 1.0,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B4332).withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFE8F5E9) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: enabled ? const Color(0xFF1B4332) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: enabled ? const Color(0xFF0F291E) : const Color(0xFF64748B),
                    ),
                  ),
                  if (subLabel != null)
                    Text(
                      subLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: enabled ? const Color(0xFF2D6A4F) : const Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              flex: 4,
              child: TextField(
                controller: controller,
                enabled: enabled,
                textAlign: TextAlign.end,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: enabled ? const Color(0xFF0F291E) : const Color(0xFF64748B),
                ),
                decoration: InputDecoration(
                  hintText: enabled ? "0.00" : "-",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),

            if (unit != null) ...[
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: enabled ? const Color(0xFFD8F3DC) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      color: enabled ? const Color(0xFF1B4332) : const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 3. แถบหัวข้อกลุ่ม ปรับสมดุลขนาดให้เท่ากันทุกกรอบ (Height & Structure Symmetric)
class SectionTitleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool? isEnabled;
  final ValueChanged<bool?>? onChanged;

  const SectionTitleCard({
    super.key,
    required this.title,
    required this.icon,
    this.isEnabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = isEnabled ?? true;
    return Container(
      height: 44, // กำหนดความสูงแน่นอนเพื่อให้กรอบทุกส่วนเท่ากันสมบูรณ์
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1B4332) : const Color(0xFF64748B),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onChanged != null && isEnabled != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isEnabled! ? "ระบุค่า" : "ปิดอยู่",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isEnabled! ? const Color(0xFFD8F3DC) : Colors.white70,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: isEnabled!,
                    onChanged: onChanged,
                    activeColor: const Color(0xFF52B788),
                    activeTrackColor: const Color(0xFF2D6A4F),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}

/// 4. ปุ่มสั่งการ Action Buttons
class FormActionButtons extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onSearch;
  final bool isLoading;

  const FormActionButtons({
    super.key,
    required this.onReset,
    required this.onSearch,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2D6A4F), width: 1.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.refresh_rounded, color: Color(0xFF2D6A4F), size: 18),
                    SizedBox(width: 4),
                    Text(
                      "ล้างค่า",
                      style: TextStyle(
                        color: Color(0xFF2D6A4F),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D6A4F), Color(0xFF1B4332)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4332).withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            "ค้นหา",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 5. Pop-up Dialog
class CustomWarningDialog extends StatelessWidget {
  final String message;

  const CustomWarningDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 32),
            ),
            const SizedBox(height: 14),
            const Text(
              "ข้อมูลไม่ถูกต้อง",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("เข้าใจแล้ว", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}