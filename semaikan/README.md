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
