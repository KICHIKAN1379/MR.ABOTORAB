import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../models/member.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Member> _members = [];
  Member? _selectedMember;
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('members', orderBy: 'name');
    setState(() {
      _members = maps.map((m) => Member.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadSessions(int memberId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('sessions', where: 'member_id = ?', whereArgs: [memberId], orderBy: 'date DESC');
    setState(() => _sessions = maps);
  }

  Future<void> _addSession() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا یک عضو انتخاب کنید')),
      );
      return;
    }

    final dateController = TextEditingController();
    final descController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('➕ افزودن جلسه', style: GoogleFonts.vazirmatn(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              readOnly: true,
              style: GoogleFonts.vazirmatn(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'تاریخ جلسه',
                labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
                suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) dateController.text = date.toIso8601String().split('T')[0];
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              style: GoogleFonts.vazirmatn(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'توضیحات جلسه',
                labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('انصراف', style: GoogleFonts.vazirmatn())),
          TextButton(
            onPressed: () async {
              if (dateController.text.isNotEmpty) {                final db = await DatabaseHelper.instance.database;
                await db.insert('sessions', {
                  'member_id': _selectedMember!.id,
                  'date': dateController.text,
                  'description': descController.text,
                  'created_at': DateTime.now().toIso8601String(),
                });
                await DatabaseHelper.instance.addLog('افزودن جلسه', 'جلسه برای ${_selectedMember!.name} در تاریخ ${dateController.text}');
                Navigator.pop(context);
                _loadSessions(_selectedMember!.id!);
              }
            },
            child: Text('ذخیره', style: GoogleFonts.vazirmatn(color: const Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(Map<String, dynamic> session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('حذف جلسه', style: GoogleFonts.vazirmatn(color: Colors.white)),
        content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('انصراف', style: GoogleFonts.vazirmatn())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('حذف', style: GoogleFonts.vazirmatn(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('sessions', where: 'id = ?', whereArgs: [session['id']]);
      await DatabaseHelper.instance.addLog('حذف جلسه', 'جلسه ${session['date']} برای ${_selectedMember!.name} حذف شد');
      _loadSessions(_selectedMember!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Member Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<int>(
            value: _selectedMember?.id,            dropdownColor: const Color(0xFF1E293B),
            style: GoogleFonts.vazirmatn(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'انتخاب عضو',
              labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
              prefixIcon: const Icon(Icons.person, color: Color(0xFF6366F1)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            items: _members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedMember = _members.firstWhere((m) => m.id == v);
              });
              if (v != null) _loadSessions(v);
            },
          ),
        ),
        
        // Sessions List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedMember == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search, size: 80, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text('یک عضو انتخاب کنید', style: GoogleFonts.vazirmatn(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : _sessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 80, color: Colors.grey.shade600),
                              const SizedBox(height: 16),
                              Text('هنوز جلسه‌ای ثبت نشده', style: GoogleFonts.vazirmatn(color: Colors.grey.shade500)),
                            ],
                          ),
                        )                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            final session = _sessions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                    child: const Icon(Icons.event, color: Color(0xFF6366F1)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('📅 ${session['date']}', style: GoogleFonts.vazirmatn(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
                                        if (session['description'] != null && session['description'].toString().isNotEmpty)
                                          const SizedBox(height: 4),
                                        if (session['description'] != null && session['description'].toString().isNotEmpty)
                                          Text(session['description'], style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade300)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteSession(session),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
