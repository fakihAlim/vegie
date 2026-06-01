import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/food_log.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_log_provider.dart';
import '../../services/activity_log_service.dart';

class EditFoodLogScreen extends StatefulWidget {
  final FoodLog log;

  const EditFoodLogScreen({Key? key, required this.log}) : super(key: key);

  @override
  State<EditFoodLogScreen> createState() => _EditFoodLogScreenState();
}

class _EditFoodLogScreenState extends State<EditFoodLogScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _proteinController;
  late TextEditingController _notesController;

  late bool _isPlantBased;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    ActivityLogService.instance.logEvent('food_log_view', extraData: {
      'food_log_id': widget.log.id,
      'food_name': widget.log.foodName,
    });
    _nameController = TextEditingController(text: widget.log.foodName);
    _caloriesController = TextEditingController(text: widget.log.calories?.toString() ?? '');
    _carbsController = TextEditingController(text: widget.log.carbs?.toString() ?? '');
    _fatController = TextEditingController(text: widget.log.fat?.toString() ?? '');
    _proteinController = TextEditingController(text: widget.log.protein?.toString() ?? '');
    _notesController = TextEditingController(text: widget.log.nutritionNotes ?? '');
    _isPlantBased = widget.log.points == 50;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _proteinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final updatedLog = widget.log.copyWith(
      foodName: _nameController.text.trim(),
      calories: double.tryParse(_caloriesController.text),
      carbs: double.tryParse(_carbsController.text),
      fat: double.tryParse(_fatController.text),
      protein: double.tryParse(_proteinController.text),
      nutritionNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      points: _isPlantBased ? 50 : -20,
      isSynced: false, // Mark as unsynced so it will push to server
    );
    
    final success = await Provider.of<FoodLogProvider>(context, listen: false).updateLog(updatedLog);
    
    setState(() => _isSaving = false);
    
    if (success && mounted) {
      // Refresh AuthProvider profile to update Carbon footprint & points
      Provider.of<AuthProvider>(context, listen: false).init();

      ActivityLogService.instance.logEvent('food_log_edit', extraData: {
        'food_log_id': widget.log.id,
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Data nutrisi berhasil diperbarui!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Widget _buildImage() {
    if (widget.log.photoPath != null && File(widget.log.photoPath!).existsSync()) {
      return Image.file(
        File(widget.log.photoPath!),
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (widget.log.photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.log.photoUrl!,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 250,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          height: 250,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey),
        ),
      );
    }
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail & Edit Nutrisi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.warning),
            onPressed: () {
              // Confirm delete
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Food Log?'),
                  content: const Text('Data yang dihapus tidak dapat dikembalikan.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx); // Close dialog
                        await Provider.of<FoodLogProvider>(context, listen: false).deleteLog(widget.log);
                        ActivityLogService.instance.logEvent('food_log_delete', extraData: {
                          'food_log_id': widget.log.id,
                        });
                        if (mounted) Navigator.pop(context); // Close screen
                      }, 
                      child: const Text('Hapus', style: TextStyle(color: AppTheme.warning))
                    ),
                  ],
                )
              );
            },
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Makanan',
                      prefixIcon: Icon(Icons.restaurant_menu),
                    ),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Status Makanan Toggle Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isPlantBased ? AppTheme.success.withOpacity(0.3) : AppTheme.warning.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isPlantBased ? Icons.eco_rounded : Icons.warning_amber_rounded,
                              size: 20,
                              color: _isPlantBased ? AppTheme.success : AppTheme.warning,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Status Makanan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() => _isPlantBased = true);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isPlantBased 
                                        ? AppTheme.success.withOpacity(0.1) 
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isPlantBased ? AppTheme.success : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.spa_rounded,
                                        color: _isPlantBased ? AppTheme.success : Colors.grey,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Nabati (Plant-Based)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: _isPlantBased ? FontWeight.bold : FontWeight.normal,
                                          color: _isPlantBased ? AppTheme.success : Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '+50 Poin',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _isPlantBased ? AppTheme.success : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() => _isPlantBased = false);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isPlantBased 
                                        ? AppTheme.warning.withOpacity(0.1) 
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: !_isPlantBased ? AppTheme.warning : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.kebab_dining_rounded,
                                        color: !_isPlantBased ? AppTheme.warning : Colors.grey,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Non-Nabati (Hewani)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: !_isPlantBased ? FontWeight.bold : FontWeight.normal,
                                          color: !_isPlantBased ? AppTheme.warning : Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '-20 Poin',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: !_isPlantBased ? AppTheme.warning : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Data Nutrisi (Per Porsi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Kalori (kcal)',
                            prefixIcon: Icon(Icons.local_fire_department, color: Colors.orange),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _carbsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Karbo (g)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _fatController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Lemak (g)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _proteinController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Protein (g)',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      hintText: 'Bahan tambahan, porsi, dsb...',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.notes),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
