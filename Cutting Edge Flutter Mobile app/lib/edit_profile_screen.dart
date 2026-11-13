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

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'catalog_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';

/// A screen that allows the user (Customer or Stylist) to edit their profile details.
/// It handles updating basic info, changing the profile picture, and updating passwords.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Form key for validating the input fields
  final _formKey = GlobalKey<FormState>();
  
  // Controllers to manage text input
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State variables
  String _dateOfBirth = 'Not set';
  bool _isLoading = false;
  bool _uploadingPhoto = false;
  String? _photoUrl;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Fetch the currently logged-in user's metadata to pre-fill the form
    final user = Supabase.instance.client.auth.currentUser;
    final String fullName = user?.userMetadata?['full_name'] ?? '';
    final String phone = user?.userMetadata?['phone'] ?? '';
    final String email = user?.email ?? '';
    final String dob = user?.userMetadata?['date_of_birth'] ?? 'Not set';

    // Split the full name into first name and surname
    final nameParts = fullName.trim().split(' ');
    final String firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final String surname = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

    // Initialize controllers with the fetched data
    _nameController = TextEditingController(text: firstName);
    _surnameController = TextEditingController(text: surname);
    _emailController = TextEditingController(text: email);
    _phoneController = TextEditingController(text: phone);
    _dateOfBirth = dob;
    
    // Load the profile picture from the custom profiles table
    _loadProfile();
  }

  @override
  void dispose() {
    // Clean up controllers when the screen is closed
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Fetches the user's profile picture URL from the 'profiles' table.
  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      // Fetch only the photo_url column
      final row = await Supabase.instance.client.from('profiles')
          .select('photo_url')
          .eq('id', user.id)
          .maybeSingle();
          
      if (mounted) {
        setState(() {
          _photoUrl = row?['photo_url']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Could not load profile: $e');
    }
  }

  /// Opens the device gallery, picks an image, uploads it to Supabase Storage,
  /// and updates the user's profile record with the new image URL.
  Future<void> _changeProfilePhoto() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null || _uploadingPhoto) return;
    
    // Pick image from gallery with max width 1200px and 85% quality to save bandwidth
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
        
    if (picked == null) return;
    
    setState(() => _uploadingPhoto = true);
    try {
      // Read the image as bytes
      final bytes = await picked.readAsBytes();
      
      // Enforce a maximum file size of 5MB
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Please choose an image smaller than 5 MB.');
      }
      
      // Determine the file extension and mime type
      final ext = picked.name.toLowerCase().split('.').last;
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      
      // Create a unique file path for the avatar in the storage bucket
      final path = 'avatars/${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      // Upload the binary data to the 'avatars' bucket
      await supabase.storage.from('avatars').uploadBinary(
        path, Uint8List.fromList(bytes),
        fileOptions: FileOptions(contentType: mime, upsert: false));
        
      // Get the public URL of the newly uploaded image
      final url = supabase.storage.from('avatars').getPublicUrl(path);
      
      // Update the 'profiles' table with the new URL
      await supabase.from('profiles').update({'photo_url': url}).eq('id', user.id);
      
      if (mounted) {
        setState(() => _photoUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update picture: $e')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  /// Opens a native date picker dialog for selecting the Date of Birth.
  Future<void> _pickDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: Colors.black,
            surface: AppColors.surfaceAlt,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      // Format the date to YYYY-MM-DD
      setState(() {
        _dateOfBirth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  /// Validates the form and saves all the updated information to Supabase.
  Future<void> _saveChanges() async {
    // 1. Validate all text fields
    if (!_formKey.currentState!.validate()) return;
    
    // 2. Check if passwords match (if a new password was entered)
    if (_passwordController.text.isNotEmpty && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final currentEmail = supabase.auth.currentUser?.email;
      final newFullName = '${_nameController.text.trim()} ${_surnameController.text.trim()}'.trim();

      // 3. Update the Auth user metadata (full name, phone, DOB)
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': newFullName,
            'phone': _phoneController.text.trim(),
            'date_of_birth': _dateOfBirth,
          },
        ),
      );

      // 4. Update the custom 'profiles' table with the new full name
      await supabase.from('profiles').update({
        'full_name': newFullName,
      }).eq('id', supabase.auth.currentUser!.id);

      // 5. Update Email (if it was changed)
      if (_emailController.text.trim() != currentEmail) {
        await supabase.auth.updateUser(
          UserAttributes(email: _emailController.text.trim()),
        );
      }

      // 6. Update Password (if a new one was provided)
      bool passwordChanged = false;
      if (_passwordController.text.isNotEmpty) {
        await supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
        passwordChanged = true;
      }

      if (!mounted) return;
      _passwordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordChanged 
              ? 'Profile and password updated successfully!' 
              : 'Profile updated successfully!'), 
          backgroundColor: AppColors.success,
        ),
      );
      
      // Close the screen and return to the previous one
      Navigator.pop(context); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // PROFILE PICTURE SECTION
              // ==========================================
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        // Display current image or a placeholder
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.12),
                            border: Border.all(color: AppColors.gold, width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CatalogImage(source: _photoUrl, width: 100, height: 100, circular: true),
                        ),
                        // Camera icon button to trigger image upload
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: _uploadingPhoto ? null : _changeProfilePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                              child: _uploadingPhoto
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : const Icon(Icons.camera_alt, color: Colors.black, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _uploadingPhoto ? null : _changeProfilePhoto,
                      child: const Text(
                        'Change Profile Picture',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ==========================================
              // PERSONAL DETAILS FIELDS
              // ==========================================
              _buildLabel('Name'),
              _buildTextField(controller: _nameController, hint: 'Enter your name', icon: Icons.person_outline),
              const SizedBox(height: 16),

              _buildLabel('Surname'),
              _buildTextField(controller: _surnameController, hint: 'Enter your surname', icon: Icons.person_outline),
              const SizedBox(height: 16),

              _buildLabel('Email'),
              _buildTextField(controller: _emailController, hint: 'Enter your email', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              _buildLabel('Phone Number'),
              _buildTextField(controller: _phoneController, hint: 'Enter your phone number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),

              // ==========================================
              // DATE OF BIRTH PICKER
              // ==========================================
              _buildLabel('Date of Birth'),
              GestureDetector(
                onTap: _pickDateOfBirth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _dateOfBirth == 'Not set' ? 'Select Date of Birth' : _dateOfBirth,
                        style: TextStyle(
                          color: _dateOfBirth == 'Not set' ? AppColors.textMuted : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // PASSWORD CHANGE SECTION
              // ==========================================
              const Divider(color: AppColors.border, height: 32),
              const Text('Change Password (Leave blank to keep current)', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              _buildLabel('New Password'),
              _buildTextField(
                controller: _passwordController, hint: '••••••••', icon: Icons.lock_outline,
                isPassword: true, isObscure: _hidePassword,
                onTogglePassword: () => setState(() => _hidePassword = !_hidePassword),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null; 
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Confirm New Password'),
              _buildTextField(
                controller: _confirmPasswordController, hint: '••••••••', icon: Icons.lock_outline,
                isPassword: true, isObscure: _hideConfirmPassword,
                onTogglePassword: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                validator: (value) {
                  if (_passwordController.text.isNotEmpty) {
                    if (value == null || value.isEmpty) return 'Please confirm your new password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // ==========================================
              // ACTION BUTTONS
              // ==========================================
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('SAVE CHANGES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget to build a consistent uppercase label for the text fields.
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700),
      ),
    );
  }

  /// Helper widget to build a consistent text input field with icons and validation.
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isObscure,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      // Default validation checks if the field is empty
      validator: validator ?? (value) {
        if (value == null || value.trim().isEmpty) return 'This field cannot be empty';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
        // Add a visibility toggle icon if it's a password field
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 18),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gold)),
      ),
    );
  }
}