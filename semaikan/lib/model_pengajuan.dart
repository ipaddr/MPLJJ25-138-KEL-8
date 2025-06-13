// models/pengajuan_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PengajuanModel {
  final String? id;
  final String judul;
  final String tanggal;
  final String namaPenerima;
  final String jenisBantuan;
  final String jumlahPenerima;
  final String alasan;
  final String lokasi;
  final DateTime createdAt;
  final String status; // pending, approved, rejected

  PengajuanModel({
    this.id,
    required this.judul,
    required this.tanggal,
    required this.namaPenerima,
    required this.jenisBantuan,
    required this.jumlahPenerima,
    required this.alasan,
    required this.lokasi,
    required this.createdAt,
    this.status = 'pending',
  });

  // Convert dari Firestore DocumentSnapshot ke Object
  factory PengajuanModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PengajuanModel(
      id: doc.id,
      judul: data['judul'] ?? '',
      tanggal: data['tanggal'] ?? '',
      namaPenerima: data['namaPenerima'] ?? '',
      jenisBantuan: data['jenisBantuan'] ?? '',
      jumlahPenerima: data['jumlahPenerima'] ?? '',
      alasan: data['alasan'] ?? '',
      lokasi: data['lokasi'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  // Convert dari Object ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'judul': judul,
      'tanggal': tanggal,
      'namaPenerima': namaPenerima,
      'jenisBantuan': jenisBantuan,
      'jumlahPenerima': jumlahPenerima,
      'alasan': alasan,
      'lokasi': lokasi,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  // Copy dengan perubahan tertentu
  PengajuanModel copyWith({
    String? id,
    String? judul,
    String? tanggal,
    String? namaPenerima,
    String? jenisBantuan,
    String? jumlahPenerima,
    String? alasan,
    String? lokasi,
    DateTime? createdAt,
    String? status,
  }) {
    return PengajuanModel(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      tanggal: tanggal ?? this.tanggal,
      namaPenerima: namaPenerima ?? this.namaPenerima,
      jenisBantuan: jenisBantuan ?? this.jenisBantuan,
      jumlahPenerima: jumlahPenerima ?? this.jumlahPenerima,
      alasan: alasan ?? this.alasan,
      lokasi: lokasi ?? this.lokasi,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
