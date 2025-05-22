import 'package:flutter/material.dart';

class NotifikasiPageIP extends StatefulWidget {
  const NotifikasiPageIP({super.key});

  @override
  State<NotifikasiPageIP> createState() => _NotifikasiPageIPState();
}

class _NotifikasiPageIPState extends State<NotifikasiPageIP> {
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
          'Notifikasi Ibu Hamil dan Pesantren',
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
              // Banner Konfirmasi Laporan Pengajuan
              _buildConfirmationBanner(),

              const SizedBox(height: 24),

              // Hari Ini
              const Text(
                'Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF626F47),
                ),
              ),
              const SizedBox(height: 12),

              // Daftar notifikasi hari ini
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return _buildNotificationItem();
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk banner konfirmasi laporan
  Widget _buildConfirmationBanner() {
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman konfirmasi laporan
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const KonfirmasiLaporanPage(),
          ),
        );
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
            // Ikon notifikasi (menggunakan gambar stack untuk efek 3D)
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
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // Teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Update Laporan Pengajuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF626F47),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Laporan Posy. Indah Hati pda tanggal 29 April...',
                    style: TextStyle(fontSize: 14, color: Color(0xFF626F47)),
                  ),
                ],
              ),
            ),

            // Ikon panah kanan
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF626F47),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk item notifikasi
  Widget _buildNotificationItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon dokumen
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

          // Konten notifikasi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Informasi Penting',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bantuan akan didistribusikan pada 6 Mei 2025',
                  style: TextStyle(fontSize: 14, color: Color(0xFF626F47)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Halaman konfirmasi laporan (mirip konfirmasi follow Instagram)
class KonfirmasiLaporanPage extends StatefulWidget {
  const KonfirmasiLaporanPage({super.key});

  @override
  State<KonfirmasiLaporanPage> createState() => _KonfirmasiLaporanPageState();
}

class _KonfirmasiLaporanPageState extends State<KonfirmasiLaporanPage> {
  // List untuk menampung data permintaan
  List<Map<String, dynamic>> _requestList = [];

  // List untuk menampung ID yang sudah diproses
  final List<int> _processedIds = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // Fungsi untuk memuat permintaan (simulasi data)
  void _loadRequests() {
    setState(() {
      _requestList = [
        {
          'id': 1,
          'name': 'SMAN 1 Kota Padang',
          'date': '22 April 2025',
          'type': 'Sekolah',
          'status': 'Pending',
        },
        {
          'id': 2,
          'name': 'Pesantren Nusa Bangsa',
          'date': '18 April 2025',
          'type': 'Pesantren',
          'status': 'Pending',
        },
        {
          'id': 3,
          'name': 'Ny. Siti Aisyah',
          'date': '01 April 2025',
          'type': 'Ibu Hamil',
          'status': 'Pending',
        },
        {
          'id': 4,
          'name': 'SMAN 2 Kota Padang',
          'date': '25 April 2025',
          'type': 'Sekolah',
          'status': 'Pending',
        },
      ];
    });
  }

  // Fungsi untuk memproses permintaan (terima/tolak)
  void _processRequest(int id, String action) {
    setState(() {
      final index = _requestList.indexWhere((request) => request['id'] == id);
      if (index != -1) {
        _requestList[index]['status'] =
            action == 'accept' ? 'Diterima' : 'Ditolak';
        _processedIds.add(id);
      }
    });

    // Tampilkan snackbar konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == 'accept'
              ? 'Permintaan berhasil diterima'
              : 'Permintaan ditolak',
        ),
        backgroundColor: action == 'accept' ? Colors.green : Colors.red,
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
      ),
      body:
          _requestList.isEmpty
              ? const Center(
                child: Text(
                  'Tidak ada permintaan saat ini',
                  style: TextStyle(fontSize: 16, color: Color(0xFF626F47)),
                ),
              )
              : ListView.builder(
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
                    child: Column(
                      children: [
                        // Header dengan informasi permintaan
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Icon atau gambar sekolah/pesantren
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECE8C8),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  color: Color(0xFF626F47),
                                  size: 30,
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Informasi permintaan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF626F47),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tanggal: ${request['date']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF626F47),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tipe: ${request['type']}',
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
                        ),

                        // Status dan tombol aksi
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFECE8C8),
                                width: 1,
                              ),
                            ),
                          ),
                          child:
                              isProcessed
                                  // Jika sudah diproses, tampilkan status
                                  ? Center(
                                    child: Text(
                                      'Status: ${request['status']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            request['status'] == 'Diterima'
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                  )
                                  // Jika belum diproses, tampilkan tombol aksi
                                  : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Tombol Tolak
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed:
                                              () => _processRequest(
                                                request['id'],
                                                'reject',
                                              ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                              color: Colors.red,
                                              width: 1,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Tolak',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // Tombol Terima
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              () => _processRequest(
                                                request['id'],
                                                'accept',
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF626F47,
                                            ),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Terima',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
