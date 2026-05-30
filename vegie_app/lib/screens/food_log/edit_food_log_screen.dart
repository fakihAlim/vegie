import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/food_log.dart';
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
      isSynced: false, // Mark as unsynced so it will push to server
    );
    
    final success = await Provider.of<FoodLogProvider>(context, listen: false).updateLog(updatedLog);
    
    setState(() => _isSaving = false);
    
    if (success && mounted) {
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
      return Image.network(
        widget.log.photoUrl!,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
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
