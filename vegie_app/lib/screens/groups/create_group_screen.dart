import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/group_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final response = await Provider.of<GroupProvider>(context, listen: false)
        .createGroup(_nameController.text.trim(), _descController.text.trim());

    setState(() => _isSubmitting = false);

    if (response['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grup berhasil dibuat! Kode: ${response['data']?['code'] ?? ''}'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Gagal membuat grup'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Buat Grup Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Illustration
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.groups_outlined, size: 64, color: AppTheme.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Buat komunitas vegetarian Anda!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kode undangan unik akan dibuat otomatis.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Name
              const Text('Nama Grup *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Vegetarian Jakarta',
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama grup wajib diisi' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),

              // Description
              const Text('Deskripsi (opsional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  hintText: 'Ceritakan tentang grup ini...',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 40),

              // Submit
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Buat Grup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
