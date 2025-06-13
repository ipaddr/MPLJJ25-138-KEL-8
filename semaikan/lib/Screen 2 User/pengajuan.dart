import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'home_general.dart';

class DaftarPengajuanPage extends StatefulWidget {
  const DaftarPengajuanPage({super.key});

  @override
  State<DaftarPengajuanPage> createState() => _DaftarPengajuanPageState();
}

class _DaftarPengajuanPageState extends State<DaftarPengajuanPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _namaPenerimaController = TextEditingController();
  final TextEditingController _jenisBantuanController = TextEditingController();
  final TextEditingController _jumlahPenerimaController =
      TextEditingController();
  final TextEditingController _alasanController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  // Date and location variables
  DateTime? _selectedDate;
  LatLng? _selectedLocation; // Untuk center dialog saja
  LatLng? _confirmedLocation; // Lokasi yang sudah dikonfirmasi user
  LatLng? _currentMapCenter; // Track current center of dialog map
  String _selectedAddress = "";
  bool _isLoading = false;
  bool _isLocationConfirmed =
      false; // Flag untuk cek apakah lokasi sudah dikonfirmasi

  // Account category variable
  String _accountCategory = "";

  // Map controllers
  final MapController _mapController = MapController();
  final MapController _dialogMapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocationForDialog();
    _getAccountCategory();
  }

  // Get account category from user document
  Future<void> _getAccountCategory() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('Account_Storage').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _accountCategory = userData['account_category'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error getting account category: $e');
    }
  }

  // Convert account category to readable kategori
  String _getKategoriFromAccountCategory(String accountCategory) {
    switch (accountCategory) {
      case 'ibu_hamil_balita':
        return 'Ibu Hamil / Balita';
      case 'sekolah_pesantren':
        return 'Sekolah / Pesantren';
      default:
        return 'Umum';
    }
  }

  // Get current location hanya untuk menentukan pusat dialog
  Future<void> _getCurrentLocationForDialog() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
      } else {
        // Default location (Indonesia)
        setState(() {
          _selectedLocation = const LatLng(-6.2088, 106.8456);
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _selectedLocation = const LatLng(-6.2088, 106.8456);
      });
    }
  }

  // Method untuk konfirmasi lokasi dari center peta
  Future<void> _confirmLocationFromMapCenter() async {
    if (_currentMapCenter != null) {
      LatLng centerLocation = _currentMapCenter!;

      setState(() {
        _confirmedLocation = centerLocation;
        _isLocationConfirmed = true;
      });

      await _getAddressFromCoordinates(centerLocation);

      Navigator.pop(context);
    } else {
      _showErrorMessage('Silakan tunggu peta selesai dimuat dan coba lagi');
    }
  }

  // Get address from coordinates untuk confirmed location
  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        setState(() {
          _selectedAddress = address;
          _alamatController.text = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  // Convert coordinates to DMS format
  String _coordinatesToDMS(LatLng location) {
    String latDirection = location.latitude >= 0 ? 'N' : 'S';
    String lngDirection = location.longitude >= 0 ? 'E' : 'W';

    double lat = location.latitude.abs();
    double lng = location.longitude.abs();

    int latDeg = lat.floor();
    int lngDeg = lng.floor();

    double latMinFloat = (lat - latDeg) * 60;
    double lngMinFloat = (lng - lngDeg) * 60;

    int latMin = latMinFloat.floor();
    int lngMin = lngMinFloat.floor();

    double latSec = (latMinFloat - latMin) * 60;
    double lngSec = (lngMinFloat - lngMin) * 60;

    return "${latDeg}°${latMin}'${latSec.toStringAsFixed(1)}\"$latDirection ${lngDeg}°${lngMin}'${lngSec.toStringAsFixed(1)}\"$lngDirection";
  }

  // Format timestamp untuk waktu_progress
  String _formatTimestamp(DateTime dateTime) {
    // Format: 11/06/2025 02:18 WIB
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    return '${formatter.format(dateTime)} WIB';
  }

  // Date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF626F47),
              onPrimary: Color(0xFFF9F3D1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Save data to Firestore
  Future<void> _submitPengajuan() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create timestamp untuk waktu pengajuan
      DateTime now = DateTime.now();
      String waktuPengajuan = _formatTimestamp(now);

      // Prepare data dengan confirmed location dan waktu_progress sebagai map
      Map<String, dynamic> pengajuanData = {
        'judul_laporan': _judulController.text.trim(),
        'waktu_progress': {'waktu_pengajuan': waktuPengajuan},
        'nama_penerima': _namaPenerimaController.text.trim(),
        'jenis_bantuan': _jenisBantuanController.text.trim(),
        'jumlah_penerima': int.parse(_jumlahPenerimaController.text.trim()),
        'alasan_kebutuhan': _alasanController.text.trim(),
        'lokasi_distribusi': {
          'koordinat': _coordinatesToDMS(_confirmedLocation!),
          'address': _alamatController.text.trim(),
        },
        'Kategori': _getKategoriFromAccountCategory(_accountCategory),
        'email_pemohon': user.email,
        'progress': 'Menunggu Persetujuan',
        'user_id': user.uid,
      };

      // Save to main collection
      DocumentReference mainDoc = await _firestore
          .collection('Data_Pengajuan')
          .add(pengajuanData);

      // Save to user's subcollection
      await _firestore
          .collection('Account_Storage')
          .doc(user.uid)
          .collection('Data_Pengajuan')
          .doc(mainDoc.id)
          .set(pengajuanData);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan berhasil dikirim!'),
            backgroundColor: Color(0xFF626F47),
          ),
        );
        // Kembali ke home setelah berhasil submit
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeGeneral()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error submitting pengajuan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Validate form
  bool _validateForm() {
    if (_judulController.text.trim().isEmpty) {
      _showErrorMessage('Judul laporan tidak boleh kosong');
      return false;
    }
    if (_selectedDate == null) {
      _showErrorMessage('Tanggal pengajuan harus dipilih');
      return false;
    }
    if (_namaPenerimaController.text.trim().isEmpty) {
      _showErrorMessage('Nama penerima tidak boleh kosong');
      return false;
    }
    if (_jenisBantuanController.text.trim().isEmpty) {
      _showErrorMessage('Jenis bantuan tidak boleh kosong');
      return false;
    }
    if (_jumlahPenerimaController.text.trim().isEmpty) {
      _showErrorMessage('Jumlah penerima tidak boleh kosong');
      return false;
    }
    if (_alasanController.text.trim().isEmpty) {
      _showErrorMessage('Alasan atau kebutuhan tidak boleh kosong');
      return false;
    }
    if (!_isLocationConfirmed || _confirmedLocation == null) {
      _showErrorMessage('Lokasi distribusi harus dipilih dan dikonfirmasi');
      return false;
    }
    if (_alamatController.text.trim().isEmpty) {
      _showErrorMessage('Alamat tidak boleh kosong');
      return false;
    }

    try {
      int.parse(_jumlahPenerimaController.text.trim());
    } catch (e) {
      _showErrorMessage('Jumlah penerima harus berupa angka');
      return false;
    }

    return true;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeGeneral()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F3D1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F3D1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF626F47)),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeGeneral()),
                (route) => false,
              );
            },
          ),
          title: const Text(
            'Pengajuan Distribusi',
            style: TextStyle(
              color: Color(0xFF626F47),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF626F47)),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildFormField(
                        controller: _judulController,
                        hintText: 'Judul Laporan Pengajuan',
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: _namaPenerimaController,
                        hintText: 'Nama Penerima Bantuan',
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: _jenisBantuanController,
                        hintText: 'Jenis Bantuan yang Ingin Diajukan',
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: _jumlahPenerimaController,
                        hintText: 'Jumlah Penerima Bantuan',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: _alasanController,
                        hintText: 'Alasan atau Kebutuhan Bantuan',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: _alamatController,
                        hintText: 'Alamat Lengkap Distribusi',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildLocationSelector(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD8D1A8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8F8962), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Color(0xFF626F47)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF8F8962)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFD8D1A8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8F8962), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? 'Tanggal Pengajuan'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(
                color:
                    _selectedDate == null
                        ? const Color(0xFF8F8962)
                        : const Color(0xFF626F47),
              ),
            ),
            const Icon(Icons.calendar_today, color: Color(0xFF626F47)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container utama yang dapat ditekan langsung
        GestureDetector(
          onTap: () => _showMapDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFD8D1A8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8F8962), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isLocationConfirmed
                        ? 'Koordinat telah ditentukan (ketuk untuk mengubah kembali)'
                        : 'Lokasi Distribusi Bantuan',
                    style: TextStyle(
                      color:
                          _isLocationConfirmed
                              ? const Color(0xFF626F47)
                              : const Color(0xFF8F8962),
                      fontWeight:
                          _isLocationConfirmed
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  _isLocationConfirmed ? Icons.edit_location : Icons.map,
                  color: const Color(0xFF626F47),
                ),
              ],
            ),
          ),
        ),

        // Tampilkan detail koordinat tanpa preview peta
        if (_isLocationConfirmed && _confirmedLocation != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD8D1A8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8F8962), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_pin,
                      color: Color(0xFF626F47),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Koordinat: ${_coordinatesToDMS(_confirmedLocation!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF626F47),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedAddress.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place,
                        color: Color(0xFF8F8962),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Alamat: $_selectedAddress',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8F8962),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showMapDialog() {
    // Set initial map center
    LatLng initialCenter =
        _confirmedLocation ??
        _selectedLocation ??
        const LatLng(-6.2088, 106.8456);
    _currentMapCenter = initialCenter;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFF9F3D1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Lokasi Distribusi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF626F47),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF626F47)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Instruksi untuk user
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D1A8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF8F8962),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF626F47),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Geser peta untuk memposisikan marker di lokasi yang diinginkan, lalu tekan "Konfirmasi Lokasi"',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF626F47),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          mapController: _dialogMapController,
                          options: MapOptions(
                            center: initialCenter,
                            zoom: 15.0,
                            onPositionChanged: (
                              MapPosition position,
                              bool hasGesture,
                            ) {
                              // Update current map center saat user menggeser peta
                              if (hasGesture && position.center != null) {
                                _currentMapCenter = position.center!;
                              }
                            },
                            onMapReady: () {
                              // Set initial center when map is ready
                              _currentMapCenter = initialCenter;
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.semaikan',
                            ),
                          ],
                        ),
                      ),

                      // Marker tetap di tengah layar
                      const Center(
                        child: Icon(
                          Icons.location_pin,
                          color: Color(0xFF626F47),
                          size: 50,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),

                      // Crosshair helper (opsional)
                      Center(
                        child: Container(
                          width: 2,
                          height: 20,
                          color: const Color(0xFF626F47).withOpacity(0.3),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 20,
                          height: 2,
                          color: const Color(0xFF626F47).withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmLocationFromMapCenter,
                        icon: const Icon(Icons.check, color: Color(0xFFF9F3D1)),
                        label: const Text(
                          'Konfirmasi Lokasi',
                          style: TextStyle(
                            color: Color(0xFFF9F3D1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF626F47),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitPengajuan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF626F47),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFFF9F3D1))
                : const Text(
                  'AJUKAN PERMOHONAN',
                  style: TextStyle(
                    color: Color(0xFFF9F3D1),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _judulController.dispose();
    _namaPenerimaController.dispose();
    _jenisBantuanController.dispose();
    _jumlahPenerimaController.dispose();
    _alasanController.dispose();
    _alamatController.dispose();
    super.dispose();
  }
}
