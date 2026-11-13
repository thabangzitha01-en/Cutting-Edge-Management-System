/*
===========================================================
PROJECT: Cutting Edge Salon
STUDENT DETAILS:
-----------------------------------------------------------
Name                  | Student Number
-----------------------------------------------------------
Goitse Kgwele         | 221050663
Thabang Zitha         | 223007074
Yamkela Mazamani      | 224007421
Nyakallo Pali         | 223060226
Bennet Linda          | 224004294
===========================================================
*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';         // Custom colors and styles
import 'app_bars.dart';          // Custom AppBar widgets
import 'buttons.dart';           // Custom buttons (GoldButton, GhostButton)
import 'inputs.dart';            // Custom text fields (AppTextField)
import 'email_service.dart';     // Service to send emails via SMTP
import 'reset_password_screen.dart'; // Screen to enter the reset code and new password

/// A screen where users can request a password reset.
/// It asks for the user's email, generates a 6-digit code, sends it via email, 
/// and then navigates to the screen where they can enter the code and set a new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Key to validate the form fields
  final _formKey = GlobalKey<FormState>();
  
  // Controller to manage the email input
  final _email = TextEditingController();
  
  // State variable to show a loading indicator
  bool _loading = false;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    // Clean up the controller when the screen is closed
    _email.dispose();
    super.dispose();
  }

  /// Helper method to show a SnackBar message.
  void _message(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Handles the logic for sending the password reset code.
  Future<void> _sendResetLink() async {
    // 1. Validate the form to ensure the email field is properly filled
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus(); // Hide the keyboard
    setState(() => _loading = true);

    try {
      final email = _email.text.trim();

      // 2. Generate a 6-digit reset code based on the current timestamp
      final resetCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

      // 3. Send the email using the custom EmailService
      final emailSent = await EmailService.sendPasswordResetCode(email, resetCode);

      if (!mounted) return;

      if (emailSent) {
        _message('Reset code sent! Check $email.', color: AppColors.success);

        // Small delay so the user sees the success message before navigating
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        // 4. Navigate to the Reset Password Screen and pass the email and the generated code
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: email, 
              expectedCode: resetCode, // Pass the code directly to verify later
            ),
          ),
        );
      } else {
        _message('Failed to send reset email. Check your console logs.', color: AppColors.error);
      }

    } catch (e) {
      _message(e.toString().replaceAll('Exception: ', ''), color: AppColors.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenAppBar(title: 'Forgot Password'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Page Title
                const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Page Description
                const Text(
                  'No worries! Enter your email address below and we will send you a 6-digit code to reset your password.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),

                // Email Input Field
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  controller: _email,
                  enabled: !_loading,
                ),

                const SizedBox(height: 22),

                // Submit Button (Shows a spinner while loading)
                _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        ),
                      )
                    : GoldButton(
                        label: 'Send Reset Code',
                        icon: Icons.arrow_forward,
                        onPressed: _sendResetLink,
                      ),

                const SizedBox(height: 16),
                
                // Back to Login Button
                GhostButton(
                  label: 'Back to Login',
                  onPressed: _loading ? null : () => Navigator.pop(context),
                ),
                const SizedBox(height: 26),
                
                // Footer Help Text
                const Center(
                  child: Text(
                    'Need help? Contact your salon admin',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}