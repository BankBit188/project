import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project/mainpage/tool.dart';
import 'package:project/login/register.dart';
import 'package:project/mainpage/menu.dart';
import 'package:project/service/user_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isCheckingAuth = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // 🟢 ปรับปรุงการเช็ค Auto-Login ให้รัดกุมขึ้น
  Future<void> _checkAutoLogin() async {
    try {
      final token = await _secureStorage.read(key: "auth_token");
      final userId = await _secureStorage.read(key: "Userid");

      // ต้องมีทั้ง Token และ Userid และต้องไม่เป็นค่าว่าง
      if (token != null &&
          token.trim().isNotEmpty &&
          userId != null &&
          userId.trim().isNotEmpty) {
        debugPrint("พบ Auth Token และ Userid สมบูรณ์ ทำการ Auto-Login");
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ToolPage()),
            (route) => false,
          );
          return;
        }
      } else {
        // 🟢 หากมีข้อมูลอย่างใดอย่างหนึ่งค้างอยู่แต่ไม่ครบ ให้ล้างทิ้งทันที
        await _secureStorage.delete(key: "auth_token");
        await _secureStorage.delete(key: "Userid");
      }
    } catch (e) {
      debugPrint("Error reading token: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  // 🟢 ปรับปรุงตรรกะการ Handle Login ให้บันทึกและตรวจสอบก่อนเปลี่ยนหน้า
  void _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    String email = _emailController.text.trim();
    String password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await UserService.login(email, password);
      
      final String? token = result['token'];
      final userData = result['user'];
      
      String? idToSave;
      if (userData != null) {
        idToSave = (userData['Userid'] ?? userData['id'])?.toString();
      }

      // 🟢 ต้องมีทั้ง Token และ Userid ที่ถูกต้องเท่านั้นจึงจะบันทึกและข้ามหน้าได้
      if (token != null && token.isNotEmpty && idToSave != null && idToSave.isNotEmpty) {
        await _secureStorage.write(key: "auth_token", value: token);
        await _secureStorage.write(key: "Userid", value: idToSave);

        debugPrint("บันทึก Auth Token และ Userid ($idToSave) สำเร็จ");
        _showSnackBar("เข้าสู่ระบบสำเร็จ", Colors.green);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ToolPage()),
            (route) => false,
          );
        }
      } else {
        _showSnackBar("ข้อมูลเข้าสู่ระบบไม่ถูกต้อง หรือไม่พบ User ID", Colors.red);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFDCEAF1), Color(0xFFD2E0C4)],
              ),
            ),
            child: SafeArea(
              child: _isCheckingAuth
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4C8E16),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 60,
                            ),
                            child: IntrinsicHeight(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const MenuPage(),
                                          ),
                                        );
                                      },
                                      child: Image.asset(
                                        'assets/images/backpage.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 50),
                                    const Center(
                                      child: Text(
                                        "เข้าสู่ระบบ",
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),

                                    _buildEmailField(),
                                    const SizedBox(height: 20),

                                    _buildPasswordField(),
                                    const SizedBox(height: 30),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF4C8E16,
                                          ),
                                          disabledBackgroundColor: const Color(
                                            0xFF4C8E16,
                                          ).withOpacity(0.6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            side: const BorderSide(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : const Text(
                                                "เข้าสู่ระบบ",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),

                                    _buildButton(
                                      "ลงทะเบียนอุปกรณ์",
                                      const Color(0xFF1D460B),
                                      () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const RegisterPage(),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) {
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '  กรุณากรอกอีเมล';
          }
          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegExp.hasMatch(value.trim())) {
            return '  รูปแบบอีเมลไม่ถูกต้อง';
          }
          return null;
        },
        decoration: const InputDecoration(
          hintText: "อีเมล",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextFormField(
        controller: _passwordController,
        focusNode: _passwordFocusNode,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _handleLogin(),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '  กรุณากรอกรหัสผ่าน';
          }
          if (value.length < 6) {
            return '  รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: "รหัสผ่าน",
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.black54,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.black87),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}