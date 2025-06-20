import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuatPengumumanPage extends StatefulWidget {
  const BuatPengumumanPage({super.key});

  @override
  State<BuatPengumumanPage> createState() => _BuatPengumumanPageState();
}

class _BuatPengumumanPageState extends State<BuatPengumumanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _pengumumanController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pengumumanController.dispose();
    super.dispose();
  }

  // Format tanggal untuk key map (contoh: "15_06_2025")
  String _getDateKey() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}';
  }

  // Format tanggal untuk display (contoh: "15 Juni 2025")
  String _getDisplayDate() {
    final now = DateTime.now();
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${now.day} ${months[now.month]} ${now.year}';
  }

  // Format waktu lengkap (contoh: "15/06/2025 14:30 WIB")
  String _getFullDateTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
  }

  Future<void> _buatPengumuman() async {
    if (_pengumumanController.text.trim().isEmpty) {
      _showSnackBar('Pengumuman tidak boleh kosong!', isError: true);
      return;
    }

    // Tampilkan dialog konfirmasi
    final bool? confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dateKey = _getDateKey();
      final pengumumanText = _pengumumanController.text.trim();
      final fullDateTime = _getFullDateTime();

      // Simpan ke Firestore
      await _firestore.collection('System_Data').doc('notifikasi_user').set({
        dateKey: {'pengumuman': pengumumanText, 'tanggal_dibuat': fullDateTime},
      }, SetOptions(merge: true)); // merge: true untuk tidak menimpa data lain

      _showSnackBar('Pengumuman berhasil dibuat!', isError: false);

      // Reset form
      _pengumumanController.clear();

      // Kembali ke halaman sebelumnya setelah 1 detik
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      print('Error creating announcement: $e');
      _showSnackBar(
        'Gagal membuat pengumuman. Silakan coba lagi.',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF9F3D1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Pengumuman',
            style: TextStyle(
              color: Color(0xFF626F47),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin membuat pengumuman ini?',
                style: TextStyle(color: Color(0xFF626F47), fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8C8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8F8962)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal: ${_getDisplayDate()}',
                      style: const TextStyle(
                        color: Color(0xFF626F47),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Isi Pengumuman:',
                      style: TextStyle(
                        color: Color(0xFF626F47),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pengumumanController.text.trim(),
                      style: const TextStyle(
                        color: Color(0xFF626F47),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF8F8962),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF626F47),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ya, Buat',
                style: TextStyle(
                  color: Color(0xFFF9F3D1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Pengumuman',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECE8C8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8F8962)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF626F47),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Informasi Pengumuman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF626F47),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tanggal: ${_getDisplayDate()}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF626F47),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pengumuman akan dikirim ke semua pengguna aplikasi.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF626F47)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Input
            const Text(
              'Isi Pengumuman',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF626F47),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8F8962)),
              ),
              child: TextField(
                controller: _pengumumanController,
                maxLines: 8,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Masukkan isi pengumuman di sini..."',
                  hintStyle: TextStyle(color: Color(0xFF8F8962), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterStyle: TextStyle(color: Color(0xFF8F8962)),
                ),
                style: const TextStyle(color: Color(0xFF626F47), fontSize: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Button Buat Pengumuman
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _buatPengumuman,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF626F47),
                  disabledBackgroundColor: const Color(0xFF8F8962),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Buat Pengumuman',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF9F3D1),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
