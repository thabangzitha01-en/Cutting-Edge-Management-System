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
import 'app_theme.dart';  // Custom colors and styles
import 'app_bars.dart';   // Custom AppBar widget

/// A screen that displays a list of past payments (receipts) for the customer.
/// It fetches bookings from the database and generates a virtual receipt for each.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _supabase = Supabase.instance.client;
  
  // State variables
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Fetches the customer's completed or confirmed bookings from Supabase 
  /// to display as payment history.
  Future<void> _loadHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetch bookings and join with the 'services' table to get the service name and price.
      // We only want 'completed' or 'confirmed' bookings to act as receipts.
      final data = await _supabase
          .from('bookings')
          .select('*, services(name, price)')
          .eq('customer_id', user.id)
          .inFilter('status', ['completed', 'confirmed'])
          .order('appointment_date', ascending: false); // Newest first

      if (!mounted) return;
      setState(() {
        _history = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('Error loading payment history: $e');
    }
  }

  /// Displays a pop-up dialog showing a formatted virtual receipt for a specific booking.
  void _showReceipt(Map<String, dynamic> booking) {
    // Generate a fake receipt reference based on the booking ID (e.g., CE-00015)
    final String ref = 'CE-${booking['booking_id'].toString().padLeft(5, '0')}';
    
    // Extract necessary details from the booking object
    final String date = booking['appointment_date'] ?? 'Unknown';
    final String service = booking['services']?['name'] ?? 'Salon Service';
    final String price = booking['services']?['price']?.toString() ?? 'R0';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
        title: const Center(
          child: Text('RECEIPT', style: TextStyle(color: AppColors.gold, letterSpacing: 2, fontWeight: FontWeight.bold)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(color: AppColors.border),
            // Helper method to build each row in the receipt
            _receiptRow('Reference', '#$ref'),
            _receiptRow('Date', date),
            _receiptRow('Service', service),
            const Divider(color: AppColors.border),
            _receiptRow('Total Paid', price, isBold: true),
            const Divider(color: AppColors.border),
            const SizedBox(height: 10),
            const Text('Thank you for visiting Cutting Edge!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  /// Helper method to build a single row in the receipt dialog.
  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // The label (e.g., "Date", "Service")
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          // The value (e.g., "24 Oct 2026", "R140")
          Text(
            value, 
            style: TextStyle(
              color: isBold ? AppColors.gold : Colors.white, 
              fontSize: 13, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600
            )
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenAppBar(title: 'Payment History'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _history.isEmpty
              ? const Center(child: Text('No payment history yet.', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final b = _history[index];
                    
                    // Extract details for the list item
                    final service = b['services']?['name'] ?? 'Salon Service';
                    final price = b['services']?['price']?.toString() ?? 'R0';
                    final date = b['appointment_date'] ?? 'Unknown Date';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          // Left side: Receipt Icon
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.receipt_long, color: AppColors.gold, size: 22),
                          ),
                          const SizedBox(width: 14),
                          
                          // Middle: Service Name and Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(service, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          
                          // Right side: Price and "View Receipt" button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(price, style: const TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _showReceipt(b),
                                child: const Text(
                                  'View Receipt', 
                                  style: TextStyle(
                                    color: AppColors.textMuted, 
                                    fontSize: 11, 
                                    decoration: TextDecoration.underline
                                  )
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}