import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class IsiProfilScreen extends StatefulWidget {
  const IsiProfilScreen({Key? key}) : super(key: key);

  @override
  State<IsiProfilScreen> createState() => _IsiProfilScreenState();
}

class _IsiProfilScreenState extends State<IsiProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _authService.updateProfile(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (success) {
        _showSnackbar('Profil berhasil disimpan!', isSuccess: true);
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      } else {
        _showSnackbar('Gagal menyimpan profil', isSuccess: false);
      }
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}', isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Lengkapi Profil',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Extra bottom padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.blue[300]!, Colors.blue[500]!] // Lighter for dark mode
                            : [Colors.blue[400]!, Colors.blue[600]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Form fields with consistent dark mode styling
                _buildTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  icon: Icons.person,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _bioController,
                  label: 'Bio (Opsional)',
                  icon: Icons.info,
                  isDark: isDark,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Gender dropdown with dark mode support
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Jenis Kelamin',
                    prefixIcon: Icon(
                      Icons.people,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                    filled: true,
                    fillColor: isDark 
                        ? Colors.grey[800]?.withValues(alpha: 0.6)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.blue[400]! : Colors.blue[600]!,
                        width: 2,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'female', child: Text('Perempuan')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Date picker with dark mode support
                InkWell(
                  onTap: _selectBirthDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal Lahir',
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                      ),
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? Colors.grey[800]?.withValues(alpha: 0.6)
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child: Text(
                      _selectedBirthDate == null
                          ? 'Pilih tanggal lahir'
                          : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Buttons with dark mode styling
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.blue[400] : Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Simpan Profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    child: const Text(
                      'Lewati untuk sekarang',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[300] : Colors.grey[600],
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[600],
        ),
        filled: true,
        fillColor: isDark 
            ? Colors.grey[800]?.withValues(alpha: 0.6)
            : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.blue[400]! : Colors.blue[600]!,
            width: 2,
          ),
        ),
        errorStyle: TextStyle(
          color: isDark ? Colors.red[300] : Colors.red[700],
        ),
      ),
    );
  }
}
