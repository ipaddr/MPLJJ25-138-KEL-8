import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DetailLaporanPage extends StatefulWidget {
  final Map<String, dynamic> laporanData;

  const DetailLaporanPage({super.key, required this.laporanData});

  @override
  State<DetailLaporanPage> createState() => _DetailLaporanPageState();
}

class _DetailLaporanPageState extends State<DetailLaporanPage> {
  // Variabel untuk menyimpan font
  pw.Font? kalniaBoldFont;

  @override
  void initState() {
    super.initState();
    _loadFont();
  }

  // Method untuk load font Kalnia-Bold
  Future<void> _loadFont() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/Kalnia-Bold.ttf');
      kalniaBoldFont = pw.Font.ttf(fontData);
    } catch (e) {
      print('Error loading font: $e');
      // Font akan null jika gagal load, akan menggunakan default font
    }
  }

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

              // Detail Pengajuan
              _buildDetailPengajuan(data),

              const SizedBox(height: 16),

              // Detail Distribusi (jika progress Selesai, Gagal, atau Ditolak)
              if (data['progress'] == 'Selesai' ||
                  data['progress'] == 'Gagal' ||
                  data['progress'] == 'Ditolak')
                _buildDistributionDetails(data),

              // Add spacing only if distribution details is shown
              if (data['progress'] == 'Selesai' ||
                  data['progress'] == 'Gagal' ||
                  data['progress'] == 'Ditolak')
                const SizedBox(height: 16),

              // Dokumentasi (jika ada foto dokumentasi)
              if (data['progress'] == 'Selesai' && _hasFotoDokumentasi(data))
                _buildDocumentation(data),

              // Add spacing only if documentation is shown
              if (data['progress'] == 'Selesai' && _hasFotoDokumentasi(data))
                const SizedBox(height: 16),

              // Timeline Progress - dipindah ke paling bawah
              _buildTimelineProgress(data),

              const SizedBox(height: 24),

              // Tombol Aksi - Updated dengan 2 button
              _buildActionButtons(data),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Header Card - Informasi Umum Laporan
  Widget _buildHeaderCard(Map<String, dynamic> data) {
    final judulLaporan =
        data['judul_laporan']?.toString() ?? 'Laporan Distribusi';
    final idPengajuan = data['id_pengajuan']?.toString() ?? 'Tidak Diketahui';
    final tanggalWaktu = _getTanggalWaktuPengajuan(data);

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
                  _getIconByCategory(data['kategori']),
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
                      judulLaporan,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF626F47),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID Laporan: $idPengajuan',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF626F47),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tanggal & Waktu: $tanggalWaktu',
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
    final progress = data['progress']?.toString() ?? 'Tidak Diketahui';
    final statusInfo = _getStatusInfo(progress);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusInfo['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusInfo['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(statusInfo['icon'], color: statusInfo['color'], size: 24),
          const SizedBox(width: 12),
          Text(
            'Status: $progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusInfo['color'],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Detail Pengajuan
  Widget _buildDetailPengajuan(Map<String, dynamic> data) {
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
            'Detail Pengajuan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoRow(
            'Nama Pemohon',
            data['nama_pemohon']?.toString() ?? 'Tidak Diketahui',
          ),
          _buildInfoRow(
            'Email Pemohon',
            data['email_pemohon']?.toString() ?? 'Tidak Diketahui',
          ),
          _buildInfoRow(
            'Nama Penerima',
            data['nama_penerima']?.toString() ?? 'Tidak Diketahui',
          ),
          _buildInfoRow(
            'Jenis Bantuan',
            data['jenis_bantuan']?.toString() ?? 'Tidak Diketahui',
          ),
          _buildInfoRow(
            'Jumlah Penerima',
            '${data['jumlah_penerima']?.toString() ?? '0'} porsi',
          ),
          _buildInfoRow(
            'Kategori',
            data['kategori']?.toString() ?? 'Tidak Diketahui',
          ),
          _buildInfoRow('Alamat', _getAddress(data)),
          _buildInfoRow('Koordinat', _getKoordinat(data)),

          const SizedBox(height: 8),
          const Text(
            'Alasan Kebutuhan:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF626F47),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['alasan_kebutuhan']?.toString() ??
                'Tidak ada alasan yang diberikan',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF626F47),
              height: 1.4,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  // Widget Timeline Progress (Updated to show date and time)
  Widget _buildTimelineProgress(Map<String, dynamic> data) {
    final timeline = _buildTimelineData(data);

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
            'Timeline Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
          const SizedBox(height: 16),

          ...timeline.map(
            (item) => _buildTimelineItem(
              item['title']!,
              item['time']!,
              item['isCompleted'] as bool,
              item['isLast'] as bool,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Timeline Item
  Widget _buildTimelineItem(
    String title,
    String time,
    bool isCompleted,
    bool isLast,
  ) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color:
                    isCompleted
                        ? const Color(0xFF626F47)
                        : const Color(0xFFD8D1A8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF626F47), width: 2),
              ),
              child:
                  isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color:
                    isCompleted
                        ? const Color(0xFF626F47)
                        : const Color(0xFFD8D1A8),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color:
                      isCompleted
                          ? const Color(0xFF626F47)
                          : const Color(0xFF8F8962),
                ),
              ),
              if (time.isNotEmpty && isCompleted)
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8F8962),
                  ),
                ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // Widget Detail Distribusi (untuk progress Selesai, Gagal, atau Ditolak)
  Widget _buildDistributionDetails(Map<String, dynamic> data) {
    final progress = data['progress']?.toString();
    final distributionData = data['distribusi_data'] as Map<String, dynamic>?;

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
          Text(
            progress == 'Selesai'
                ? 'Detail Distribusi'
                : progress == 'Ditolak'
                ? 'Detail Penolakan'
                : 'Detail Kegagalan',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
          const SizedBox(height: 12),

          if (progress == 'Selesai' && distributionData != null) ...[
            _buildInfoRow(
              'Penerima di Lapangan',
              distributionData['nama_penerima_lapangan']?.toString() ??
                  'Tidak Diketahui',
            ),
            _buildInfoRow(
              'Waktu Selesai',
              _formatTanggalWaktuIndonesia(
                distributionData['waktu_selesai']?.toString() ?? '',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kendala Lapangan:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF626F47),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              distributionData['kendala_lapangan']?.toString() ??
                  'Tidak ada kendala',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF626F47),
                height: 1.4,
              ),
              textAlign: TextAlign.justify,
            ),
          ],

          if (progress == 'Gagal') ...[
            const Text(
              'Alasan Kegagalan:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF626F47),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['reason_gagal']?.toString() ??
                  'Tidak ada alasan yang diberikan',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.justify,
            ),
          ],

          if (progress == 'Ditolak') ...[
            const Text(
              'Alasan Penolakan:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF626F47),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['alasan_ditolak']?.toString() ??
                  'Tidak ada alasan penolakan yang diberikan',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ],
      ),
    );
  }

  // Widget Dokumentasi
  Widget _buildDocumentation(Map<String, dynamic> data) {
    final distributionData = data['distribusi_data'] as Map<String, dynamic>?;
    final fotoDokumentasi =
        distributionData?['foto_dokumentasi'] as List<dynamic>?;

    if (fotoDokumentasi == null || fotoDokumentasi.isEmpty) {
      return const SizedBox.shrink();
    }

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

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: fotoDokumentasi.length,
            itemBuilder: (context, index) {
              final base64String = fotoDokumentasi[index].toString();

              try {
                final imageBytes = base64Decode(base64String);
                return GestureDetector(
                  onTap: () => _showImageDialog(imageBytes),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF626F47).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFECE8C8),
                            child: const Icon(
                              Icons.broken_image,
                              color: Color(0xFF626F47),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              } catch (e) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE8C8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF626F47).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.broken_image,
                    color: Color(0xFF626F47),
                  ),
                );
              }
            },
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

  // Widget Tombol Aksi - Updated dengan 2 button (Print dan Save PDF)
  Widget _buildActionButtons(Map<String, dynamic> data) {
    return Column(
      children: [
        // Button Print Laporan
        SizedBox(
          width: double.infinity,
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

        const SizedBox(height: 12),

        // Button Simpan sebagai PDF
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _savePdfToDevice(data);
            },
            icon: const Icon(Icons.download),
            label: const Text('Simpan sebagai PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8F8962),
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

  // Helper Methods
  IconData _getIconByCategory(String? kategori) {
    switch (kategori?.toLowerCase()) {
      case 'sekolah / pesantren':
        return Icons.school;
      case 'ibu hamil / balita':
        return Icons.child_care;
      default:
        return Icons.description;
    }
  }

  Map<String, dynamic> _getStatusInfo(String progress) {
    switch (progress) {
      case 'Selesai':
        return {'color': Colors.green, 'icon': Icons.check_circle};
      case 'Gagal':
        return {'color': Colors.red, 'icon': Icons.cancel};
      case 'Dikirim':
        return {'color': Colors.purple, 'icon': Icons.local_shipping};
      case 'Disetujui':
        return {'color': Colors.blue, 'icon': Icons.verified};
      case 'Menunggu Persetujuan':
        return {'color': Colors.orange, 'icon': Icons.schedule};
      case 'Ditolak':
        return {'color': Colors.red[800]!, 'icon': Icons.block};
      default:
        return {'color': Colors.grey, 'icon': Icons.help_outline};
    }
  }

  // Updated to include time
  String _getTanggalWaktuPengajuan(Map<String, dynamic> data) {
    try {
      final waktuProgress = data['waktu_progress'] as Map<String, dynamic>?;
      final waktuPengajuan = waktuProgress?['waktu_pengajuan']?.toString();

      if (waktuPengajuan != null && waktuPengajuan.isNotEmpty) {
        return _formatTanggalWaktuIndonesia(waktuPengajuan);
      }
    } catch (e) {
      print('Error getting tanggal waktu pengajuan: $e');
    }
    return 'Tanggal & Waktu Tidak Diketahui';
  }

  String _getAddress(Map<String, dynamic> data) {
    try {
      final lokasiDistribusi =
          data['lokasi_distribusi'] as Map<String, dynamic>?;
      return lokasiDistribusi?['address']?.toString() ??
          'Alamat Tidak Diketahui';
    } catch (e) {
      return 'Alamat Tidak Diketahui';
    }
  }

  String _getKoordinat(Map<String, dynamic> data) {
    try {
      final lokasiDistribusi =
          data['lokasi_distribusi'] as Map<String, dynamic>?;
      final koordinat = lokasiDistribusi?['koordinat']?.toString();
      return koordinat ?? 'Koordinat Tidak Diketahui';
    } catch (e) {
      return 'Koordinat Tidak Diketahui';
    }
  }

  List<Map<String, dynamic>> _buildTimelineData(Map<String, dynamic> data) {
    final waktuProgress = data['waktu_progress'] as Map<String, dynamic>?;
    final currentProgress = data['progress']?.toString() ?? '';

    List<Map<String, dynamic>> timeline = [];

    // Jika status gagal, buat timeline berdasarkan progress yang sudah tercapai
    if (currentProgress == 'Gagal') {
      // Selalu tambahkan pengajuan
      timeline.add({
        'title': 'Pengajuan Dibuat',
        'time': _formatTanggalWaktuIndonesia(
          waktuProgress?['waktu_pengajuan']?.toString() ?? '',
        ),
        'isCompleted': true,
        'isLast': false,
      });

      // Tambahkan tahapan yang sudah dilalui sebelum gagal
      if (waktuProgress?['Disetujui'] != null) {
        timeline.add({
          'title': 'Disetujui',
          'time': _formatTanggalWaktuIndonesia(
            waktuProgress!['Disetujui'].toString(),
          ),
          'isCompleted': true,
          'isLast': false,
        });
      }

      if (waktuProgress?['Dikirim'] != null) {
        timeline.add({
          'title': 'Dikirim',
          'time': _formatTanggalWaktuIndonesia(
            waktuProgress!['Dikirim'].toString(),
          ),
          'isCompleted': true,
          'isLast': false,
        });
      }

      // Tambahkan status gagal di akhir
      timeline.add({
        'title': 'Gagal',
        'time': _formatTanggalWaktuIndonesia(
          waktuProgress?['Gagal']?.toString() ?? '',
        ),
        'isCompleted': true,
        'isLast': true,
      });

      return timeline;
    }

    // Jika status ditolak, buat timeline khusus untuk penolakan
    if (currentProgress == 'Ditolak') {
      // Selalu tambahkan pengajuan
      timeline.add({
        'title': 'Pengajuan Dibuat',
        'time': _formatTanggalWaktuIndonesia(
          waktuProgress?['waktu_pengajuan']?.toString() ?? '',
        ),
        'isCompleted': true,
        'isLast': false,
      });

      // Tambahkan status ditolak
      timeline.add({
        'title': 'Ditolak',
        'time': _formatTanggalWaktuIndonesia(
          waktuProgress?['Ditolak']?.toString() ?? '',
        ),
        'isCompleted': true,
        'isLast': true,
      });

      return timeline;
    }

    // Urutan normal untuk status selain gagal dan ditolak
    final normalOrder = ['waktu_pengajuan', 'Disetujui', 'Dikirim', 'Selesai'];
    final progressLabels = {
      'waktu_pengajuan': 'Pengajuan Dibuat',
      'Disetujui': 'Disetujui',
      'Dikirim': 'Dikirim',
      'Selesai': 'Selesai',
    };

    for (int i = 0; i < normalOrder.length; i++) {
      final key = normalOrder[i];
      final label = progressLabels[key]!;
      final time = waktuProgress?[key]?.toString() ?? '';
      final isCompleted = _isProgressCompleted(currentProgress, key);
      final isLast = i == normalOrder.length - 1;

      timeline.add({
        'title': label,
        'time': isCompleted ? _formatTanggalWaktuIndonesia(time) : '',
        'isCompleted': isCompleted,
        'isLast': isLast,
      });
    }

    return timeline;
  }

  bool _isProgressCompleted(String currentProgress, String checkProgress) {
    final progressOrder = [
      'waktu_pengajuan',
      'Disetujui',
      'Dikirim',
      'Selesai',
    ];

    // Untuk status gagal, logika berbeda (sudah ditangani di _buildTimelineData)
    if (currentProgress == 'Gagal') {
      return false; // Tidak digunakan untuk gagal
    }

    // Pengajuan Dibuat selalu completed untuk semua status
    if (checkProgress == 'waktu_pengajuan') {
      return true;
    }

    final currentIndex = progressOrder.indexOf(currentProgress);
    final checkIndex = progressOrder.indexOf(checkProgress);

    // Jika currentProgress tidak ditemukan dalam progressOrder, berarti masih "Menunggu Persetujuan"
    if (currentIndex == -1) {
      return checkProgress ==
          'waktu_pengajuan'; // Hanya pengajuan yang completed
    }

    return checkIndex <= currentIndex;
  }

  bool _hasFotoDokumentasi(Map<String, dynamic> data) {
    try {
      final distributionData = data['distribusi_data'] as Map<String, dynamic>?;
      final fotoDokumentasi =
          distributionData?['foto_dokumentasi'] as List<dynamic>?;
      return fotoDokumentasi != null && fotoDokumentasi.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  DateTime? _parseWaktuPengajuan(String waktuPengajuan) {
    try {
      final parts = waktuPengajuan.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0];
        final timePart = parts[1];

        final dateComponents = datePart.split('/');
        final timeComponents = timePart.split(':');

        if (dateComponents.length == 3 && timeComponents.length == 2) {
          final day = int.parse(dateComponents[0]);
          final month = int.parse(dateComponents[1]);
          final year = int.parse(dateComponents[2]);
          final hour = int.parse(timeComponents[0]);
          final minute = int.parse(timeComponents[1]);

          return DateTime(year, month, day, hour, minute);
        }
      }
    } catch (e) {
      print('Error parsing waktu pengajuan: $e');
    }
    return null;
  }

  // Updated to format both date and time in Indonesian
  String _formatTanggalWaktuIndonesia(String waktuPengajuan) {
    if (waktuPengajuan.isEmpty) return '';

    try {
      final dateTime = _parseWaktuPengajuan(waktuPengajuan);
      if (dateTime != null) {
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

        final formattedTime =
            '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        return '${dateTime.day} ${months[dateTime.month]} ${dateTime.year}, $formattedTime WIB';
      }
    } catch (e) {
      print('Error formatting tanggal waktu Indonesia: $e');
    }
    return waktuPengajuan;
  }

  void _showImageDialog(List<int> imageBytes) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Image.memory(
                  Uint8List.fromList(imageBytes),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
    );
  }

  // Helper function untuk mendapatkan jumlah foto dokumentasi
  int _getFotoDokumentasiCount(Map<String, dynamic> data) {
    try {
      final distributionData = data['distribusi_data'] as Map<String, dynamic>?;
      final fotoDokumentasi =
          distributionData?['foto_dokumentasi'] as List<dynamic>?;
      return fotoDokumentasi?.length ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Helper function untuk format tanggal saat ini
  String _getCurrentDate() {
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
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return '${now.day} ${months[now.month]} ${now.year}, $formattedTime WIB';
  }

  // Helper function untuk timeline PDF (Updated with time)
  pw.Widget _buildPdfTimelineSection(Map<String, dynamic> data) {
    final timeline = _buildTimelineData(data);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TIMELINE PROGRESS',
            style: pw.TextStyle(fontSize: 14, font: kalniaBoldFont),
          ),
          pw.SizedBox(height: 12),
          ...timeline.map(
            (item) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 15,
                    height: 15,
                    decoration: pw.BoxDecoration(
                      color:
                          (item['isCompleted'] as bool)
                              ? PdfColors.green
                              : PdfColors.grey300,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(7.5),
                      ),
                    ),
                    child:
                        (item['isCompleted'] as bool)
                            ? pw.Center(
                              child: pw.Text(
                                '✓',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.white,
                                ),
                              ),
                            )
                            : null,
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item['title']!,
                          style: pw.TextStyle(
                            fontSize: 11,
                            font: kalniaBoldFont,
                            color:
                                (item['isCompleted'] as bool)
                                    ? PdfColors.black
                                    : PdfColors.grey600,
                          ),
                        ),
                        if (item['time']!.isNotEmpty &&
                            (item['isCompleted'] as bool))
                          pw.Text(
                            item['time']!,
                            style: pw.TextStyle(
                              fontSize: 9,
                              font: kalniaBoldFont,
                              color: PdfColors.grey600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function untuk distribution section PDF
  pw.Widget _buildPdfDistributionSection(Map<String, dynamic> data) {
    final progress = data['progress']?.toString();
    final distributionData = data['distribusi_data'] as Map<String, dynamic>?;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color:
            progress == 'Gagal' || progress == 'Ditolak'
                ? PdfColors.red50
                : PdfColors.green50,
        border: pw.Border.all(
          color:
              progress == 'Gagal' || progress == 'Ditolak'
                  ? PdfColors.red300
                  : PdfColors.green300,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            progress == 'Selesai'
                ? 'DETAIL DISTRIBUSI'
                : progress == 'Ditolak'
                ? 'DETAIL PENOLAKAN'
                : 'DETAIL KEGAGALAN',
            style: pw.TextStyle(fontSize: 14, font: kalniaBoldFont),
          ),
          pw.SizedBox(height: 8),

          if (progress == 'Selesai' && distributionData != null) ...[
            pw.Text(
              'Penerima di Lapangan: ${distributionData['nama_penerima_lapangan']?.toString() ?? 'Tidak Diketahui'}',
              style: pw.TextStyle(fontSize: 11, font: kalniaBoldFont),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Waktu Selesai: ${_formatTanggalWaktuIndonesia(distributionData['waktu_selesai']?.toString() ?? '')}',
              style: pw.TextStyle(fontSize: 11, font: kalniaBoldFont),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Kendala Lapangan:',
              style: pw.TextStyle(fontSize: 11, font: kalniaBoldFont),
            ),
            pw.Text(
              distributionData['kendala_lapangan']?.toString() ??
                  'Tidak ada kendala',
              style: pw.TextStyle(fontSize: 10, font: kalniaBoldFont),
            ),
          ],

          if (progress == 'Gagal') ...[
            pw.Text(
              'Alasan Kegagalan:',
              style: pw.TextStyle(fontSize: 11, font: kalniaBoldFont),
            ),
            pw.Text(
              data['reason_gagal']?.toString() ??
                  'Tidak ada alasan yang diberikan',
              style: pw.TextStyle(
                fontSize: 10,
                font: kalniaBoldFont,
                color: PdfColors.red700,
              ),
            ),
          ],

          if (progress == 'Ditolak') ...[
            pw.Text(
              'Alasan Penolakan:',
              style: pw.TextStyle(fontSize: 11, font: kalniaBoldFont),
            ),
            pw.Text(
              data['alasan_ditolak']?.toString() ??
                  'Tidak ada alasan penolakan yang diberikan',
              style: pw.TextStyle(
                fontSize: 10,
                font: kalniaBoldFont,
                color: PdfColors.red700,
              ),
            ),
          ],

          // Tambahkan informasi foto dokumentasi jika ada
          if (progress == 'Selesai' && _hasFotoDokumentasi(data)) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Foto Dokumentasi: ${_getFotoDokumentasiCount(data)} foto tersimpan',
              style: pw.TextStyle(
                fontSize: 10,
                font: kalniaBoldFont,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Method untuk request permission storage
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt <= 29) {
        final permission = await Permission.storage.request();
        return permission == PermissionStatus.granted;
      } else {
        // Android 11+ uses different permission
        return true; // Untuk Android 11+, kita akan menggunakan download folder
      }
    }
    return true; // iOS tidak memerlukan permission khusus untuk menyimpan file
  }

  // Method untuk save PDF ke device - NEW METHOD
  Future<void> _savePdfToDevice(Map<String, dynamic> data) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Menyimpan PDF..."),
                ],
              ),
            ),
          );
        },
      );

      // Request storage permission
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar(
          'Izin akses storage diperlukan untuk menyimpan file',
          isError: true,
        );
        return;
      }

      // Generate PDF
      final pdf = await _generatePdf(data);
      final pdfBytes = await pdf.save();

      // Get directory for saving
      Directory? directory;
      String fileName =
          'Laporan_${data['id_pengajuan'] ?? 'Distribusi'}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (Platform.isAndroid) {
        // Try to save to Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);

        Navigator.pop(context); // Close loading dialog

        // Show success message with file location
        _showSnackBar('PDF berhasil disimpan di: ${file.path}');

        // Option to share the file
        _showShareDialog(file.path, data);
      } else {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar('Gagal mendapatkan direktori penyimpanan', isError: true);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error saving PDF: $e');
      _showSnackBar('Gagal menyimpan PDF: $e', isError: true);
    }
  }

  // Method untuk show snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Method untuk show share dialog
  void _showShareDialog(String filePath, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PDF Tersimpan'),
          content: Text(
            'PDF laporan berhasil disimpan.\n\nApakah Anda ingin membagikan file ini?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _shareFile(filePath, data);
              },
              child: const Text('Bagikan'),
            ),
          ],
        );
      },
    );
  }

  // Method untuk share file
  Future<void> _shareFile(String filePath, Map<String, dynamic> data) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Laporan Distribusi - ${data['judul_laporan'] ?? 'Semaikan'}',
        subject: 'Laporan Distribusi PDF',
      );
    } catch (e) {
      print('Error sharing file: $e');
      _showSnackBar('Gagal membagikan file: $e', isError: true);
    }
  }

  // Fungsi Print
  void _showPrintPreview(Map<String, dynamic> data) async {
    final pdf = await _generatePdf(data);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return pdf.save();
      },
      name: 'Laporan_${data['id_pengajuan'] ?? 'Distribusi'}.pdf',
    );
  }

  Future<pw.Document> _generatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header laporan
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LAPORAN DISTRIBUSI MAKANAN',
                    style: pw.TextStyle(fontSize: 20, font: kalniaBoldFont),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Sistem Distribusi Makanan Semaikan',
                    style: pw.TextStyle(
                      fontSize: 12,
                      font: kalniaBoldFont,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Informasi Laporan (Updated to include date and time)
            _buildPdfInfoSection('INFORMASI LAPORAN', [
              {
                'Judul Laporan':
                    data['judul_laporan']?.toString() ?? 'Tidak Diketahui',
              },
              {
                'ID Laporan':
                    data['id_pengajuan']?.toString() ?? 'Tidak Diketahui',
              },
              {'Tanggal & Waktu Pengajuan': _getTanggalWaktuPengajuan(data)},
              {'Status': data['progress']?.toString() ?? 'Tidak Diketahui'},
              {'Kategori': data['kategori']?.toString() ?? 'Tidak Diketahui'},
            ]),
            pw.SizedBox(height: 15),

            // Detail Pengajuan (All information included)
            _buildPdfInfoSection('DETAIL PENGAJUAN', [
              {
                'Nama Pemohon':
                    data['nama_pemohon']?.toString() ?? 'Tidak Diketahui',
              },
              {
                'Email Pemohon':
                    data['email_pemohon']?.toString() ?? 'Tidak Diketahui',
              },
              {
                'Nama Penerima':
                    data['nama_penerima']?.toString() ?? 'Tidak Diketahui',
              },
              {
                'Jenis Bantuan':
                    data['jenis_bantuan']?.toString() ?? 'Tidak Diketahui',
              },
              {
                'Jumlah Penerima':
                    '${data['jumlah_penerima']?.toString() ?? '0'} porsi',
              },
              {'Alamat': _getAddress(data)},
              {'Koordinat': _getKoordinat(data)},
            ]),
            pw.SizedBox(height: 15),

            // Alasan Kebutuhan
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ALASAN KEBUTUHAN',
                    style: pw.TextStyle(fontSize: 14, font: kalniaBoldFont),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    data['alasan_kebutuhan']?.toString() ??
                        'Tidak ada alasan yang diberikan',
                    style: pw.TextStyle(fontSize: 11, font: kalniaBoldFont),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            // Timeline Progress (Updated with time)
            _buildPdfTimelineSection(data),
            pw.SizedBox(height: 15),

            // Detail Distribusi (jika ada)
            if (data['progress'] == 'Selesai' ||
                data['progress'] == 'Gagal' ||
                data['progress'] == 'Ditolak')
              _buildPdfDistributionSection(data),

            // Footer
            pw.SizedBox(height: 30),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Laporan dibuat oleh Sistem Semaikan',
                    style: pw.TextStyle(
                      fontSize: 9,
                      font: kalniaBoldFont,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Dicetak pada ${_getCurrentDate()}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      font: kalniaBoldFont,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  // Helper function untuk membuat bagian informasi di PDF (Updated dengan custom font)
  pw.Widget _buildPdfInfoSection(
    String title,
    List<Map<String, String>> items,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 14, font: kalniaBoldFont),
          ),
          pw.SizedBox(height: 8),
          ...items.map((item) {
            final entry = item.entries.first;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text(
                      '${entry.key}:',
                      style: pw.TextStyle(fontSize: 11, font: kalniaBoldFont),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      entry.value,
                      style: pw.TextStyle(fontSize: 11, font: kalniaBoldFont),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
