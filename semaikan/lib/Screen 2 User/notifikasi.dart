import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotifikasiPageIP extends StatefulWidget {
  const NotifikasiPageIP({super.key});

  @override
  State<NotifikasiPageIP> createState() => _NotifikasiPageIPState();
}

class _NotifikasiPageIPState extends State<NotifikasiPageIP> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _allNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllNotifications();
  }

  Future<void> _loadAllNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Map<String, dynamic>> notifications = [];

      // Load pengumuman dari petugas
      await _loadPengumumanNotifications(notifications);

      // Load notifikasi laporan pengguna
      await _loadLaporanNotifications(notifications);

      // Sort berdasarkan tanggal terbaru
      notifications.sort((a, b) {
        final dateA = a['sort_date'] as DateTime;
        final dateB = b['sort_date'] as DateTime;
        return dateB.compareTo(dateA);
      });

      setState(() {
        _allNotifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPengumumanNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    try {
      final doc =
          await _firestore
              .collection('System_Data')
              .doc('notifikasi_user')
              .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final pengumuman = value['pengumuman']?.toString() ?? '';
            final tanggalDibuat = value['tanggal_dibuat']?.toString() ?? '';

            if (pengumuman.isNotEmpty && tanggalDibuat.isNotEmpty) {
              final parsedDate = _parseWaktuString(tanggalDibuat);
              if (parsedDate != null) {
                // Cek apakah notifikasi masih dalam 1 bulan
                final now = DateTime.now();
                final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);

                if (parsedDate.isAfter(oneMonthAgo)) {
                  notifications.add({
                    'type': 'pengumuman',
                    'title': 'Informasi Penting!',
                    'content': pengumuman,
                    'date_string': tanggalDibuat,
                    'sort_date': parsedDate,
                    'formatted_date': _formatTanggalIndonesia(tanggalDibuat),
                  });
                }
              }
            }
          }
        });
      }
    } catch (e) {
      print('Error loading pengumuman notifications: $e');
    }
  }

  Future<void> _loadLaporanNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final querySnapshot =
            await _firestore
                .collection('Account_Storage')
                .doc(user.uid)
                .collection('Data_Pengajuan')
                .get();

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final progress = data['progress']?.toString() ?? '';
          final waktuProgress = data['waktu_progress'] as Map<String, dynamic>?;

          if (waktuProgress != null) {
            // Cek progress yang ingin ditampilkan
            if ([
              'Disetujui',
              'Dikirim',
              'Selesai',
              'Gagal',
              'Ditolak',
            ].contains(progress)) {
              String? dateString;
              String title = '';
              String content = '';

              // Ambil tanggal berdasarkan progress
              switch (progress) {
                case 'Disetujui':
                  dateString = waktuProgress['Disetujui']?.toString();
                  title = 'Laporan Pengajuan Disetujui.';
                  break;
                case 'Dikirim':
                  dateString = waktuProgress['Dikirim']?.toString();
                  title = 'Laporan Pengajuan Dikirim.';
                  break;
                case 'Selesai':
                  dateString = waktuProgress['Selesai']?.toString();
                  title = 'Laporan Pengajuan Selesai.';
                  break;
                case 'Gagal':
                  dateString = waktuProgress['Gagal']?.toString();
                  title = 'Laporan Pengajuan Gagal.';
                  break;
                case 'Ditolak':
                  dateString = waktuProgress['Ditolak']?.toString();
                  title = 'Laporan Pengajuan Ditolak.';
                  break;
              }

              if (dateString != null && dateString.isNotEmpty) {
                final parsedDate = _parseWaktuString(dateString);
                if (parsedDate != null) {
                  // Cek apakah notifikasi masih dalam 1 bulan
                  final now = DateTime.now();
                  final oneMonthAgo = DateTime(
                    now.year,
                    now.month - 1,
                    now.day,
                  );

                  if (parsedDate.isAfter(oneMonthAgo)) {
                    final formattedDate = _formatTanggalIndonesia(dateString);

                    // Buat content berdasarkan progress
                    switch (progress) {
                      case 'Disetujui':
                        content =
                            'Laporan pengajuan pada tanggal $formattedDate telah disetujui.';
                        break;
                      case 'Dikirim':
                        content =
                            'Laporan pengajuan pada tanggal $formattedDate telah dikirim.';
                        break;
                      case 'Selesai':
                        content =
                            'Laporan pengajuan pada tanggal $formattedDate telah selesai.';
                        break;
                      case 'Gagal':
                        content =
                            'Laporan pengajuan pada tanggal $formattedDate mengalami kegagalan.';
                        break;
                      case 'Ditolak':
                        content =
                            'Laporan pengajuan pada tanggal $formattedDate telah ditolak.';
                        break;
                    }

                    notifications.add({
                      'type': 'laporan',
                      'title': title,
                      'content': content,
                      'date_string': dateString,
                      'sort_date': parsedDate,
                      'formatted_date': formattedDate,
                      'progress': progress,
                    });
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading laporan notifications: $e');
    }
  }

  DateTime? _parseWaktuString(String waktuString) {
    try {
      // Format: "15/06/2025 14:30 WIB"
      final parts = waktuString.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0]; // "15/06/2025"
        final timePart = parts[1]; // "14:30"

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
      print('Error parsing waktu string: $e');
    }
    return null;
  }

  String _formatTanggalIndonesia(String waktuString) {
    try {
      final dateTime = _parseWaktuString(waktuString);
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
      print('Error formatting tanggal Indonesia: $e');
    }
    return waktuString;
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Hari Ini';
    } else if (notificationDate == yesterday) {
      return 'Kemarin';
    } else {
      final difference = today.difference(notificationDate).inDays;
      if (difference < 7) {
        return '$difference hari yang lalu';
      } else if (difference < 30) {
        final weeks = (difference / 7).floor();
        return '$weeks minggu yang lalu';
      } else {
        return _formatTanggalIndonesia(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB',
        );
      }
    }
  }

  // Group notifications by relative date
  Map<String, List<Map<String, dynamic>>> _groupNotificationsByDate() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var notification in _allNotifications) {
      final date = notification['sort_date'] as DateTime;
      final relativeDate = _getRelativeDate(date);

      if (!grouped.containsKey(relativeDate)) {
        grouped[relativeDate] = [];
      }
      grouped[relativeDate]!.add(notification);
    }

    return grouped;
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
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF626F47)),
              )
              : _allNotifications.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Color(0xFF8F8962),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tidak ada notifikasi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8F8962),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Notifikasi akan muncul di sini',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8F8962)),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadAllNotifications,
                color: const Color(0xFF626F47),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        ..._buildGroupedNotifications(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  List<Widget> _buildGroupedNotifications() {
    final grouped = _groupNotificationsByDate();
    List<Widget> widgets = [];

    grouped.forEach((dateGroup, notifications) {
      // Add date header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Text(
            dateGroup,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
        ),
      );

      // Add notifications for this date group
      for (int i = 0; i < notifications.length; i++) {
        widgets.add(_buildNotificationItem(notifications[i]));

        // Add divider between notifications (but not after the last one in the group)
        if (i < notifications.length - 1) {
          widgets.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Color(0xFF8F8962), height: 1, thickness: 1),
            ),
          );
        }
      }
    });

    return widgets;
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final type = notification['type'] as String;
    final title = notification['title'] as String;
    final content = notification['content'] as String;

    // Icon berdasarkan tipe notifikasi
    IconData iconData;
    Color iconColor;

    if (type == 'pengumuman') {
      iconData = Icons.campaign;
      iconColor = const Color(0xFF626F47);
    } else {
      // Icon berdasarkan progress laporan
      final progress = notification['progress'] as String?;
      switch (progress) {
        case 'Disetujui':
          iconData = Icons.check_circle_outline;
          iconColor = Colors.blue;
          break;
        case 'Dikirim':
          iconData = Icons.local_shipping;
          iconColor = Colors.purple;
          break;
        case 'Selesai':
          iconData = Icons.task_alt;
          iconColor = Colors.green;
          break;
        case 'Gagal':
          iconData = Icons.error_outline;
          iconColor = Colors.red;
          break;
        case 'Ditolak':
          iconData = Icons.block;
          iconColor = Colors.red[800]!;
          break;
        default:
          iconData = Icons.description_outlined;
          iconColor = const Color(0xFF626F47);
      }
    }

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
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF626F47),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
