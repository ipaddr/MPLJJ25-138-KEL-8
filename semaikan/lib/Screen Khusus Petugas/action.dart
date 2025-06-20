import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:semaikan/widgets/petugas_navbar.dart';
import 'package:semaikan/Screen%20Bersama/maps.dart';
import 'package:semaikan/Screen%20Khusus%20Petugas/home.dart';
import 'package:semaikan/Screen%20Khusus%20Petugas/laporan.dart';
import 'package:semaikan/Screen%20Khusus%20Petugas/distribusi.dart';

class ActionPage extends StatefulWidget {
  @override
  _ActionPageState createState() => _ActionPageState();
}

class _ActionPageState extends State<ActionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> allReports = [];
  List<Map<String, dynamic>> filteredReports = [];
  String selectedCategory = 'Semua';
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  int _currentIndex =
      4; // Index untuk action dalam navbar (floating button tidak memiliki index)
  String _accountCategory = 'petugas_distribusi';

  @override
  void initState() {
    super.initState();
    _initializeAccountCategory();
    loadAllReports();
    searchController.addListener(_filterReports);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Method untuk initialize account category
  Future<void> _initializeAccountCategory() async {
    await _loadUserData();
    _accountCategory = _accountCategory.trim();
  }

  // Mengambil account category pengguna dari Firestore
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
            _accountCategory = userData['account_category']?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      setState(() {
        _accountCategory = '';
      });
    }
  }

  String formatDisplayDate(String originalDate) {
    try {
      List<String> months = [
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

      List<String> parts = originalDate.split(' ')[0].split('/');
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);

      return '$day ${months[month]} $year';
    } catch (e) {
      return originalDate;
    }
  }

  String getCurrentTimestamp() {
    DateTime now = DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm').format(now) + ' WIB';
  }

  Future<void> loadAllReports() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot =
          await _firestore.collection('Data_Pengajuan').get();

      List<Map<String, dynamic>> reports = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['doc_id'] = doc.id;

        String progress = data['progress']?.toString() ?? '';
        print('Document ID: ${doc.id}, Progress: "$progress"'); // Debug print

        // Don't include completed reports and failed reports
        if (progress != 'Selesai' && progress != 'Gagal') {
          reports.add(data);
          print(
            'Added report: ${data['judul_laporan']} with progress: $progress',
          ); // Debug print
        }
      }

      // Sort by timestamp if available, otherwise by document creation
      reports.sort((a, b) {
        try {
          // Try to use created_at field first
          if (a['created_at'] != null && b['created_at'] != null) {
            return b['created_at'].toString().compareTo(
              a['created_at'].toString(),
            );
          }
          // Fallback to document ID comparison (newest first)
          return b['doc_id'].toString().compareTo(a['doc_id'].toString());
        } catch (e) {
          return 0;
        }
      });

      print('Total reports loaded: ${reports.length}'); // Debug print

      setState(() {
        allReports = reports;
        filteredReports = reports;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e'); // Debug print
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reports: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterReports() {
    String query = searchController.text.toLowerCase();

    setState(() {
      filteredReports =
          allReports.where((report) {
            bool matchesSearch =
                query.isEmpty ||
                (report['judul_laporan']?.toLowerCase().contains(query) ??
                    false) ||
                (report['nama_pemohon']?.toLowerCase().contains(query) ??
                    false) ||
                (report['nama_penerima']?.toLowerCase().contains(query) ??
                    false);

            bool matchesCategory =
                selectedCategory == 'Semua' ||
                report['progress']?.toString() == selectedCategory;

            print(
              'Report: ${report['judul_laporan']}, Progress: "${report['progress']}", Selected: $selectedCategory, Matches: $matchesCategory',
            ); // Debug print

            return matchesSearch && matchesCategory;
          }).toList();

      print('Filtered reports count: ${filteredReports.length}'); // Debug print
    });
  }

  // Method untuk update System_Data ketika distribusi selesai
  Future<void> _updateSystemData() async {
    try {
      DateTime now = DateTime.now();
      String currentYear = now.year.toString();
      String currentMonth = _getMonthName(now.month);

      DocumentReference systemDataRef = _firestore
          .collection('System_Data')
          .doc('status_distribusi');

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(systemDataRef);

        Map<String, dynamic> data = {};
        int currentTotalPenerima = 0;

        if (snapshot.exists) {
          data = snapshot.data() as Map<String, dynamic>;
          currentTotalPenerima = (data['total_penerima'] ?? 0) as int;
        }

        // Update atau buat structure untuk tahun dan bulan
        if (data[currentYear] == null) {
          data[currentYear] = {};
        }

        Map<String, dynamic> yearData = Map<String, dynamic>.from(
          data[currentYear],
        );
        int currentMonthValue = (yearData[currentMonth] ?? 0) as int;
        yearData[currentMonth] = currentMonthValue + 1;
        data[currentYear] = yearData;

        // Update total_penerima
        data['total_penerima'] = currentTotalPenerima + 1;

        transaction.set(systemDataRef, data, SetOptions(merge: true));
      });

      print('System_Data updated successfully');
    } catch (e) {
      print('Error updating System_Data: $e');
      // Don't show error to user as this is background operation
    }
  }

  // Helper method untuk mendapatkan nama bulan
  String _getMonthName(int month) {
    List<String> months = [
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
    return months[month];
  }

  // Perbaikan pada fungsi updateReportProgress
  Future<void> updateReportProgress(
    String docId,
    String userId,
    String idPengajuan,
    String newProgress, {
    String? rejectionReason,
    Map<String, dynamic>? distributionData,
  }) async {
    String timestamp = getCurrentTimestamp();

    try {
      // Update root document
      Map<String, dynamic> updateData = {
        'progress': newProgress,
        'waktu_progress.$newProgress': timestamp,
      };

      if (rejectionReason != null) {
        // Gunakan field yang berbeda berdasarkan status
        if (newProgress == 'Ditolak') {
          updateData['alasan_ditolak'] = rejectionReason;
        } else if (newProgress == 'Gagal') {
          updateData['alasan_gagal'] = rejectionReason;
        }
      }

      if (distributionData != null) {
        updateData['distribusi_data'] = distributionData;
      }

      await _firestore
          .collection('Data_Pengajuan')
          .doc(docId)
          .update(updateData);

      // Update user document
      await _firestore
          .collection('Account_Storage')
          .doc(userId)
          .collection('Data_Pengajuan')
          .doc(idPengajuan)
          .update(updateData);

      // Update System_Data jika progress adalah "Selesai"
      if (newProgress == 'Selesai') {
        await _updateSystemData();
      }

      // Reload reports
      await loadAllReports();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status berhasil diperbarui'),
          backgroundColor: const Color(0xFF626F47),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showConfirmationDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.rate_review_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Konfirmasi Laporan',
                    style: TextStyle(
                      color: const Color(0xFF626F47),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Pilih tindakan untuk laporan "${report['judul_laporan']}"',
              style: TextStyle(
                color: Color(0xFF626F47).withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  showRejectionDialog(report);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Tolak',
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  updateReportProgress(
                    report['doc_id'],
                    report['user_id'],
                    report['id_pengajuan'],
                    'Disetujui',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Konfirmasi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  void showRejectionDialog(Map<String, dynamic> report) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    color: Colors.red[600],
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Alasan Penolakan',
                    style: TextStyle(
                      color: const Color(0xFF626F47),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Berikan alasan penolakan untuk laporan "${report['judul_laporan']}":',
                  style: TextStyle(
                    color: Color(0xFF626F47).withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan alasan penolakan...',
                    hintStyle: TextStyle(
                      color: Color(0xFF8F8962).withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF8F8962)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF626F47),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9F3D1).withOpacity(0.3),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: Color(0xFF626F47).withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (reasonController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    updateReportProgress(
                      report['doc_id'],
                      report['user_id'],
                      report['id_pengajuan'],
                      'Ditolak',
                      rejectionReason: reasonController.text.trim(),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Alasan penolakan harus diisi'),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Tolak',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  void showDistributionDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF626F47).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: const Color(0xFF626F47),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kirim Distribusi',
                    style: TextStyle(
                      color: const Color(0xFF626F47),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Apakah Anda yakin ingin mengirim distribusi untuk laporan "${report['judul_laporan']}"?',
              style: TextStyle(
                color: Color(0xFF626F47).withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: Color(0xFF626F47).withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  updateReportProgress(
                    report['doc_id'],
                    report['user_id'],
                    report['id_pengajuan'],
                    'Dikirim',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF626F47),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Kirim',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  void showFailDialog(Map<String, dynamic> report) {
    TextEditingController failReasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red[600],
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal Distribusi',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Berikan alasan mengapa distribusi untuk laporan "${report['judul_laporan']}" gagal dilakukan:',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: failReasonController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan alasan kegagalan distribusi...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (failReasonController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    updateReportProgress(
                      report['doc_id'],
                      report['user_id'],
                      report['id_pengajuan'],
                      'Gagal',
                      rejectionReason: failReasonController.text.trim(),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Alasan kegagalan harus diisi'),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Tandai Gagal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  void showCompleteDistributionDialog(Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CompleteDistributionPage(
              report: report,
              onComplete: (distributionData) {
                updateReportProgress(
                  report['doc_id'],
                  report['user_id'],
                  report['id_pengajuan'],
                  'Selesai',
                  distributionData: distributionData,
                );
              },
              onFailed: () {
                updateReportProgress(
                  report['doc_id'],
                  report['user_id'],
                  report['id_pengajuan'],
                  'Gagal',
                );
              },
            ),
      ),
    );
  }

  Widget buildActionButton(Map<String, dynamic> report) {
    String progress = report['progress'] ?? '';

    switch (progress) {
      case 'Menunggu Persetujuan':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => showConfirmationDialog(report),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Konfirmasi / Tolak',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      case 'Disetujui':
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () => showDistributionDialog(report),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF626F47),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Kirim',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: () => showFailDialog(report),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: BorderSide(color: const Color(0xFFEF4444), width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Gagal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 'Dikirim':
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () => showCompleteDistributionDialog(report),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Selesaikan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: () => showFailDialog(report),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: BorderSide(color: const Color(0xFFEF4444), width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Gagal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F3D1), // Sama dengan background
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF8F8962).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white, // Background putih untuk tombol kembali
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8F8962).withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: const Color(0xFF626F47),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Manajemen Pengajuan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF626F47),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF9F3D1,
      ), // Kembali ke warna krem sesuai gambar
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari laporan, pemohon, atau penerima...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.grey[400],
                            size: 22,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Category tabs
                  Container(
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          [
                            {'name': 'Semua', 'icon': Icons.dashboard_rounded},
                            {
                              'name': 'Menunggu Persetujuan',
                              'icon': Icons.pending_actions_rounded,
                            },
                            {
                              'name': 'Disetujui',
                              'icon': Icons.check_circle_rounded,
                            },
                            {
                              'name': 'Dikirim',
                              'icon': Icons.local_shipping_rounded,
                            },
                          ].map((categoryData) {
                            String category = categoryData['name'] as String;
                            IconData icon = categoryData['icon'] as IconData;
                            bool isSelected = selectedCategory == category;
                            return Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = category;
                                      _filterReports();
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(0xFF626F47)
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? const Color(0xFF626F47)
                                                : const Color(0xFF8F8962),
                                        width: 1,
                                      ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF626F47,
                                                  ).withOpacity(0.3),
                                                  spreadRadius: 0,
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 18,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF626F47),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          category,
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : const Color(0xFF626F47),
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  // Reports list
                  Expanded(
                    child:
                        isLoading
                            ? Center(
                              child: CircularProgressIndicator(
                                color: const Color(0xFF626F47),
                                strokeWidth: 3,
                              ),
                            )
                            : filteredReports.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8E2B8),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.assignment_outlined,
                                      size: 48,
                                      color: const Color(0xFF8F8962),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada laporan ditemukan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF626F47),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Laporan akan muncul di sini setelah diajukan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF626F47).withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: filteredReports.length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> report =
                                    filteredReports[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF8F8962,
                                      ).withOpacity(0.3),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF8F8962,
                                        ).withOpacity(0.1),
                                        spreadRadius: 0,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header dengan icon dan ID Pengajuan
                                        Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xFF626F47),
                                                    Color(0xFF8F8962),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.description_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // ID Pengajuan
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF626F47,
                                                      ).withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'ID: ${report['id_pengajuan'] ?? 'N/A'}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFF626F47,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Judul Laporan
                                                  Text(
                                                    report['judul_laporan'] ??
                                                        'Judul tidak tersedia',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                        0xFF626F47,
                                                      ),
                                                      height: 1.2,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),

                                        // Informasi Pemohon
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF9F3D1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF8F8962,
                                              ).withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Nama Pemohon
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .person_outline_rounded,
                                                    size: 16,
                                                    color: const Color(
                                                      0xFF626F47,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Pemohon: ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(
                                                        0xFF626F47,
                                                      ).withOpacity(0.7),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      report['nama_pemohon'] ??
                                                          'Nama tidak tersedia',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: const Color(
                                                          0xFF626F47,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Email Pemohon
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.email_outlined,
                                                    size: 16,
                                                    color: const Color(
                                                      0xFF626F47,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Email: ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(
                                                        0xFF626F47,
                                                      ).withOpacity(0.7),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      report['email_pemohon'] ??
                                                          'Email tidak tersedia',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: const Color(
                                                          0xFF626F47,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Alamat
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.location_on_outlined,
                                                    size: 16,
                                                    color: const Color(
                                                      0xFF626F47,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Alamat: ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(
                                                        0xFF626F47,
                                                      ).withOpacity(0.7),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      report['lokasi_distribusi']?['address'] ??
                                                          'Alamat tidak tersedia',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: const Color(
                                                          0xFF626F47,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Status dan tanggal
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  report['progress'],
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _getStatusColor(
                                                    report['progress'],
                                                  ).withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                        report['progress'],
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    report['progress'] ??
                                                        'Status tidak diketahui',
                                                    style: TextStyle(
                                                      color: _getStatusColor(
                                                        report['progress'],
                                                      ),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (report['created_at'] != null)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.schedule_rounded,
                                                    size: 14,
                                                    color: Color(
                                                      0xFF626F47,
                                                    ).withOpacity(0.7),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    formatDisplayDate(
                                                      report['created_at'],
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(
                                                        0xFF626F47,
                                                      ).withOpacity(0.7),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        buildActionButton(report),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PetugasNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DistribusiPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MapsPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LaporanPage()),
            );
          }
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Menunggu Persetujuan':
        return const Color(0xFFF59E0B);
      case 'Disetujui':
        return const Color(0xFF626F47);
      case 'Dikirim':
        return const Color(0xFF10B981);
      case 'Selesai':
        return const Color(0xFF059669);
      case 'Gagal':
        return const Color(0xFFEF4444);
      case 'Ditolak':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF8F8962);
    }
  }
}

class CompleteDistributionPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final Function(Map<String, dynamic>) onComplete;
  final VoidCallback onFailed;

  CompleteDistributionPage({
    required this.report,
    required this.onComplete,
    required this.onFailed,
  });

  @override
  _CompleteDistributionPageState createState() =>
      _CompleteDistributionPageState();
}

