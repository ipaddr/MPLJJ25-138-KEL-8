// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_pengajuan.dart';

class FirestoreService {
  // Instance Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  final String _collectionName = 'pengajuan';

  // 1. CREATE - Tambah pengajuan baru
  Future<String> addPengajuan(PengajuanModel pengajuan) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(pengajuan.toFirestore());

      return docRef.id; // Return document ID
    } catch (e) {
      throw Exception('Gagal menambah pengajuan: $e');
    }
  }

  // 2. READ - Ambil semua pengajuan (Real-time)
  Stream<List<PengajuanModel>> getAllPengajuan() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PengajuanModel.fromFirestore(doc);
          }).toList();
        });
  }

  // 3. READ - Ambil pengajuan berdasarkan status
  Stream<List<PengajuanModel>> getPengajuanByStatus(String status) {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PengajuanModel.fromFirestore(doc);
          }).toList();
        });
  }

  // 4. READ - Ambil satu pengajuan berdasarkan ID
  Future<PengajuanModel?> getPengajuanById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionName).doc(id).get();

      if (doc.exists) {
        return PengajuanModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil pengajuan: $e');
    }
  }

  // 5. UPDATE - Update pengajuan
  Future<void> updatePengajuan(String id, PengajuanModel pengajuan) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(pengajuan.toFirestore());
    } catch (e) {
      throw Exception('Gagal update pengajuan: $e');
    }
  }

  // 6. UPDATE - Update status pengajuan saja
  Future<void> updateStatus(String id, String status) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Gagal update status: $e');
    }
  }

  // 7. DELETE - Hapus pengajuan
  Future<void> deletePengajuan(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Gagal hapus pengajuan: $e');
    }
  }

  // 8. SEARCH - Cari pengajuan berdasarkan nama penerima
  Stream<List<PengajuanModel>> searchPengajuan(String query) {
    return _firestore
        .collection(_collectionName)
        .where('namaPenerima', isGreaterThanOrEqualTo: query)
        .where('namaPenerima', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PengajuanModel.fromFirestore(doc);
          }).toList();
        });
  }
}
