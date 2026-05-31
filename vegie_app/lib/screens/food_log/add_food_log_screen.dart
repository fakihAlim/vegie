import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';
import '../../models/food_log.dart';
import '../../models/badge_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_log_provider.dart';
import '../../services/activity_log_service.dart';
import '../../widgets/badge_celebration_dialog.dart';

class AddFoodLogScreen extends StatefulWidget {
  const AddFoodLogScreen({Key? key}) : super(key: key);

  @override
  State<AddFoodLogScreen> createState() => _AddFoodLogScreenState();
}

class _AddFoodLogScreenState extends State<AddFoodLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  late String _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    ActivityLogService.instance.logEvent('screen_view', screen: 'AddFoodLogScreen');
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _selectedCategory = _autoDetectCategory(_selectedTime);
  }

  /// Auto-detect meal category based on current time
  String _autoDetectCategory(TimeOfDay time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 10) return 'breakfast';
    if (hour >= 10 && hour < 15) return 'lunch';
    if (hour >= 15 && hour < 18) return 'snack';
    return 'dinner'; // 18-04
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'breakfast': return '🌅 Sarapan';
      case 'lunch': return '☀️ Makan Siang';
      case 'dinner': return '🌙 Makan Malam';
      case 'snack': return '🍪 Camilan';
      default: return category;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100, // We will compress it manually
      );
      if (pickedFile != null) {
        final compressedFile = await _compressImage(File(pickedFile.path));
        setState(() => _imageFile = compressedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error picking image')),
      );
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final targetPath = '${dir.path}/food_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // compressAndGetFile returns XFile?, get path from it
      final xResult = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 800,
        minHeight: 800,
      );

      if (xResult != null) {
        final compressed = File(xResult.path);
        if (compressed.existsSync() && compressed.lengthSync() > 0) {
          print('[ImageCompress] OK → ${compressed.path} (${compressed.lengthSync()} bytes)');
          return compressed;
        }
      }
      print('[ImageCompress] fallback to original: ${file.path}');
      return file; // Fallback to original if compression fails
    } catch (e) {
      print('[ImageCompress] error: $e — using original file');
      return file;
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ambil Foto Makanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_camera, color: AppTheme.primary),
                ),
                title: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ambil foto langsung'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: AppTheme.accent),
                ),
                title: const Text('Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pilih dari galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedCategory = _autoDetectCategory(picked);
      });
    }
  }

  Future<void> _save() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📷 Silakan ambil foto makanan terlebih dahulu'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    // Verify the file still exists on disk
    if (!_imageFile!.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ File foto tidak ditemukan. Ambil foto ulang.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    print('[AddFoodLog] Photo path: ${_imageFile!.path}');
    print('[AddFoodLog] Photo exists: ${_imageFile!.existsSync()}');
    print('[AddFoodLog] Photo size: ${_imageFile!.lengthSync()} bytes');

    // Food name will be filled by AI on server side
    final newLog = FoodLog(
      foodName: 'Menganalisis...',
      category: _selectedCategory,
      mealTime: finalDateTime,
      nutritionNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      photoPath: _imageFile!.path,
    );

    final newBadges = await Provider.of<FoodLogProvider>(context, listen: false).addLog(newLog);

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (newBadges.isNotEmpty || true) {
      // Refresh AuthProvider profile to update Carbon footprint & points & badge codes
      await Provider.of<AuthProvider>(context, listen: false).init();
      // Also refresh the provider's badge list
      await Provider.of<AuthProvider>(context, listen: false).refreshBadges();
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Food log berhasil ditambahkan!'),
          backgroundColor: AppTheme.success,
        ),
      );

      // Show badge celebration dialogs one by one (sequential awaits)
      for (final badgeMap in newBadges) {
        if (!mounted) break;
        final badge = BadgeModel.fromJson(badgeMap);
        await BadgeCelebrationDialog.show(context, badge);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Food Log'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo Section (Mandatory)
            GestureDetector(
              onTap: _showImagePickerModal,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppTheme.accentLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _imageFile != null ? AppTheme.success : AppTheme.primaryLight, 
                    width: 2,
                  ),
                  image: _imageFile != null 
                    ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: _imageFile == null 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 40, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ambil Foto Makanan',
                          style: TextStyle(
                            color: AppTheme.primaryDark, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wajib • AI akan menganalisis nutrisinya',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Ganti Foto', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Auto-detected Category
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      const Text('Kategori Otomatis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['breakfast', 'lunch', 'dinner', 'snack'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(_getCategoryLabel(cat)),
                        selected: isSelected,
                        selectedColor: AppTheme.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Date & Time
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        prefixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(DateFormat('d MMM yyyy').format(_selectedDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Waktu',
                        prefixIcon: Icon(Icons.access_time, size: 18),
                      ),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Notes (Optional)
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Bahan, porsi, atau detail lainnya...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.note_alt_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // AI Info Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI akan otomatis mengenali makanan dan menghitung kalori, karbohidrat, lemak, dan protein dari foto.',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Save Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                _isSaving ? 'Menyimpan & Menganalisis...' : 'Simpan & Analisis',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
