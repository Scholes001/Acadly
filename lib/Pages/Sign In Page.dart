import 'package:flutter/material.dart';
import 'package:resourceapp/Pages/Sign%20Up%20Page.dart';
import 'package:resourceapp/Pages/Bottom Nav.dart';
import 'package:resourceapp/Services/Supabase service.dart';
class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  final SupabaseService _service = SupabaseService();
  bool _submitting = false;

  final bgColor = const Color(0xFFF0ECF9);
  final titleColor = const Color(0xD9150054);
  final labelColor = const Color(0x9C150054);
  final fieldBorder = const Color(0x4F6A3DF0);
  final hintColor = const Color(0x4F150054);
  final forgotColor = const Color(0x99150054);
  final btnColor = const Color(0xF26A3DF0);
  final noAccColor = const Color(0x99150054);
  final signUpColor = const Color(0xE6150054);
  final eyeColor = const Color(0xFF716593);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      _showSnackBar('Please enter your email and password.', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      await _service.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final profile = await _service.getMyProfile();
      final String fullName = (profile?['full_name'] as String?)?.trim() ?? '';
      final String displayName = fullName.isNotEmpty ? fullName : 'there';

      if (!mounted) return;
      _showSnackBar('Welcome, $displayName!', isError: false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BottomNav()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Sign in failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final String email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Enter your email above, then tap Forgot Password.', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      await _service.sendPasswordResetEmail(email);
      if (!mounted) return;
      _showSnackBar('Reset link sent to $email. Check your inbox.', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Could not send reset email: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : btnColor,
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
              const SizedBox(height: 40),

              // Logo, centered at the top
              Center(
                child: Image.asset(
                  'assets/images/appy.png',
                  width: 140,
                  height: 140,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Sign In',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: titleColor),
              ),

              const SizedBox(height: 32),

              Text('Student Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'user@futa.edu.ng',
                  hintStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder, width: 1.4)),
                ),
              ),

              const SizedBox(height: 24),

              Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter Password',
                  hintStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: CustomPaint(
                      size: const Size(18, 13),
                      painter: EyeIconPainter(isOpen: !obscurePassword, color: eyeColor),
                    ),
                    onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder, width: 1.4)),
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _submitting ? null : _handleForgotPassword,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Forgot Password?', style: TextStyle(fontSize: 13, color: forgotColor, fontWeight: FontWeight.w500)),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSignIn,
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
                      : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an Account? ", style: TextStyle(fontSize: 13, color: noAccColor)),
                    GestureDetector(
                      onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => SignUp()));
                      },
                      child: Text('Sign Up', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: signUpColor)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
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