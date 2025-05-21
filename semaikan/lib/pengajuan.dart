import 'package:flutter/material.dart';
import '/ibu hamil/laporan_ih.dart';
import '/pesantren/laporan_p.dart';

class PengajuanPage extends StatefulWidget {
  const PengajuanPage({super.key});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> {
  final judulController = TextEditingController();
  final tanggalController = TextEditingController();
  final namaController = TextEditingController();
  final jenisController = TextEditingController();
  final jumlahController = TextEditingController();
  final alasanController = TextEditingController();
  final lokasiController = TextEditingController();

  bool _isAllFilled() {
    return judulController.text.isNotEmpty &&
        tanggalController.text.isNotEmpty &&
        namaController.text.isNotEmpty &&
        jenisController.text.isNotEmpty &&
        jumlahController.text.isNotEmpty &&
        alasanController.text.isNotEmpty &&
        lokasiController.text.isNotEmpty;
  }

  void _handleSubmit() async {
    if (_isAllFilled()) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LaporanPageIH()),
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LaporanPageP()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi semua kolom terlebih dahulu."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F2DC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3E3D30)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengajuan',
          style: TextStyle(
            color: Color(0xFF3E3D30),
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            _buildTextField(
              'Judul Laporan Pengajuan',
              controller: judulController,
            ),
            _buildTextField('Tanggal Pengajuan', controller: tanggalController),
            _buildTextField(
              'Nama Penerima Bantuan',
              controller: namaController,
            ),
            _buildTextField(
              'Jenis Bantuan yang Ingin Diajukan',
              controller: jenisController,
            ),
            _buildTextField(
              'Jumlah Penerima Bantuan',
              controller: jumlahController,
            ),
            _buildTextField(
              'Alasan atau Kebutuhan Bantuan',
              controller: alasanController,
              maxLines: 3,
            ),
            _buildTextField(
              'Lokasi Distribusi Bantuan',
              controller: lokasiController,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF60623E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('KIRIM', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFD6D1A4),
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            IconButton(icon: const Icon(Icons.inventory), onPressed: () {}),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.map), onPressed: () {}),
            IconButton(icon: const Icon(Icons.folder), onPressed: () {}),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF60623E),
        child: const Icon(Icons.add, color: Color(0xFFF5F2DC)),
        onPressed: () {},
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildTextField(
    String hint, {
    int maxLines = 1,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFD6D1A4),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Color(0xFF3E3D30)),
        ),
      ),
    );
  }
}
