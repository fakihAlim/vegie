import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../services/local_notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0); // Default to 8:00 PM
  bool _allowEggs = false;
  bool _allowMilk = false;
  bool _allowHoney = false;
  bool _restrictAlliums = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads stored reminder settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isReminderEnabled = prefs.getBool('is_reminder_enabled') ?? false;
      final int? hour = prefs.getInt('reminder_hour');
      final int? minute = prefs.getInt('reminder_minute');
      if (hour != null && minute != null) {
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      }
      _allowEggs = prefs.getBool('diet_allow_eggs') ?? false;
      _allowMilk = prefs.getBool('diet_allow_milk') ?? false;
      _allowHoney = prefs.getBool('diet_allow_honey') ?? false;
      _restrictAlliums = prefs.getBool('diet_restrict_alliums') ?? false;
    });
  }

  /// Saves reminder settings and updates the scheduled local notification
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_reminder_enabled', _isReminderEnabled);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);

    if (_isReminderEnabled) {
      await LocalNotificationService.scheduleDailyReminder(_reminderTime);
    } else {
      await LocalNotificationService.cancelReminder();
    }
  }

  /// Sets diet preference setting dynamically and saves to SharedPreferences
  Future<void> _setDietSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'diet_allow_eggs') _allowEggs = value;
      if (key == 'diet_allow_milk') _allowMilk = value;
      if (key == 'diet_allow_honey') _allowHoney = value;
      if (key == 'diet_restrict_alliums') _restrictAlliums = value;
    });
  }

  /// Shows the Time Picker dialog to select reminder time
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary, // Forest Green header and selections
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
        _isReminderEnabled = true; // Auto-enable reminder when time is picked
      });
      await _saveSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengingat harian dijadwalkan pada ${_reminderTime.format(context)} ⏰'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Header / Title card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pengingat Harian',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bantu bangun kebiasaan mencatat food log agar diet plant-based kamu tetap terpantau.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Settings Options Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                // Toggle Switch
                SwitchListTile(
                  activeThumbColor: AppTheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: const Text(
                    'Aktifkan Pengingat',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    _isReminderEnabled 
                        ? 'Pengingat aktif setiap hari pada jam ${_reminderTime.format(context)}' 
                        : 'Pengingat saat ini dinonaktifkan',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  value: _isReminderEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _isReminderEnabled = value;
                    });
                    await _saveSettings();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value 
                            ? 'Pengingat harian diaktifkan! ⏰' 
                            : 'Pengingat harian dinonaktifkan'),
                        backgroundColor: value ? AppTheme.primary : AppTheme.error,
                      ),
                    );
                  },
                ),
                
                Divider(color: Colors.grey.shade100, height: 1, thickness: 1),

                // Time picker row
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  title: const Text(
                    'Jam Pengingat',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    'Pilih jam terbaik untuk menerima notifikasi',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _reminderTime.format(context),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Diet Exceptions Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pengecualian Diet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sesuaikan penilaian food log berdasarkan aturan khusus diet plant-based Anda.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
                
                // Allow Eggs
                SwitchListTile(
                  activeThumbColor: AppTheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: const Text(
                    'Bolehkan Telur',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    'Telur dan olahannya tidak dideteksi sebagai hewani.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  value: _allowEggs,
                  onChanged: (bool val) => _setDietSetting('diet_allow_eggs', val),
                ),
                Divider(color: Colors.grey.shade50, height: 1, thickness: 1),

                // Allow Milk
                SwitchListTile(
                  activeThumbColor: AppTheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: const Text(
                    'Bolehkan Susu & Produk Susu',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    'Susu, keju, mentega tidak dideteksi sebagai hewani.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  value: _allowMilk,
                  onChanged: (bool val) => _setDietSetting('diet_allow_milk', val),
                ),
                Divider(color: Colors.grey.shade50, height: 1, thickness: 1),

                // Allow Honey
                SwitchListTile(
                  activeThumbColor: AppTheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: const Text(
                    'Bolehkan Madu',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    'Madu tidak dideteksi sebagai hewani.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  value: _allowHoney,
                  onChanged: (bool val) => _setDietSetting('diet_allow_honey', val),
                ),
                Divider(color: Colors.grey.shade50, height: 1, thickness: 1),

                // Restrict Alliums
                SwitchListTile(
                  activeThumbColor: AppTheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: const Text(
                    'Batasi Bawang & Turunannya',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    'Deteksi bawang, bawang putih, daun bawang sebagai non-nabati.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  value: _restrictAlliums,
                  onChanged: (bool val) => _setDietSetting('diet_restrict_alliums', val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
