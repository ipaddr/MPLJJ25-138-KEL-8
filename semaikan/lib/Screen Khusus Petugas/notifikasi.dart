import 'package:flutter/material.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmationBanner(),
              const SizedBox(height: 24),
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
                itemCount: 3,
                itemBuilder: (context, index) => _buildNotificationItem(),
              ),
              const SizedBox(height: 24),
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
                itemCount: 5,
                itemBuilder: (context, index) => _buildNotificationItem(),
              ),
            ],
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Konfirmasi Laporan Pengajuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF626F47),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Laporan Pengajuan SMAN 1 Padang + 1253 lainnya',
                    style: TextStyle(fontSize: 14, color: Color(0xFF626F47)),
                  ),
                ],
              ),
            ),
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

  Widget _buildNotificationItem() {
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
              children: const [
                Text(
                  'Pengajuan Distribusi Perlu Konfirmasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'SMAN 1 Padang pada tanggal 4 April 2025 mengajukan laporan distribusi.',
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

class KonfirmasiLaporanPage extends StatefulWidget {
  const KonfirmasiLaporanPage({super.key});

  @override
  State<KonfirmasiLaporanPage> createState() => _KonfirmasiLaporanPageState();
}

class _KonfirmasiLaporanPageState extends State<KonfirmasiLaporanPage> {
  List<Map<String, dynamic>> _requestList = [];
  final List<int> _processedIds = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

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

  void _processRequest(int id) {
    setState(() {
      final index = _requestList.indexWhere((request) => request['id'] == id);
      if (index != -1) {
        _requestList[index]['status'] = 'Sedang diproses';
        _processedIds.add(id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permintaan berhasil dikonfirmasi'),
        backgroundColor: Colors.green,
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
                    child: ListTile(
                      title: Text(
                        request['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF626F47),
                        ),
                      ),
                      subtitle: Text(
                        '${request['type']} • ${request['date']}',
                        style: const TextStyle(color: Color(0xFF626F47)),
                      ),
                      trailing:
                          isProcessed
                              ? const Text(
                                'Sedang diproses',
                                style: TextStyle(color: Colors.orange),
                              )
                              : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF626F47),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _processRequest(request['id']),
                                child: const Text('Konfirmasi'),
                              ),
                    ),
                  );
                },
              ),
    );
  }
}
