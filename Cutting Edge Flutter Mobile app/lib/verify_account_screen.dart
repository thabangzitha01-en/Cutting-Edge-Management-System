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
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';   
import 'app_bars.dart';    
import 'buttons.dart';     
import 'email_service.dart'; 
import 'login_screen.dart';  

class VerifyAccountScreen extends StatefulWidget {
  final String email;
  final String expectedCode; 
  final String fullName;
  final String phone;
  final String password;

  const VerifyAccountScreen({
    super.key,
    required this.email,
    required this.expectedCode,
    required this.fullName,
    required this.phone,
    required this.password,
  });

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final List<TextEditingController> _codes = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  late String _currentExpectedCode;

  @override
  void initState() {
    super.initState();
    _currentExpectedCode = widget.expectedCode;
  }

  @override
  void dispose() {
    for (final controller in _codes) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    final token = _codes.map((controller) => controller.text).join();

    if (token.length != 6 || !RegExp(r'^\d{6}$').hasMatch(token)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit code.')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // 👈 Check the code BEFORE creating the account
      if (token == _currentExpectedCode) {
        
        final supabase = Supabase.instance.client;

        // 1. Create the user in Supabase Auth
        final response = await supabase.auth.signUp(
          email: widget.email,
          password: widget.password,
          data: {
            'full_name': widget.fullName,
            'phone': widget.phone,
            'role': 'Customer',
          },
        );

        if (response.user == null) {
          throw Exception('Failed to create account. Please try again.');
        }

        // 2. Save the user details to the 'profiles' table
        try {
          await supabase.from('profiles').upsert({
            'id': response.user!.id,
            'full_name': widget.fullName,
            'email': widget.email,
            'phone': widget.phone,
          });
        } catch (e) {
          debugPrint('Could not save profile to database: $e');
        }

        // 3. Log the user out so they have to log in properly
        await supabase.auth.signOut();

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account verified! Please log in.'),
            backgroundColor: AppColors.success,
          ),
        );

        // 4. Go to Login Screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        throw Exception('Incorrect code. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isVerifying = true);
    
    try {
      // 1. Generate NEW code
      final newOtpCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

      // 2. Send Email
      final emailSent = await EmailService.sendVerificationCode(widget.email, newOtpCode);

      if (!mounted) return;
      
      if (emailSent) {
        setState(() {
          _currentExpectedCode = newOtpCode;
          for (var controller in _codes) {
            controller.clear();
          }
        });
        _focusNodes[0].requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new code has been sent to your email.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        throw Exception('Failed to send email.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _cancelAndGoBack() async {
    // Just go back without creating the account
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenAppBar(title: 'Verify Account'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.gold,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a verification code to ${widget.email}. '
                'Enter it below to continue.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _codes[i],
                      focusNode: _focusNodes[i],
                      onChanged: (value) => _onDigitChanged(i, value),
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              
              GoldButton(
                label: _isVerifying ? 'Verifying...' : 'Verify & Continue',
                onPressed: _isVerifying ? null : _verifyCode,
              ),
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: _isVerifying ? null : _resendCode,
                child: const Text(
                  'Resend verification code',
                  style: TextStyle(color: AppColors.gold),
                ),
              ),
              
              GhostButton(
                label: 'Cancel',
                onPressed: _isVerifying ? null : _cancelAndGoBack,
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Your account is protected',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}