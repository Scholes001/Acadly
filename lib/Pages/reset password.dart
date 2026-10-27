import 'package:flutter/material.dart';
import 'package:resourceapp/Pages/Sign In Page.dart';
import 'package:resourceapp/Services/Supabase service.dart';

/// Shown automatically when the user taps the reset link in their email.
class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirm = true;

  final SupabaseService _service = SupabaseService();
  bool _submitting = false;

  final bgColor = const Color(0xFFF0ECF9);
  final titleColor = const Color(0xD9150054);
  final labelColor = const Color(0x9C150054);
  final fieldBorder = const Color(0x4F6A3DF0);
  final hintColor = const Color(0x4F150054);
  final btnColor = const Color(0xF26A3DF0);
  final eyeColor = const Color(0xFF716593);

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final String password = passwordController.text;
    final String confirm = confirmController.text;

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters.', isError: true);
      return;
    }
    if (password != confirm) {
      _showSnackBar('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      await _service.updatePassword(password);
      await _service.signOut();

      if (!mounted) return;
      _showSnackBar('Password updated. Please sign in with your new password.', isError: false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignIn()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Could not update password: $e', isError: true);
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

  InputDecoration _decoration({
    required String hint,
    required bool obscured,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: IconButton(
        icon: CustomPaint(
          size: const Size(18, 13),
          painter: EyeIconPainter(isOpen: !obscured, color: eyeColor),
        ),
        onPressed: onToggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder, width: 1.4)),
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
              const SizedBox(height: 160),

              Text(
                'Reset Password',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: titleColor),
              ),

              const SizedBox(height: 8),

              Text(
                'Enter a new password for your account.',
                style: TextStyle(fontSize: 14, color: labelColor),
              ),

              const SizedBox(height: 32),

              Text('New Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: _decoration(
                  hint: 'Enter new password',
                  obscured: obscurePassword,
                  onToggle: () => setState(() => obscurePassword = !obscurePassword),
                ),
              ),

              const SizedBox(height: 24),

              Text('Confirm Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor)),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                obscureText: obscureConfirm,
                decoration: _decoration(
                  hint: 'Re-enter new password',
                  obscured: obscureConfirm,
                  onToggle: () => setState(() => obscureConfirm = !obscureConfirm),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSave,
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
                      : const Text('Save Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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