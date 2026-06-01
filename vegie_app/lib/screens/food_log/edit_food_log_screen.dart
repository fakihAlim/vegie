import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/food_log.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_log_provider.dart';
import '../../services/activity_log_service.dart';

class EditFoodLogScreen extends StatefulWidget {
  final FoodLog log;

  const EditFoodLogScreen({super.key, required this.log});

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
  List<Map<String, dynamic>> _items = [];

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
    
    if (widget.log.rawResponse != null) {
      try {
        final parsed = jsonDecode(widget.log.rawResponse!);
        if (parsed['items'] != null && parsed['items'] is List) {
          _items = List<Map<String, dynamic>>.from(
            (parsed['items'] as List).map((x) => Map<String, dynamic>.from(x))
          );
        }
      } catch (e) {
        debugPrint("Error parsing rawResponse: $e");
      }
    }
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
      rawResponse: _items.isNotEmpty ? jsonEncode({'items': _items}) : null,
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

  void _recalculateTotals() {
    if (_items.isEmpty) {
      setState(() {
        _caloriesController.text = '0';
        _carbsController.text = '0.0';
        _fatController.text = '0.0';
        _proteinController.text = '0.0';
      });
      return;
    }
    
    double totalCalories = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalProtein = 0;

    for (var item in _items) {
      totalCalories += (item['kalori'] != null ? (item['kalori'] as num).toDouble() : 0.0);
      totalCarbs += (item['karbohidrat'] != null ? (item['karbohidrat'] as num).toDouble() : 0.0);
      totalFat += (item['lemak'] != null ? (item['lemak'] as num).toDouble() : 0.0);
      totalProtein += (item['protein'] != null ? (item['protein'] as num).toDouble() : 0.0);
    }

    setState(() {
      _caloriesController.text = totalCalories.toStringAsFixed(0);
      _carbsController.text = totalCarbs.toStringAsFixed(1);
      _fatController.text = totalFat.toStringAsFixed(1);
      _proteinController.text = totalProtein.toStringAsFixed(1);
    });
  }

  void _showEditItemDialog({int? index}) {
    final isEditing = index != null;
    final item = isEditing ? _items[index] : null;

    final nameController = TextEditingController(text: item?['nama'] ?? '');
    final calController = TextEditingController(text: item?['kalori']?.toString() ?? '');
    final carbsController = TextEditingController(text: item?['karbohidrat']?.toString() ?? '');
    final fatController = TextEditingController(text: item?['lemak']?.toString() ?? '');
    final protController = TextEditingController(text: item?['protein']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEditing ? 'Edit Bahan Makanan' : 'Tambah Bahan Makanan',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Bahan',
                  hintText: 'Contoh: Tempe',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: calController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kalori (kcal)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: carbsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Karbohidrat (g)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Lemak (g)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: protController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Protein (g)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama bahan wajib diisi!')),
                );
                return;
              }
              
              final newItem = {
                'nama': nameController.text.trim(),
                'kalori': double.tryParse(calController.text) ?? 0.0,
                'karbohidrat': double.tryParse(carbsController.text) ?? 0.0,
                'lemak': double.tryParse(fatController.text) ?? 0.0,
                'protein': double.tryParse(protController.text) ?? 0.0,
              };

              setState(() {
                if (isEditing) {
                  _items[index] = newItem;
                } else {
                  _items.add(newItem);
                }
              });

              _recalculateTotals();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.list_alt_rounded, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Komposisi Bahan Makanan (AI)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showEditItemDialog(),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppTheme.primary),
                label: const Text(
                  'Tambah',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                'Tidak ada rincian bahan makanan.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final double itemCal = item['kalori'] != null ? (item['kalori'] as num).toDouble() : 0.0;
                final double itemCarbs = item['karbohidrat'] != null ? (item['karbohidrat'] as num).toDouble() : 0.0;
                final double itemFat = item['lemak'] != null ? (item['lemak'] as num).toDouble() : 0.0;
                final double itemProtein = item['protein'] != null ? (item['protein'] as num).toDouble() : 0.0;

                return Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    title: Text(
                      item['nama'] ?? 'Bahan',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${itemCal.toStringAsFixed(0)} kcal • K ${itemCarbs.toStringAsFixed(1)}g • L ${itemFat.toStringAsFixed(1)}g • P ${itemProtein.toStringAsFixed(1)}g',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showEditItemDialog(index: index),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _items.removeAt(index);
                            });
                            _recalculateTotals();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
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
                        if (!context.mounted) return;
                        Navigator.pop(context); // Close screen
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
                        color: _isPlantBased ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.warning.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
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
                                        ? AppTheme.success.withValues(alpha: 0.1) 
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
                                        ? AppTheme.warning.withValues(alpha: 0.1) 
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
                  
                  _buildIngredientsSection(),
                  
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
