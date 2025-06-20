import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotifikasiActionPage extends StatefulWidget {
  const NotifikasiActionPage({super.key});

  @override
  State<NotifikasiActionPage> createState() => _NotifikasiActionPageState();
}

class _NotifikasiActionPageState extends State<NotifikasiActionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _requestList = [];
  final List<String> _processedIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final querySnapshot = await _firestore.collection('Data_Pengajuan').get();
      List<Map<String, dynamic>> pendingRequests = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final progress = data['progress'] ?? '';

        if (progress == 'Menunggu Persetujuan') {
          final namaLengkap = data['nama_pemohon'] ?? 'Tidak diketahui';
          final judulLaporan = data['judul_laporan'] ?? 'Tidak ada judul';
          final waktuProgress = data['waktu_progress'] as Map<String, dynamic>?;
          final waktuPengajuan = waktuProgress?['waktu_pengajuan'] ?? '';

          pendingRequests.add({
            'id': doc.id,
            'name': namaLengkap,
            'judul_laporan': judulLaporan,
            'date': _formatTanggal(waktuPengajuan),
            'type': _determineType(data),
            'status': 'Pending',
            'full_data': data,
          });
        }
      }

      // Sort by most recent first
      pendingRequests.sort((a, b) {
        final aTime = _parseWaktuPengajuan(
          a['full_data']['waktu_progress']?['waktu_pengajuan'] ?? '',
        );
        final bTime = _parseWaktuPengajuan(
          b['full_data']['waktu_progress']?['waktu_pengajuan'] ?? '',
        );

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime);
      });

      setState(() {
        _requestList = pendingRequests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _parseWaktuPengajuan(String waktuPengajuan) {
    try {
      // Format: "13/06/2025 20:45 WIB"
      final parts = waktuPengajuan.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0]; // "13/06/2025"
        final timePart = parts[1]; // "20:45"

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

  String _formatTanggal(String waktuPengajuan) {
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

        return '${dateTime.day} ${months[dateTime.month]} ${dateTime.year}';
      }
    } catch (e) {
      print('Error formatting tanggal: $e');
    }
    return waktuPengajuan;
  }

  String _determineType(Map<String, dynamic> data) {
    final kategori = data['kategori'] ?? '';
    final jenisBantuan = data['jenis_bantuan'] ?? '';

    if (kategori.isNotEmpty) {
      return kategori;
    } else if (jenisBantuan.isNotEmpty) {
      return jenisBantuan;
    }

    return 'Distribusi';
  }

  // Show rejection reason dialog
  Future<void> _showRejectionDialog(String id) async {
    final TextEditingController reasonController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF9F3D1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Alasan Penolakan',
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
                'Silakan berikan alasan mengapa pengajuan ini ditolak:',
                style: TextStyle(color: Color(0xFF626F47), fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8F8962)),
                ),
                child: TextField(
                  controller: reasonController,
                  maxLines: 4,
                  maxLength: 250,
                  decoration: const InputDecoration(
                    hintText: 'Input alasan penolakan disini...',
                    hintStyle: TextStyle(
                      color: Color(0xFF8F8962),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    counterStyle: TextStyle(color: Color(0xFF8F8962)),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF626F47),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF8F8962),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alasan penolakan tidak boleh kosong!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _processRequest(
                  id,
                  'reject',
                  rejectionReason: reasonController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tolak',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRequest(
    String id,
    String action, {
    String? rejectionReason,
  }) async {
    try {
      String newStatus;
      String message;
      String timestampKey;

      if (action == 'approve') {
        newStatus = 'Disetujui';
        message = 'Pengajuan berhasil disetujui';
        timestampKey = 'Disetujui';
      } else {
        newStatus = 'Ditolak';
        message = 'Pengajuan berhasil ditolak';
        timestampKey = 'Ditolak';
      }

      // Create timestamp
      String timestamp =
          '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB';

      // Prepare update data
      Map<String, dynamic> updateData = {
        'progress': newStatus,
        'waktu_progress.$timestampKey': timestamp,
      };

      // Add rejection reason if this is a rejection
      if (action == 'reject' && rejectionReason != null) {
        updateData['alasan_ditolak'] = rejectionReason;
      }

      // Get document data to extract user_id and id_pengajuan
      DocumentSnapshot docSnapshot =
          await _firestore.collection('Data_Pengajuan').doc(id).get();

      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }

      Map<String, dynamic> docData = docSnapshot.data() as Map<String, dynamic>;
      String? userId = docData['user_id'];
      String? idPengajuan =
          docData['id_pengajuan'] ??
          id; // Fallback to document ID if id_pengajuan not found

      // Update main collection (Data_Pengajuan)
      await _firestore.collection('Data_Pengajuan').doc(id).update(updateData);

      // Update user's subcollection if user_id exists
      if (userId != null && userId.isNotEmpty) {
        try {
          await _firestore
              .collection('Account_Storage')
              .doc(userId)
              .collection('Data_Pengajuan')
              .doc(idPengajuan)
              .update(updateData);

          print(
            'Successfully updated user subcollection for user: $userId, doc: $idPengajuan',
          );
        } catch (e) {
          print('Error updating user subcollection: $e');
          // Continue execution even if subcollection update fails
        }
      } else {
        print('Warning: user_id not found in document $id');
      }

      // Update local state
      setState(() {
        final index = _requestList.indexWhere((request) => request['id'] == id);
        if (index != -1) {
          _requestList[index]['status'] = newStatus;
          _processedIds.add(id);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
      }

      // Refresh data setelah 1 detik
      Future.delayed(const Duration(seconds: 1), () {
        _loadRequests();
      });
    } catch (e) {
      print('Error processing request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses permintaan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDetailDialog(Map<String, dynamic> requestData) {
    final data = requestData['full_data'] as Map<String, dynamic>;
    final lokasiDistribusi = data['lokasi_distribusi'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF626F47),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Detail Pengajuan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem(
                          'Judul Laporan',
                          data['judul_laporan'] ?? '-',
                        ),
                        _buildDetailItem(
                          'Nama Lengkap',
                          data['nama_pemohon'] ?? '-',
                        ),
                        _buildDetailItem(
                          'Email Pemohon',
                          data['email_pemohon'] ?? '-',
                        ),
                        _buildDetailItem('Kategori', data['kategori'] ?? '-'),
                        _buildDetailItem(
                          'Jenis Bantuan',
                          data['jenis_bantuan'] ?? '-',
                        ),
                        _buildDetailItem(
                          'Jumlah Penerima',
                          data['jumlah_penerima']?.toString() ?? '-',
                        ),
                        _buildDetailItem(
                          'Nama Penerima',
                          data['nama_penerima'] ?? '-',
                        ),
                        _buildDetailItem(
                          'Lokasi Distribusi',
                          lokasiDistribusi?['address'] ?? '-',
                        ),
                        _buildDetailItem(
                          'Alasan Kebutuhan',
                          data['alasan_kebutuhan'] ?? '-',
                          isLongText: true,
                        ),
                        // Debug info (dapat dihapus di production)
                        _buildDetailItem('User ID', data['user_id'] ?? '-'),
                        _buildDetailItem(
                          'ID Pengajuan',
                          data['id_pengajuan'] ?? '-',
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showRejectionDialog(requestData['id']);
                          },
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF626F47),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _processRequest(requestData['id'], 'approve');
                          },
                          child: const Text('Setujui'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool isLongText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F3D1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF8F8962).withOpacity(0.3),
              ),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF626F47)),
              maxLines: isLongText ? null : 1,
              overflow: isLongText ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Konfirmasi Laporan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF626F47)),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _requestList.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_alt, size: 64, color: Color(0xFF8F8962)),
                    SizedBox(height: 16),
                    Text(
                      'Tidak ada permintaan saat ini',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF626F47),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Semua permintaan telah diproses',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8F8962)),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadRequests,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requestList.length,
                  itemBuilder: (context, index) {
                    final request = _requestList[index];
                    final bool isProcessed = _processedIds.contains(
                      request['id'],
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF626F47).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header dengan nama dan tanggal
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF626F47),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${request['judul_laporan']} • ${request['date']}',
                                        style: const TextStyle(
                                          color: Color(0xFF626F47),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isProcessed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          request['status'] == 'Disetujui'
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            request['status'] == 'Disetujui'
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                    child: Text(
                                      request['status'],
                                      style: TextStyle(
                                        color:
                                            request['status'] == 'Disetujui'
                                                ? Colors.green
                                                : Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Action buttons
                            if (!isProcessed) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFF626F47),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          () => _showDetailDialog(request),
                                      child: const Text(
                                        'Detail',
                                        style: TextStyle(
                                          color: Color(0xFF626F47),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          () => _showRejectionDialog(
                                            request['id'],
                                          ),
                                      child: const Text('Tolak'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF626F47,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          () => _processRequest(
                                            request['id'],
                                            'approve',
                                          ),
                                      child: const Text('Setujui'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
