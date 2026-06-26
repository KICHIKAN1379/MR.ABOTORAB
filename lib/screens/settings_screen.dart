import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportData(BuildContext context) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final members = await db.query('members');
      final groups = await db.query('groups');
      final groupMembers = await db.query('group_members');
      final sessions = await db.query('sessions');
      final rewards = await db.query('rewards');
      final logs = await db.query('logs');

      final data = {
        'members': members,
        'groups': groups,
        'group_members': groupMembers,
        'sessions': sessions,
        'rewards': rewards,
        'logs': logs,
        'export_date': DateTime.now().toIso8601String(),
      };

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/halghe_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(data.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'پشتیبان برنامه مدیریت حلقه');
      await DatabaseHelper.instance.addLog('پشتیبان‌گیری', 'فایل پشتیبان ایجاد و به اشتراک گذاشته شد');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فایل پشتیبان ایجاد شد', style: GoogleFonts.vazirmatn()), backgroundColor: const Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e', style: GoogleFonts.vazirmatn()), backgroundColor: Colors.red),
        );
      }
    }
  }
  Future<void> _importData(BuildContext context) async {
    // Note: Full import implementation would require file picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('قابلیت وارد کردن داده در نسخه بعدی اضافه می‌شود', style: GoogleFonts.vazirmatn()), backgroundColor: const Color(0xFF6366F1)),
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('⚠️ پاک کردن تمام داده‌ها', style: GoogleFonts.vazirmatn(color: Colors.white)),
        content: Text('آیا مطمئن هستید؟ تمام اطلاعات حذف خواهد شد و قابل بازگشت نیست!', style: GoogleFonts.vazirmatn(color: Colors.grey.shade300)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('انصراف', style: GoogleFonts.vazirmatn())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('حذف همه', style: GoogleFonts.vazirmatn(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('members');
      await db.delete('groups');
      await db.delete('group_members');
      await db.delete('sessions');
      await db.delete('rewards');
      await db.delete('logs');
      await DatabaseHelper.instance.addLog('پاک کردن', 'تمام داده‌ها پاک شدند');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تمام داده‌ها پاک شدند', style: GoogleFonts.vazirmatn()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Backup Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text('پشتیبان‌گیری و بازیابی', style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('اطلاعات خود را ذخیره یا بازیابی کنید', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Export Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.download, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ذخیره اطلاعات', style: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('دانلود فایل پشتیبان', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _exportData(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),                  ),
                  child: Text('ذخیره', style: GoogleFonts.vazirmatn()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Import Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.upload, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('آپلود اطلاعات', style: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('بازیابی از فایل پشتیبان', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _importData(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('آپلود', style: GoogleFonts.vazirmatn()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Clear All Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_sweep, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('پاک کردن همه داده‌ها', style: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('حذف تمام اطلاعات برنامه', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _clearAllData(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('حذف', style: GoogleFonts.vazirmatn()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 32),
                const SizedBox(height: 12),
                Text('درباره برنامه', style: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('MR.ABOTORAB - برنامه مدیریت اعضای حلقه', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400)),
                const SizedBox(height: 4),
                Text('نسخه 1.0.0', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
