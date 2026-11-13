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

import 'package:supabase_flutter/supabase_flutter.dart';

/// A utility class used to manage the current Stylist's session data.
/// Its primary purpose is to fetch the `stylist_id` associated with the 
/// currently logged-in user (from the `auth.users` table) and cache it.
/// Caching prevents the app from making repetitive database queries.
class StylistSession {
  // Cached variables to store the stylist ID and the user ID it belongs to.
  static dynamic _cachedId;
  static String? _cachedUserId;
  
  // Stores the last error message if the database query fails or no row is found.
  static String? lastError;

  /// Resolves the `stylist_id` for the currently authenticated user.
  /// 
  /// [forceRefresh] - If true, bypasses the cache and fetches fresh data from the database.
  static Future<dynamic> resolve({bool forceRefresh = false}) async {
    // Get the currently logged-in user from Supabase Auth
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    // If we have a valid cache for this specific user and forceRefresh is false, return the cached ID.
    if (!forceRefresh && _cachedUserId == user.id) return _cachedId;

    try {
      // Query the 'stylists' table to find the row where the profile_id matches the user's ID.
      // Note: Depending on your DB schema, this column might be named 'profile_id' or 'user_id'.
      final row = await Supabase.instance.client
          .from('stylists')
          .select('stylist_id')
          .eq('profile_id', user.id)
          .maybeSingle();

      // If no row is found, log an error message. This usually means the user 
      // is a customer, not a stylist.
      if (row == null) {
        lastError = 'No row found in "stylists" table for user ${user.id}.';
      }

      // Update the cache with the new ID and user ID
      _cachedId = row?['stylist_id'];
      _cachedUserId = user.id;
      
      return _cachedId;
    } catch (e) {
      // Catch any database connection or query errors
      lastError = 'Database error: $e';
      return null;
    }
  }

  /// Clears the cached data. 
  /// This should be called when the user logs out or switches accounts to 
  /// prevent them from seeing another user's data.
  static void clear() {
    _cachedId = null;
    _cachedUserId = null;
    lastError = null;
  }
}