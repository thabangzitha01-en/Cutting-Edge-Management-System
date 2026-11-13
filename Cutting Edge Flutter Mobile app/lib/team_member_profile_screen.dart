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
import 'app_theme.dart';              
import 'app_bars.dart';              
import 'buttons.dart';               
import 'catalog_image.dart';         
import 'our_team_screen.dart';        
import 'booking_gate.dart';           
import 'services_screen.dart'; // Imported ServicesScreen to allow picking a service

/// A screen that displays the detailed public profile of a selected Stylist.
/// It shows their photo, name, role, bio, services offered, and allows 
/// the customer to book an appointment with them.
class TeamMemberProfileScreen extends StatelessWidget {
  final TeamMember member;
  
  const TeamMemberProfileScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenAppBar(title: 'Stylist Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // HEADER CARD
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  // Circular Profile Picture
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: member.photoUrl != null && member.photoUrl!.isNotEmpty
                        ? CatalogImage(source: member.photoUrl, width: 110, height: 110, circular: true)
                        : const Icon(Icons.person, color: AppColors.gold, size: 50),
                  ),
                  const SizedBox(height: 14),
                  
                  // Stylist Name
                  Text(
                    member.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  
                  // Stylist Role
                  Text(
                    member.role,
                    style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  
                  // Overall Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: AppColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${member.rating.toStringAsFixed(1)} overall',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // BIO SECTION
            // ==========================================
            const _SectionLabel(text: 'About'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                member.bio,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // SERVICES OFFERED SECTION
            // ==========================================
            const _SectionLabel(text: 'Services Offered'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              // Map the list of services to custom chips
              children: member.services.map((s) => _ServiceChip(label: s)).toList(),
            ),
            const SizedBox(height: 30),

            // ==========================================
            // ACTION BUTTONS
            // ==========================================
            GoldButton(
              label: 'Book with ${member.name.split(' ').first}',
              onPressed: () {
                // Use the BookingGate to check if the user already has an active booking.
                // If they don't, it navigates to the ServicesScreen, passing the stylist's 
                // name so the booking screen can remember who they selected.
                BookingGate.checkAndProceedToBook(
                  context,
                  ServicesScreen(initialStylist: member.name), 
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Back Button
            GhostButton(
              label: 'Back to Team',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// A helper widget to display a consistent section label (e.g., "ABOUT", "SERVICES OFFERED").
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(color: AppColors.gold, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// A helper widget to display a single service as a pill-shaped chip.
class _ServiceChip extends StatelessWidget {
  final String label;
  const _ServiceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}