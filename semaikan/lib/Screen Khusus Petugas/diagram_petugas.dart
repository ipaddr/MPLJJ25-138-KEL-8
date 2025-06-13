import 'package:flutter/material.dart';

class DiagramPetugas extends StatelessWidget {
  final Map<String, dynamic> distributionData;

  const DiagramPetugas({super.key, required this.distributionData});

  @override
  Widget build(BuildContext context) {
    final chartData = _processDistributionData();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFF9F3D1),
      ),
      child: Column(
        children: [
          // Data Grafik
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children:
                chartData
                    .map(
                      (data) => _buildChartBar(
                        data['value'].toString(),
                        data['height'],
                        data['label'],
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _processDistributionData() {
    List<Map<String, dynamic>> result = [];

    if (distributionData.isEmpty) {
      // Data default jika tidak ada data
      return [
        {'value': 0, 'height': 0.1, 'label': 'Distribusi\nTidak Ada Data'},
        {'value': 0, 'height': 0.1, 'label': 'Distribusi\nTidak Ada Data'},
        {'value': 0, 'height': 0.1, 'label': 'Distribusi\nTidak Ada Data'},
      ];
    }

    // Dapatkan tahun terbaru
    List<String> years =
        distributionData.keys.where((key) => key != 'total_penerima').toList();
    years.sort();

    if (years.isEmpty) {
      return [
        {'value': 0, 'height': 0.1, 'label': 'Distribusi\nTidak Ada Data'},
        {'value': 0, 'height': 0.1, 'label': 'Distribusi\nTidak Ada Data'},
        {'value': 0, 'height': 0.1, 'label': 'Distribusi\nTidak Ada Data'},
      ];
    }

    // Ambil data dari tahun terbaru
    String latestYear = years.last;
    Map<String, dynamic> yearData = distributionData[latestYear] ?? {};

    // Urutan bulan
    List<String> monthOrder = [
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

    // Dapatkan bulan yang ada data
    List<String> availableMonths = [];
    for (String month in monthOrder) {
      if (yearData.containsKey(month)) {
        availableMonths.add(month);
      }
    }

    // Ambil 3 bulan terakhir
    List<String> lastThreeMonths =
        availableMonths.length >= 3
            ? availableMonths.sublist(availableMonths.length - 3)
            : availableMonths;

    // Jika kurang dari 3 bulan, tambahkan bulan kosong
    while (lastThreeMonths.length < 3) {
      lastThreeMonths.insert(0, 'Tidak Ada Data');
    }

    // Hitung nilai maksimum untuk normalisasi tinggi bar
    int maxValue = 0;
    for (String month in lastThreeMonths) {
      if (month != 'Tidak Ada Data' && yearData.containsKey(month)) {
        int value = yearData[month] ?? 0;
        if (value > maxValue) maxValue = value;
      }
    }

    // Buat data untuk chart
    for (String month in lastThreeMonths) {
      int value = 0;
      double height = 0.1;
      String label = 'Distribusi $month\n$latestYear';

      if (month != 'Tidak Ada Data' && yearData.containsKey(month)) {
        value = yearData[month] ?? 0;
        height = maxValue > 0 ? (value / maxValue) * 0.8 + 0.2 : 0.2;
      } else {
        label = 'Distribusi\nTidak Ada Data';
      }

      result.add({'value': value, 'height': height, 'label': label});
    }

    return result;
  }

  Widget _buildChartBar(String value, double height, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        const Text(
          'Bantuan\nTerdistribusi',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Color(0xFF626F47)),
        ),
        const SizedBox(height: 5),
        Container(
          width: 80,
          height: 150 * height,
          decoration: const BoxDecoration(
            color: Color(0xFF626F47),
            borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF626F47)),
        ),
      ],
    );
  }
}
