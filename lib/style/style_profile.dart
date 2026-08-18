import 'package:flutter/material.dart';

/// -----------------------------------------------------------------
/// 1. PROFILE THEME
/// -----------------------------------------------------------------
class ProfileTheme {
  static const Color bgGradientStart = Color(0xFFDCEAF1);
  static const Color bgGradientEnd = Color(0xFFD2E0C4);

  static const Color cardBg = Color(0xFFE3ECE1);
  static const Color modalBg = Color(0xFFE8EFE6);
  static const Color primaryGreen = Color(0xFF4A7C59);
  static const Color darkGreen = Color(0xFF2E5A39);
  static const Color textColor = Color(0xFF212522);

  static const BoxDecoration pageDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bgGradientStart, bgGradientEnd],
    ),
  );

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black26, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 2. HEADER WIDGET
/// -----------------------------------------------------------------
class ProfileHeaderWidget extends StatelessWidget {
  final VoidCallback onBackPressed;

  const ProfileHeaderWidget({
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
                color: ProfileTheme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "โปรไฟล์",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.account_circle_outlined,
          size: 30,
          color: Colors.black87,
        ),
      ],
    );
  }
}

/// -----------------------------------------------------------------
/// 3. AVATAR WIDGET (กรอบสีเทาอ่อนละมุน ไอคอนสีดำ)
/// -----------------------------------------------------------------
class ProfileAvatarWidget extends StatelessWidget {
  const ProfileAvatarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: ProfileTheme.cardBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 68,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 4. USERNAME CARD (คงกรอบชัดเจน มีคำว่า ชื่อผู้ใช้งาน: สีดำ)
/// -----------------------------------------------------------------
class ProfileUsernameTile extends StatelessWidget {
  final String username;
  final VoidCallback onEditPressed;

  const ProfileUsernameTile({
    super.key,
    required this.username,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: ProfileTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26, width: 1.2), // กรอบยังอยู่ ชัดเจนสวยงาม
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline_rounded,
            color: Colors.black87,
            size: 24,
          ),
          const SizedBox(width: 10),
          const Text(
            "ชื่อผู้ใช้งาน:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black, // ชื่อผู้ใช้งานสีดำ
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onEditPressed,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
              child: const Icon(
                Icons.edit,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 5. PASSWORD CARD (คงกรอบชัดเจน)
/// -----------------------------------------------------------------
class ProfilePasswordTile extends StatelessWidget {
  final VoidCallback onEditPressed;

  const ProfilePasswordTile({
    super.key,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: ProfileTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26, width: 1.2), // กรอบยังอยู่ ชัดเจนสวยงาม
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: Colors.black87,
            size: 24,
          ),
          const SizedBox(width: 10),
          const Text(
            "รหัสผ่าน:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              "********",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onEditPressed,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
              child: const Icon(
                Icons.edit,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 6. DIALOG STYLES
/// -----------------------------------------------------------------
class ProfileEditUsernameDialog extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const ProfileEditUsernameDialog({
    super.key,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ProfileTheme.modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.black26, width: 1),
      ),
      title: const Text(
        "แก้ไขชื่อผู้ใช้งาน",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      content: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.black),
        decoration: ProfileTheme.inputDecoration('ชื่อผู้ใช้งานใหม่'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ยกเลิก", style: TextStyle(color: Colors.redAccent)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ProfileTheme.primaryGreen,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onSave,
          child: const Text("บันทึก", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class ProfileChangePasswordDialog extends StatelessWidget {
  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSave;

  const ProfileChangePasswordDialog({
    super.key,
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ProfileTheme.modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.black26, width: 1),
      ),
      title: const Text(
        "เปลี่ยนรหัสผ่านใหม่",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.black),
              decoration: ProfileTheme.inputDecoration('รหัสผ่านเดิม'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.black),
              decoration: ProfileTheme.inputDecoration('รหัสผ่านใหม่'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.black),
              decoration: ProfileTheme.inputDecoration('ยืนยันรหัสผ่านใหม่'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ยกเลิก", style: TextStyle(color: Colors.redAccent)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ProfileTheme.primaryGreen,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onSave,
          child: const Text("บันทึก", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}