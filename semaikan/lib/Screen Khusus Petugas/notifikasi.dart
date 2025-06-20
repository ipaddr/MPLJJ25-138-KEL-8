import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notifikasi_action.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _todayNotifications = [];
  List<Map<String, dynamic>> _last7DaysNotifications = [];
  int _pendingRequestsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final querySnapshot = await _firestore.collection('Data_Pengajuan').get();

      List<Map<String, dynamic>> pendingNotifications = [];
      int pendingCount = 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sevenDaysAgo = today.subtract(const Duration(days: 7));

      print('Debug: Current time: $now');
      print('Debug: Today: $today');
      print('Debug: Seven days ago: $sevenDaysAgo');

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final progress = data['progress'] ?? '';

        if (progress == 'Menunggu Persetujuan') {
          pendingCount++;

          final namaLengkap = data['nama_pemohon'] ?? 'Tidak diketahui';
          final waktuProgress = data['waktu_progress'] as Map<String, dynamic>?;
          final waktuPengajuan = waktuProgress?['waktu_pengajuan'] ?? '';

          print(
            'Debug: Processing notification for $namaLengkap, waktu: $waktuPengajuan',
          );

          if (waktuPengajuan.isNotEmpty) {
            final notificationDate = _parseWaktuPengajuan(waktuPengajuan);

            print('Debug: Parsed date: $notificationDate');

            if (notificationDate != null) {
              final notification = {
                'id': doc.id,
                'nama_pemohon': namaLengkap,
                'waktu_pengajuan': waktuPengajuan,
                'formatted_date': _formatTanggal(waktuPengajuan),
                'notification_date': notificationDate,
                'title': '$namaLengkap mengajukan laporan distribusi',
                'subtitle':
                    '$namaLengkap pada tanggal ${_formatTanggal(waktuPengajuan)} mengajukan laporan distribusi',
              };

              pendingNotifications.add(notification);
            }
          }
        }
      }

      // Urutkan berdasarkan waktu terbaru
      pendingNotifications.sort((a, b) {
        final dateA = a['notification_date'] as DateTime;
        final dateB = b['notification_date'] as DateTime;
        return dateB.compareTo(dateA); // Terbaru di atas
      });

      // Pisahkan antara hari ini dan 7 hari terakhir
      List<Map<String, dynamic>> todayList = [];
      List<Map<String, dynamic>> last7DaysList = [];

      for (var notification in pendingNotifications) {
        final notificationDate = notification['notification_date'] as DateTime;
        final notificationDay = DateTime(
          notificationDate.year,
          notificationDate.month,
          notificationDate.day,
        );

        print(
          'Debug: Checking notification date: $notificationDay vs today: $today',
        );

        if (notificationDay.isAtSameMomentAs(today)) {
          print('Debug: Adding to today list: ${notification['nama_pemohon']}');
          todayList.add(notification);
        } else if (notificationDay.isAfter(sevenDaysAgo) &&
            notificationDay.isBefore(today)) {
          print(
            'Debug: Adding to last 7 days list: ${notification['nama_pemohon']}',
          );
          last7DaysList.add(notification);
        } else {
          print(
            'Debug: Notification outside range: ${notification['nama_pemohon']}, date: $notificationDay',
          );
        }
      }

      print('Debug: Total notifications: ${pendingNotifications.length}');
      print('Debug: Today notifications: ${todayList.length}');
      print('Debug: Last 7 days notifications: ${last7DaysList.length}');
      print('Debug: Today date: $today');

      setState(() {
        _todayNotifications = todayList;
        _last7DaysNotifications = last7DaysList;
        _pendingRequestsCount = pendingCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
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
          'Notifikasi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_pendingRequestsCount > 0) ...[
                          _buildConfirmationBanner(),
                          const SizedBox(height: 24),
                        ],

                        // Hari Ini Section
                        if (_todayNotifications.isNotEmpty) ...[
                          const Text(
                            'Hari Ini',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF626F47),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _todayNotifications.length,
                            itemBuilder:
                                (context, index) => _buildNotificationItem(
                                  _todayNotifications[index],
                                ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 7 Hari Terakhir Section
                        if (_last7DaysNotifications.isNotEmpty) ...[
                          const Text(
                            '7 Hari Terakhir',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF626F47),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _last7DaysNotifications.length,
                            itemBuilder:
                                (context, index) => _buildNotificationItem(
                                  _last7DaysNotifications[index],
                                ),
                          ),
                        ],

                        // Jika tidak ada notifikasi
                        if (_todayNotifications.isEmpty &&
                            _last7DaysNotifications.isEmpty &&
                            !_isLoading &&
                            _pendingRequestsCount == 0) ...[
                          const SizedBox(height: 50),
                          const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 64,
                                  color: Color(0xFF8F8962),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Tidak ada notifikasi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF626F47),
                                  ),
                                ),
                                Text(
                                  'Semua notifikasi akan muncul di sini',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8F8962),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildConfirmationBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotifikasiActionPage()),
        ).then((_) {
          // Refresh notifications when returning from action page
          _loadNotifications();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF626F47).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Positioned(
                  left: 5,
                  top: 5,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.pending_actions,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Konfirmasi Laporan Pengajuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF626F47),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _pendingRequestsCount > 0
                        ? '$_pendingRequestsCount pengajuan menunggu persetujuan'
                        : 'Tidak ada pengajuan pending',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF626F47),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (_pendingRequestsCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _pendingRequestsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF626F47),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFECE8C8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF626F47),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengajuan Distribusi Perlu Konfirmasi',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['subtitle'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF626F47),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getRelativeTime(notification['notification_date']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8F8962),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }
}
