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
import 'app_theme.dart';             // Custom colors and styles
import 'app_bars.dart';              // Custom AppBar widget
import 'edit_profile_screen.dart';   // Screen to edit the profile
import 'my_appointment_screen.dart'; // Screen to view appointments
import 'settings_screen.dart';       // Screen for account settings
import 'catalog_image.dart';         // Custom image widget with error handling
import 'package:intl/intl.dart';     // For formatting dates

/// A screen that displays the profile of a Stylist.
/// It shows their personal information and provides quick access to their 
/// appointments, monthly earnings, and settings.
class StylistProfileScreen extends StatefulWidget {
  const StylistProfileScreen({super.key});

  @override
  State<StylistProfileScreen> createState() => _StylistProfileScreenState();
}

class _StylistProfileScreenState extends State<StylistProfileScreen> {
  final _supabase = Supabase.instance.client;

  // State variables
  bool _loading = true;
  Map<String, dynamic>? _profile;
  dynamic _stylistId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Fetches the current user's profile data and their associated stylist ID.
  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // 1. Fetch the general profile information
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // 2. Fetch the specific stylist ID linked to this profile
      final stylistData = await _supabase
          .from('stylists')
          .select('stylist_id')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _profile = profileData;
        _stylistId = stylistData?['stylist_id'];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error loading profile: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  /// Calculates the total earnings for the current calendar month.
  /// It fetches all completed bookings for the month, parses the prices, 
  /// and displays the total in a dialog.
  Future<void> _calculateMonthlyEarnings() async {
    if (_stylistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Stylist profile not found.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    // Show a loading spinner while calculating
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
    );

    try {
      final now = DateTime.now();
      
      // Calculate the first and last day of the current month
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0); 

      // Format dates as YYYY-MM-DD for the database query
      final String startStr = '${firstDayOfMonth.year}-${firstDayOfMonth.month.toString().padLeft(2, '0')}-01';
      final String endStr = '${lastDayOfMonth.year}-${lastDayOfMonth.month.toString().padLeft(2, '0')}-${lastDayOfMonth.day.toString().padLeft(2, '0')}';

      // Fetch completed bookings between the 1st and last day of the month
      final response = await _supabase
          .from('bookings')
          .select('final_price') 
          .eq('stylist_id', _stylistId)
          .gte('appointment_date', startStr)
          .lte('appointment_date', endStr)
          .eq('status', 'completed');

      double totalEarnings = 0.0;
      
      // Iterate through the bookings and sum up the final_price
      for (var row in (response as List)) {
        final dynamic priceStr = row['final_price'] ?? '0';
        
        // Clean the string (remove currency symbols) and parse it to a double
        final double? parsedPrice = double.tryParse(priceStr.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
        
        if (parsedPrice != null) {
          totalEarnings += parsedPrice;
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading spinner

      // Show the result in a dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
            side: const BorderSide(color: AppColors.gold)
          ),
          title: const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppColors.gold),
              SizedBox(width: 10),
              Text('This Month\'s Earnings', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(now), // Shows "October 2026"
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'R${totalEarnings.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.gold, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Calculated from completed appointments this month.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CLOSE', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error calculating earnings: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    // Extract data from the profile map for easy access
    final String fullName = _profile?['full_name'] ?? 'Stylist';
    final String firstName = fullName.split(' ').first;
    final String lastName = fullName.contains(' ') ? fullName.split(' ').last : '';
    final String email = _profile?['email'] ?? _supabase.auth.currentUser?.email ?? 'Not set';
    final String phone = _profile?['phone'] ?? 'Not set';
    final String dob = _profile?['date_of_birth'] != null 
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(_profile!['date_of_birth'])) 
        : 'Not set';
    final String? photoUrl = _profile?['photo_url'];

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const ScreenAppBar(title: 'My Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Column(
          children: [
            // ==========================================
            // HEADER (Profile Picture, Name, Role)
            // ==========================================
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? CatalogImage(source: photoUrl, width: 90, height: 90)
                        : const Icon(Icons.person, color: AppColors.gold, size: 50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stylist',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ==========================================
            // INFO CARD
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.person_outline, 'Name', firstName),
                  _buildDivider(),
                  _buildInfoRow(Icons.person_outline, 'Surname', lastName),
                  _buildDivider(),
                  _buildInfoRow(Icons.email_outlined, 'Email', email),
                  _buildDivider(),
                  _buildInfoRow(Icons.phone_outlined, 'Phone', phone),
                  _buildDivider(),
                  _buildInfoRow(Icons.cake_outlined, 'Date of Birth', dob),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // ACTION TILES
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.calendar_month_outlined,
                    title: 'My Appointments',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'This Month\'s Earnings', 
                    onTap: _calculateMonthlyEarnings, 
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // ==========================================
      // BOTTOM EDIT PROFILE BUTTON
      // ==========================================
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () async {
                // Navigate to edit screen and wait for the result
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                // If the profile was updated (result == true), reload the data
                if (result == true) _loadProfile(); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('EDIT PROFILE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper widget to build a single row of information (Label + Value).
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(), // Pushes the value to the right
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Helper widget to build the clickable action tiles (Appointments, Earnings, Settings).
  Widget _buildActionTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.gold, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
    );
  }

  /// Helper widget to build a thin divider line.
  Widget _buildDivider() {
    return const Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16);
  }
}