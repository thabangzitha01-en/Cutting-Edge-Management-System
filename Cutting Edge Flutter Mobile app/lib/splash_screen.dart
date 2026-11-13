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
import 'brand.dart';                  // Imports the BrandTitle widget (Logo and text)
import 'role_selection_screen.dart';  // The screen to navigate to after the splash screen

/// The initial screen that appears when the app is launched.
/// It displays the brand logo and title for a short duration before
/// automatically navigating to the Role Selection screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Sets a 1.5-second timer using Future.delayed.
    // Once the timer finishes, it checks if the widget is still in the widget tree (mounted)
    // to prevent errors, then navigates to the RoleSelectionScreen.
    // pushReplacement is used so the user cannot press "back" to return to the splash screen.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The UI is a simple black background with the BrandTitle centered on the screen.
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: BrandTitle(logoSize: 96)),
    );
  }
}