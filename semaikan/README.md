TODO

progress Value 
- Menunggu Persetujuan --> Menunggu Petugas Konfirmasi Laporan
- Disetujui --> Petugas Menyetujui Laporan ( Sama dengan dibawah )
- Menunggu Dikirim --> Menunggu Bantuan Dikirimkan 
- Dikirim --> Bantuan Sedang Dikirimkan
- Selesai --> Bantuan Berhasil Dikirimkan dan selesai
- Gagal --> Bantuan Gagal Dikirimkan Dikarenakan Kendala

Petugas Konfirmasi Laporan
- Changed Progress --> Disetujui
- Added waktu_progress --> Disetujui (TIMESTAMP)
- Lakukan pada 2 level collection (User / System)

Condition
- Petugas Menyetujui Laporan dan pada timeline akan muncul 2 timeline :
    1. Laporan Pengguna Disetujui Dengan TimeStamp dari waktu_progress
    2. Laporan Pengguna Sedang menunggu Pengiriman (Timestamp yang sama)
- Dikirim
- Selesai
- Gagal

- Sisi Petugas
    1. Add Menyetujui Laporan
    2. Add Mengirimkan Laporan Distribusi





import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/floating_bottom_navbar.dart';
import 'distribusi.dart';
import 'pengajuan.dart';
import 'package:semaikan/Screen%20Bersama/maps.dart';
import 'home_general.dart';
import '../Screen Bersama/detail_laporan.dart';