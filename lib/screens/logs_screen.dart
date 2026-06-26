import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final db = await DatabaseHelper.instance.database;
    final logs = await db.query('logs', orderBy: 'timestamp DESC');
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('پاک کردن لاگ', style: GoogleFonts.vazirmatn(color: Colors.white)),
        content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('انصراف', style: GoogleFonts.vazirmatn())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('پاک کردن', style: GoogleFonts.vazirmatn(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('logs');
      _loadLogs();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text('${_logs.length}', style: GoogleFonts.vazirmatn(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('تعداد لاگ‌ها', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _clearLogs,
                icon: const Icon(Icons.delete),
                label: Text('پاک کردن', style: GoogleFonts.vazirmatn()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt_outlined, size: 80, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text('هنوز فعالیتی ثبت نشده', style: GoogleFonts.vazirmatn(color: Colors.grey.shade500)),
                        ],                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final timestamp = DateTime.parse(log['timestamp']);
                        final formattedDate = '${timestamp.year}/${timestamp.month}/${timestamp.day} - ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.history, color: Color(0xFF6366F1), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log['action'], style: GoogleFonts.vazirmatn(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text(log['details'] ?? '', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400)),
                                    const SizedBox(height: 4),
                                    Text(formattedDate, style: GoogleFonts.vazirmatn(fontSize: 10, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }}
