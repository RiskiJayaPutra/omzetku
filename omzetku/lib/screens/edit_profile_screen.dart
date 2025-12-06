import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/api_service.dart';
import '../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _namaLengkapController = TextEditingController();
  final _namaUsahaController = TextEditingController();
  final _emailController = TextEditingController();
  final _nomorTeleponController = TextEditingController();
  final _passwordLamaController = TextEditingController();
  final _passwordBaruController = TextEditingController();

  bool _isLoading = true;
  bool _obscurePasswordLama = true;
  bool _obscurePasswordBaru = true;
  String? _imagePath; // Store image path for mobile
  String? _imageUrl; // Store photo URL from server
  XFile? _pickedFile; // Store picked file for both web and mobile
  List<int>? _imageBytes; // Store image bytes for preview
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _namaUsahaController.dispose();
    _emailController.dispose();
    _nomorTeleponController.dispose();
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _apiService.getUser();
      if (userData['success'] == true && userData['data'] != null) {
        final user = userData['data'];
        setState(() {
          _namaLengkapController.text = user['nama_lengkap'] ?? '';
          _namaUsahaController.text = user['nama_usaha'] ?? '';
          _emailController.text = user['email'] ?? '';
          _nomorTeleponController.text = user['nomor_telepon'] ?? '';
          _imageUrl = user['photo_url']; // Load existing photo URL
          _isLoading = false;
        });
        print('📷 Photo URL loaded: $_imageUrl');
      } else {
        setState(() => _isLoading = false);
        _showMessage('Gagal memuat data', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Gagal memuat data: $e', Colors.red);
      print('❌ Error loading user data: $e');
    }
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imagePath != null || _imageBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Hapus Foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imagePath = null;
                      _imageBytes = null;
                      _pickedFile = null;
                    });
                    _showMessage('Foto dihapus', Colors.orange);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // For web, read bytes immediately for preview
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _pickedFile = pickedFile;
            _imageBytes = bytes;
            _imagePath = pickedFile.path; // Keep for reference
          });
          _showMessage('Foto berhasil dipilih', Colors.green);
        } else {
          // For mobile, crop image
          setState(() {
            _pickedFile = pickedFile;
          });
          await _cropImage(pickedFile.path);
        }
      }
    } catch (e) {
      _showMessage('Gagal memilih foto: $e', Colors.red);
    }
  }

  Future<void> _cropImage(String imagePath) async {
    if (kIsWeb) {
      // Skip cropping on web
      setState(() {
        _imagePath = imagePath;
      });
      _showMessage('Foto berhasil dipilih', Colors.green);
      return;
    }

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Sesuaikan Foto',
            toolbarColor: const Color(0xFF1E88E5),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Sesuaikan Foto', aspectRatioLockEnabled: true),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imagePath = croppedFile.path;
          _pickedFile = null; // Clear picked file after crop
        });
        _showMessage('Foto berhasil dipilih', Colors.green);
      }
    } catch (e) {
      // If cropping fails, use original
      setState(() {
        _imagePath = imagePath;
        _pickedFile = null;
      });
      _showMessage('Foto berhasil dipilih', Colors.green);
    }
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        List<int>? imageBytes;
        String? imageFileName;

        // Prepare image data
        if (_pickedFile != null) {
          // For web: read bytes from XFile
          imageBytes = await _pickedFile!.readAsBytes();
          imageFileName = _pickedFile!.name;
          print(
            '📷 Prepared image for upload: $imageFileName (${imageBytes.length} bytes)',
          );
        }

        // Update profile with photo
        final result = await _apiService.updateProfile(
          namaLengkap: _namaLengkapController.text,
          namaUsaha: _namaUsahaController.text,
          nomorTelepon: _nomorTeleponController.text,
          imagePath: _imagePath,
          imageBytes: imageBytes,
          imageFileName: imageFileName,
        );

        setState(() => _isLoading = false);

        if (result['success'] == true) {
          // Update photo URL if photo was uploaded
          if (result['data'] != null && result['data']['photo_url'] != null) {
            setState(() {
              _imageUrl = result['data']['photo_url'];
              _imagePath = null; // Clear temp file after successful upload
              _pickedFile = null; // Clear picked file
              _imageBytes = null; // Clear image bytes
            });
          }
          _showMessage('Profil berhasil diperbarui', Colors.green);
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            Navigator.pop(
              context,
              true,
            ); // Return true to indicate update success
          }
        } else {
          _showMessage(
            result['message'] ?? 'Gagal memperbarui profil',
            Colors.red,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showMessage('Gagal memperbarui profil: $e', Colors.red);
      }
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha:
                        0.2, // compatible with older Flutter if withOpacity(0.2)
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  color == Colors.green ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2196F3),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(
                                width: 120,
                                height: 120,
                                child: _imageBytes != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          Uint8List.fromList(_imageBytes!),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : _imagePath != null && !kIsWeb
                                    ? ClipOval(
                                        child: Image.file(
                                          File(_imagePath!),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : ProfileAvatar(
                                        imageUrl:
                                            _imageUrl != null &&
                                                _imageUrl!.isNotEmpty
                                            ? '${ApiService.baseUrl.replaceAll('/api', '')}/$_imageUrl'
                                            : null,
                                        radius: 60,
                                        userName: _namaLengkapController.text,
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _namaLengkapController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCard('Informasi Pribadi', [
                            _buildTextField(
                              controller: _namaLengkapController,
                              label: 'Nama Lengkap',
                              icon: Icons.person_outline,
                              validator: (v) =>
                                  v!.isEmpty ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _namaUsahaController,
                              label: 'Nama Usaha',
                              icon: Icons.business_outlined,
                              validator: (v) =>
                                  v!.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ]),
                          const SizedBox(height: 16),
                          _buildCard('Informasi Kontak', [
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v!.isEmpty) {
                                  return 'Wajib diisi';
                                }
                                if (!v.contains('@')) {
                                  return 'Email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _nomorTeleponController,
                              label: 'Nomor Telepon',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  v!.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ]),
                          const SizedBox(height: 16),
                          _buildCard('Ubah Password (Opsional)', [
                            _buildTextField(
                              controller: _passwordLamaController,
                              label: 'Password Lama',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePasswordLama,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePasswordLama
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePasswordLama =
                                        !_obscurePasswordLama;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordBaruController,
                              label: 'Password Baru',
                              icon: Icons.lock_open_outlined,
                              obscureText: _obscurePasswordBaru,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePasswordBaru
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePasswordBaru =
                                        !_obscurePasswordBaru;
                                  });
                                },
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleUpdate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Simpan Perubahan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }
}
