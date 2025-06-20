import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../Screen 2 User/home_general.dart';
import '../Verifikasi Awal/daftar_pengguna.dart';

class ProfilePage extends StatefulWidget {
  final String? accountCategory; // ✅ Parameter untuk account category dari home

  const ProfilePage({super.key, this.accountCategory});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String _namaLengkap = "";
  String _email = "";
  String _accountCategory = "";
  String _profilePicture = "";
  bool _isLoading = true;
  bool _isUpdatingPicture = false;

  @override
  void initState() {
    super.initState();
    // ✅ Set account category dari parameter jika ada
    if (widget.accountCategory != null) {
      _accountCategory = widget.accountCategory!;
    }
    _loadUserData();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('Account_Storage').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _namaLengkap = userData['nama_lengkap'] ?? '';
            _email = userData['email'] ?? user.email ?? '';
            // ✅ Update account category jika belum ada dari parameter
            if (_accountCategory.isEmpty) {
              _accountCategory = userData['account_category'] ?? '';
            }
            _profilePicture = userData['profile_picture'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Convert account category to readable text
  String _getJenisPengguna(String accountCategory) {
    switch (accountCategory) {
      case 'ibu_hamil_balita':
        return 'Ibu Hamil / Balita';
      case 'sekolah_pesantren':
        return 'Sekolah / Pesantren';
      case 'petugas_distribusi': // ✅ Tambahkan case untuk petugas distribusi
        return 'Petugas Distribusi';
      default:
        return 'Koordinator Ibu Hamil';
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      setState(() {
        _isUpdatingPicture = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image != null) {
        // Convert image to base64
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);

        // Update profile picture in Firestore
        await _updateProfilePicture(base64String);
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorMessage('Gagal memilih gambar');
    } finally {
      setState(() {
        _isUpdatingPicture = false;
      });
    }
  }

  // Update profile picture in Firestore
  Future<void> _updateProfilePicture(String base64Image) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('Account_Storage').doc(user.uid).update({
          'profile_picture': base64Image,
        });

        setState(() {
          _profilePicture = base64Image;
        });

        _showSuccessMessage('Foto profil berhasil diperbarui');
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      _showErrorMessage('Gagal memperbarui foto profil');
    }
  }

  // Convert base64 to image widget
  Widget _buildProfileImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8F8962), width: 3),
      ),
      child: ClipOval(
        child:
            _profilePicture.isEmpty
                ? Image.asset(
                  'assets/profile.jpg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      color: const Color(0xFFD8D1A8),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF626F47),
                      ),
                    );
                  },
                )
                : Image.memory(
                  base64Decode(_profilePicture),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      color: const Color(0xFFD8D1A8),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF626F47),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  // Logout function
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error logging out: $e');
      _showErrorMessage('Gagal keluar dari aplikasi');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF626F47),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F3D1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF626F47)),
          onPressed: () {
            // ✅ Kembali sesuai account category
            if (_accountCategory == 'petugas_distribusi') {
              Navigator.pop(context); // Kembali ke HomePage petugas
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeGeneral()),
              );
            }
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF626F47),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF626F47)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Picture Section
                    Stack(
                      children: [
                        _buildProfileImage(),
                        if (_isUpdatingPicture)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF9F3D1),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Change Photo Button
                    GestureDetector(
                      onTap: _isUpdatingPicture ? null : _pickImage,
                      child: Text(
                        'Ganti foto pengguna',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _isUpdatingPicture
                                  ? const Color(0xFF8F8962)
                                  : const Color(0xFF626F47),
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form Fields
                    _buildFormField(
                      label: 'Nama Pengguna',
                      value: _namaLengkap.isEmpty ? 'rawimpuja' : _namaLengkap,
                    ),

                    const SizedBox(height: 20),

                    _buildFormField(label: 'Email', value: _email),

                    const SizedBox(height: 20),

                    _buildFormField(
                      label: 'Jenis Pengguna',
                      value: _getJenisPengguna(_accountCategory),
                    ),

                    const SizedBox(height: 60),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF626F47),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'KELUAR',
                          style: TextStyle(
                            color: Color(0xFFF9F3D1),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 120,
                    ), // Extra space untuk floating navbar
                  ],
                ),
              ),
    );
  }

  Widget _buildFormField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8F8962),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFD8D1A8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8F8962), width: 1),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF626F47),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
