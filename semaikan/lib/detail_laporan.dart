import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class DetailLaporanPage extends StatefulWidget {
  final Map<String, dynamic> laporanData;

  const DetailLaporanPage({super.key, required this.laporanData});

  @override
  State<DetailLaporanPage> createState() => _DetailLaporanPageState();
}

class _DetailLaporanPageState extends State<DetailLaporanPage> {
  @override
  Widget build(BuildContext context) {
    final data = widget.laporanData;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F3D1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF626F47)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Detail Laporan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Informasi Laporan
              _buildHeaderCard(data),

              const SizedBox(height: 16),

              // Status Laporan
              _buildStatusCard(data),

              const SizedBox(height: 16),

              // Detail Distribusi
              _buildDistributionDetails(data),

              const SizedBox(height: 16),

              // Informasi Penerima
              _buildRecipientInfo(data),

              const SizedBox(height: 16),

              // Dokumentasi
              _buildDocumentation(data),

              const SizedBox(height: 16),

              // Keterangan Tambahan
              _buildAdditionalNotes(data),

              const SizedBox(height: 24),

              // Tombol Aksi
              _buildActionButtons(data),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Header Card - Informasi Umum Laporan
  Widget _buildHeaderCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF626F47).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8C8),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _getIconByType(data['type']),
                  color: const Color(0xFF626F47),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Laporan Distribusi',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF626F47),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID Laporan: ${data['id'] ?? 'LP001'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF626F47),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tanggal: ${data['date'] ?? '22 April 2025'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF626F47),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Status Card
  Widget _buildStatusCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'Menunggu';
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.hourglass_empty;

    switch (status.toLowerCase()) {
      case 'berhasil':
      case 'selesai':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'gagal':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'tertunda':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Text(
            'Status: $status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Detail Distribusi
  Widget _buildDistributionDetails(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF626F47).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Distribusi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
          const SizedBox(height: 12),

          // Grid untuk detail distribusi
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildDetailItem(
                'Jumlah Makanan',
                data['jumlahMakanan']?.toString() ?? '250 porsi',
              ),
              _buildDetailItem(
                'Jenis Makanan',
                data['jenisMakanan']?.toString() ?? 'Makanan Bergizi',
              ),
              _buildDetailItem(
                'Lokasi',
                data['lokasi']?.toString() ?? 'SMAN 1 Kota Padang',
              ),
              _buildDetailItem(
                'Waktu Distribusi',
                data['waktuDistribusi']?.toString() ?? '08:00 - 12:00',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Detail Item
  Widget _buildDetailItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFECE8C8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF626F47),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF626F47),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Informasi Penerima
  Widget _buildRecipientInfo(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF626F47).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Penerima',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
          const SizedBox(height: 12),

          // Data penerima
          _buildInfoRow(
            'Jumlah Penerima',
            data['jumlahPenerima']?.toString() ?? '150 orang',
          ),
          _buildInfoRow(
            'Kategori',
            data['kategori']?.toString() ?? 'Siswa Sekolah',
          ),
          _buildInfoRow(
            'Kondisi Penerima',
            data['kondisiPenerima']?.toString() ?? 'Sehat dan aktif',
          ),
          _buildInfoRow(
            'Koordinator',
            data['koordinator']?.toString() ?? 'Bpk. Ahmad',
          ),
          _buildInfoRow(
            'No. Telepon',
            data['noTelepon']?.toString() ?? '081234567890',
          ),
        ],
      ),
    );
  }

  // Widget Info Row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF626F47),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF626F47))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF626F47)),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Dokumentasi
  Widget _buildDocumentation(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF626F47).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dokumentasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
          const SizedBox(height: 12),

          // Placeholder untuk foto-foto dokumentasi
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 3, // Simulasi 3 foto
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8C8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF626F47).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image, color: Color(0xFF626F47), size: 32),
                    const SizedBox(height: 4),
                    Text(
                      'Foto ${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF626F47),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget Keterangan Tambahan
  Widget _buildAdditionalNotes(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF626F47).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keterangan Tambahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data['keterangan']?.toString() ??
                'Distribusi makanan bergizi untuk siswa SMAN 1 Kota Padang berjalan lancar. Semua siswa mendapatkan porsi yang sama dan terlihat antusias menerima makanan. Tidak ada kendala berarti selama proses distribusi. Tim distribusi bekerja dengan baik dan koordinasi dengan pihak sekolah sangat baik.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF626F47),
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  // Widget Tombol Aksi
  Widget _buildActionButtons(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? 'menunggu';

    // Jika status sudah selesai, tampilkan tombol download atau print
    if (status == 'berhasil' || status == 'selesai') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _generateAndDownloadPDF(data);
              },
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF626F47),
                side: const BorderSide(color: Color(0xFF626F47)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showPrintPreview(data);
              },
              icon: const Icon(Icons.print),
              label: const Text('Print Laporan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF626F47),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    // Jika status menunggu, tampilkan tombol approve/reject
    if (status == 'menunggu' || status == 'tertunda') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _showRejectDialog();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Tolak Laporan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _approveLaporan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF626F47),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Setujui Laporan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    // Default: hanya tombol kembali
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF626F47),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text(
          'Kembali',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Function untuk mendapatkan ikon berdasarkan tipe
  IconData _getIconByType(String? type) {
    switch (type?.toLowerCase()) {
      case 'sekolah':
        return Icons.school;
      case 'pesantren':
        return Icons.mosque;
      case 'ibu hamil':
      case 'balita':
        return Icons.child_care;
      default:
        return Icons.description;
    }
  }

  // Function untuk approve laporan
  void _approveLaporan() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text(
              'Apakah Anda yakin ingin menyetujui laporan ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Laporan berhasil disetujui'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Update status dan kembali ke halaman sebelumnya
                  setState(() {
                    widget.laporanData['status'] = 'Berhasil';
                  });
                },
                child: const Text('Setujui'),
              ),
            ],
          ),
    );
  }

  // Function untuk reject laporan
  void _showRejectDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tolak Laporan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Berikan alasan penolakan:'),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan alasan penolakan...',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Laporan ditolak'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  // Update status dan kembali ke halaman sebelumnya
                  setState(() {
                    widget.laporanData['status'] = 'Gagal';
                    widget.laporanData['alasanPenolakan'] =
                        reasonController.text;
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Tolak'),
              ),
            ],
          ),
    );
  }

  // Fungsi untuk membuat PDF dan menyimpannya
  Future<void> _generateAndDownloadPDF(Map<String, dynamic> data) async {
    try {
      // Membuat dokumen PDF menggunakan fungsi helper
      final pdf = await _generatePdf(data);

      // Mendapatkan direktori untuk menyimpan file
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/laporan_${data['id'] ?? 'distribusi'}.pdf',
      );

      // Menyimpan file PDF
      await file.writeAsBytes(await pdf.save());

      // Berbagi file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Laporan Distribusi ${data['id'] ?? ''}',
        subject: 'Laporan Distribusi Makanan',
      );

      // Menampilkan notifikasi berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF berhasil dibuat dan siap untuk dibagikan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi untuk menampilkan preview sebelum print
  void _showPrintPreview(Map<String, dynamic> data) async {
    final pdf = await _generatePdf(data);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return pdf.save();
      },
      name: 'Laporan_${data['id'] ?? 'Distribusi'}.pdf',
    );

    // Tambahkan tombol untuk save PDF setelah preview
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ingin menyimpan dokumen PDF?'),
        action: SnackBarAction(
          label: 'Simpan',
          onPressed: () async {
            // Simpan PDF dan bagikan
            final bytes = await pdf.save();
            final directory = await getApplicationDocumentsDirectory();
            final file = File(
              '${directory.path}/laporan_${data['id'] ?? 'distribusi'}.pdf',
            );
            await file.writeAsBytes(bytes);

            // Bagikan file
            await Share.shareXFiles(
              [XFile(file.path)],
              text: 'Laporan Distribusi ${data['id'] ?? ''}',
              subject: 'Laporan Distribusi Makanan',
            );
          },
        ),
        duration: const Duration(seconds: 10),
        backgroundColor: const Color(0xFF626F47),
      ),
    );
  }

  // Fungsi untuk menghasilkan dokumen PDF
  Future<pw.Document> _generatePdf(Map<String, dynamic> data) async {
    // Membuat dokumen PDF
    final pdf = pw.Document();

    // Menambahkan konten ke PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header laporan
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Distribusi Makanan',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Informasi laporan
            _buildPdfInfoSection('Informasi Laporan', [
              {'Judul': data['title'] ?? 'Laporan Distribusi'},
              {'ID Laporan': data['id'] ?? 'LP001'},
              {'Tanggal': data['date'] ?? '22 April 2025'},
              {'Status': data['status'] ?? 'Menunggu'},
            ]),
            pw.SizedBox(height: 20),

            // Detail distribusi
            _buildPdfInfoSection('Detail Distribusi', [
              {
                'Jumlah Makanan':
                    data['jumlahMakanan']?.toString() ?? '250 porsi',
              },
              {
                'Jenis Makanan':
                    data['jenisMakanan']?.toString() ?? 'Makanan Bergizi',
              },
              {'Lokasi': data['lokasi']?.toString() ?? 'SMAN 1 Kota Padang'},
              {
                'Waktu Distribusi':
                    data['waktuDistribusi']?.toString() ?? '08:00 - 12:00',
              },
            ]),
            pw.SizedBox(height: 20),

            // Informasi Penerima
            _buildPdfInfoSection('Informasi Penerima', [
              {
                'Jumlah Penerima':
                    data['jumlahPenerima']?.toString() ?? '150 orang',
              },
              {'Kategori': data['kategori']?.toString() ?? 'Siswa Sekolah'},
              {
                'Kondisi Penerima':
                    data['kondisiPenerima']?.toString() ?? 'Sehat dan aktif',
              },
              {'Koordinator': data['koordinator']?.toString() ?? 'Bpk. Ahmad'},
              {'No. Telepon': data['noTelepon']?.toString() ?? '081234567890'},
            ]),
            pw.SizedBox(height: 20),

            // Keterangan Tambahan
            pw.Header(level: 1, text: 'Keterangan Tambahan'),
            pw.Paragraph(
              text:
                  data['keterangan']?.toString() ??
                  'Distribusi makanan bergizi untuk siswa SMAN 1 Kota Padang berjalan lancar. Semua siswa mendapatkan porsi yang sama dan terlihat antusias menerima makanan. Tidak ada kendala berarti selama proses distribusi. Tim distribusi bekerja dengan baik dan koordinasi dengan pihak sekolah sangat baik.',
            ),
            pw.SizedBox(height: 30),

            // Footer dengan tanggal cetak
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Laporan dibuat oleh Sistem Distribusi Makanan',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Dicetak pada ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }
}

// Helper function untuk membuat bagian informasi di PDF
pw.Widget _buildPdfInfoSection(String title, List<Map<String, String>> items) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Header(level: 1, text: title),
      pw.SizedBox(height: 10),
      ...items.map((item) {
        final entry = item.entries.first;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 150,
                child: pw.Text(
                  '${entry.key}:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(child: pw.Text(entry.value)),
            ],
          ),
        );
      }),
    ],
  );
}