class _CompleteDistributionPageState extends State<CompleteDistributionPage> {
  TextEditingController receiverController = TextEditingController();
  TextEditingController issuesController = TextEditingController();
  bool useOriginalReceiver = false;
  List<XFile> selectedImages = <XFile>[]; // Explicit type
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    receiverController.text = widget.report['nama_penerima'] ?? '';
  }

  @override
  void dispose() {
    receiverController.dispose();
    issuesController.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        imageQuality: 80, // Same as ProfilePage
        maxWidth: 500, // Same as ProfilePage
        maxHeight: 500, // Same as ProfilePage
      );
      if (images != null && images.isNotEmpty) {
        setState(() {
          selectedImages = images; // Keep as XFile list
        });
      }
    } catch (e) {
      print('Error selecting images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> convertImageToBase64(XFile image) async {
    try {
      // Use the same method as ProfilePage
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      print('Error converting image to base64: $e');
      throw Exception('Failed to process image');
    }
  }

  Future<void> completeDistribution() async {
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimal 1 foto dokumentasi harus diupload'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: CircularProgressIndicator(color: const Color(0xFF626F47)),
          ),
    );

    try {
      List<String> base64Images = <String>[];

      // Process each XFile explicitly
      for (int i = 0; i < selectedImages.length; i++) {
        try {
          XFile currentImage = selectedImages[i];
          String base64 = await convertImageToBase64(currentImage);
          base64Images.add(base64);
        } catch (e) {
          print('Error processing image ${selectedImages[i].path}: $e');
          // Skip problematic images but continue with others
          continue;
        }
      }

      if (base64Images.isEmpty) {
        throw Exception('No images could be processed');
      }

      Map<String, dynamic> distributionData = <String, dynamic>{
        'nama_penerima_lapangan':
            useOriginalReceiver
                ? widget.report['nama_penerima']
                : receiverController.text,
        'kendala_lapangan':
            issuesController.text.isNotEmpty ? issuesController.text : null,
        'foto_dokumentasi': base64Images,
        'waktu_selesai':
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()) + ' WIB',
      };

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close this page

      widget.onComplete(distributionData);
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error completing distribution: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing distribution: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1), // Sesuai dengan tema krem
      appBar: AppBar(
        title: Text(
          'Selesaikan Distribusi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red[600],
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Gagal Distribusi',
                              style: TextStyle(
                                color: const Color(0xFF626F47),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        'Apakah distribusi gagal dilakukan?',
                        style: TextStyle(
                          color: Color(0xFF626F47).withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: Color(0xFF626F47).withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            widget.onFailed();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Ya, Gagal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
              );
            },
            child: Text(
              'GAGAL',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8F8962).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8F8962).withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Info Distribusi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF626F47),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.report['judul_laporan'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF626F47),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pemohon: ${widget.report['nama_pemohon'] ?? ''}',
                    style: TextStyle(
                      color: Color(0xFF626F47).withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Receiver name
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8F8962).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8F8962).withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nama Penerima',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF626F47),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F3D1).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        'Sesuai dengan pengajuan',
                        style: TextStyle(
                          color: const Color(0xFF626F47),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: useOriginalReceiver,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (value) {
                        setState(() {
                          useOriginalReceiver = value ?? false;
                          if (useOriginalReceiver) {
                            receiverController.text =
                                widget.report['nama_penerima'] ?? '';
                          }
                        });
                      },
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: receiverController,
                    enabled: !useOriginalReceiver,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama penerima di lapangan',
                      hintStyle: TextStyle(
                        color: Color(0xFF8F8962).withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFF8F8962)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          useOriginalReceiver
                              ? const Color(0xFFF9F3D1).withOpacity(0.3)
                              : Colors.white,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Field issues (optional)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8F8962).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8F8962).withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kendala Lapangan (Opsional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF626F47),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: issuesController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan kendala yang ditemui di lapangan',
                      hintStyle: TextStyle(
                        color: Color(0xFF8F8962).withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFF8F8962)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9F3D1).withOpacity(0.3),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Photo documentation
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8F8962).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8F8962).withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto Dokumentasi *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF626F47),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Minimal 1 foto dokumentasi harus diupload',
                    style: TextStyle(
                      color: Color(0xFF626F47).withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: pickImages,
                      icon: Icon(Icons.camera_alt_rounded, size: 20),
                      label: Text(
                        'Pilih Foto',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (selectedImages.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${selectedImages.length} foto dipilih',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(right: 12),
                            width: 80,
                            height: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(
                                          0xFF8F8962,
                                        ).withOpacity(0.5),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: FutureBuilder<Uint8List>(
                                        future:
                                            selectedImages[index].readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                            );
                                          } else if (snapshot.hasError) {
                                            return Container(
                                              color: const Color(
                                                0xFFF9F3D1,
                                              ).withOpacity(0.5),
                                              child: Icon(
                                                Icons
                                                    .image_not_supported_rounded,
                                                color: const Color(0xFF8F8962),
                                                size: 30,
                                              ),
                                            );
                                          } else {
                                            return Container(
                                              color: const Color(
                                                0xFFF9F3D1,
                                              ).withOpacity(0.3),
                                              child: Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: const Color(
                                                          0xFF10B981,
                                                        ),
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.red[600],
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 32),

            // Complete button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: completeDistribution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'SELESAIKAN DISTRIBUSI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
