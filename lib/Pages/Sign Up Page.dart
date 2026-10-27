import 'package:flutter/material.dart';
import 'package:resourceapp/Pages/Sign%20In%20Page.dart';
import 'package:resourceapp/Pages/Bottom Nav.dart';
import 'package:resourceapp/Services/Supabase service.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final SupabaseService _service = SupabaseService();
  bool _submitting = false;

  String? selectedLevel;
  String? selectedDepartment;

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final levels = ['100 Level', '200 Level', '300 Level', '400 Level', '500 Level'];
  final departments = ['Information Technology'];

  final bgColor = const Color(0xFFF0ECF9);
  final titleColor = const Color(0xD9150054);
  final labelColor = const Color(0x9C150054);
  final fieldBorder = const Color(0x4F6A3DF0);
  final hintColor = const Color(0x4F150054);
  final dropdownHintColor = const Color(0xAB150054);
  final btnColor = const Color(0xF26A3DF0);
  final noAccColor = const Color(0x99150054);
  final signInColor = const Color(0xE6150054);
  final eyeColor = const Color(0xFF716593);

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder, width: 1.4)),
    );
  }

  Future<void> _handleSignUp() async {
    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        selectedLevel == null ||
        selectedDepartment == null) {
      _showSnackBar('Please fill in all fields.', isError: true);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      await _service.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
        role: 'student', // server-side trigger overrides this if the
        // email is on the admin_emails allowlist.
        department: selectedDepartment,
        level: selectedLevel,
      );

      if (!mounted) return;
      _showSnackBar('Account created successfully!', isError: false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BottomNav()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Sign up failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Logo, centered at the top
              Center(
                child: Image.asset(
                  'assets/images/appy.png',
                  width: 140,
                  height: 140,
                ),
              ),

              const SizedBox(height: 16),

              Text('Sign Up', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: titleColor)),
              const SizedBox(height: 24),

              Text('FullName', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 8),
              TextField(controller: fullNameController, decoration: fieldDecoration('Drew Jack')),
              const SizedBox(height: 20),

              Text('Student Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: fieldDecoration('user@futa.edu.ng'),
              ),
              const SizedBox(height: 20),

              Text('Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                icon: Icon(Icons.keyboard_arrow_down, color: eyeColor),
                hint: Text('Select Level', style: TextStyle(color: dropdownHintColor, fontSize: 14)),
                decoration: fieldDecoration(''),
                style: TextStyle(color: titleColor, fontSize: 14),
                items: levels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedLevel = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              Text('Department', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedDepartment,
                icon: Icon(Icons.keyboard_arrow_down, color: eyeColor),
                hint: Text('Select Department', style: TextStyle(color: dropdownHintColor, fontSize: 14)),
                decoration: fieldDecoration(''),
                style: TextStyle(color: titleColor, fontSize: 14),
                items: departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDepartment = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: fieldDecoration('Enter Password').copyWith(
                  suffixIcon: IconButton(
                    icon: CustomPaint(
                      size: const Size(18, 13),
                      painter: EyeIconPainter(isOpen: !obscurePassword, color: eyeColor),
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Confirm Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: fieldDecoration('Confirm Password').copyWith(
                  suffixIcon: IconButton(
                    icon: CustomPaint(
                      size: const Size(18, 13),
                      painter: EyeIconPainter(isOpen: !obscureConfirmPassword, color: eyeColor),
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an Account? ", style: TextStyle(fontSize: 13, color: noAccColor)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SignIn()));
                      },
                      child: Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: signInColor)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class EyeIconPainter extends CustomPainter {
  final bool isOpen;
  final Color color;

  EyeIconPainter({required this.isOpen, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = color;

    final eyePath = Path()
      ..moveTo(0, size.height / 2)
      ..quadraticBezierTo(size.width / 2, -size.height * 0.55, size.width, size.height / 2)
      ..quadraticBezierTo(size.width / 2, size.height * 1.55, 0, size.height / 2)
      ..close();

    canvas.drawPath(eyePath, fillPaint);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.34,
      Paint()..color = Colors.white,
    );

    if (!isOpen) {
      final slashPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.16
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(size.width * 0.05, size.height * 1.05),
        Offset(size.width * 0.95, -size.height * 0.05),
        slashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EyeIconPainter oldDelegate) => oldDelegate.isOpen != isOpen;
}