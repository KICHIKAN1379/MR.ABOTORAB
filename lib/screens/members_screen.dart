import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../models/member.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<Member> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('members', orderBy: 'created_at DESC');
    setState(() {
      _members = maps.map((m) => Member.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  Future<void> _addMember() async {
    final result = await showDialog<Member>(
      context: context,
      builder: (context) => const MemberFormDialog(),
    );
    
    if (result != null) {
      final db = await DatabaseHelper.instance.database;
      await db.insert('members', result.toMap());
      await DatabaseHelper.instance.addLog('افزودن عضو', 'عضو "${result.name}" اضافه شد');
      _loadMembers();
    }
  }

  Future<void> _editMember(Member member) async {
    final result = await showDialog<Member>(
      context: context,      builder: (context) => MemberFormDialog(member: member),
    );
    
    if (result != null) {
      final db = await DatabaseHelper.instance.database;
      await db.update('members', result.toMap(), where: 'id = ?', whereArgs: [result.id]);
      await DatabaseHelper.instance.addLog('ویرایش عضو', 'اطلاعات "${result.name}" به‌روز شد');
      _loadMembers();
    }
  }

  Future<void> _deleteMember(Member member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('حذف عضو', style: GoogleFonts.vazirmatn(color: Colors.white)),
        content: Text('آیا از حذف "${member.name}" مطمئن هستید؟', style: GoogleFonts.vazirmatn(color: Colors.grey.shade300)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('انصراف', style: GoogleFonts.vazirmatn()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: GoogleFonts.vazirmatn(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('members', where: 'id = ?', whereArgs: [member.id]);
      await db.delete('group_members', where: 'member_id = ?', whereArgs: [member.id]);
      await db.delete('sessions', where: 'member_id = ?', whereArgs: [member.id]);
      await DatabaseHelper.instance.addLog('حذف عضو', 'عضو "${member.name}" حذف شد');
      _loadMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [              Expanded(
                child: _buildStatCard('تعداد اعضا', '${_members.length}', Icons.people),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'میانگین امتیاز',
                  _members.isEmpty ? '0' : '${(_members.fold(0, (sum, m) => sum + m.points) / _members.length).round()}',
                  Icons.stars,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'بالاترین سطح',
                  _members.isEmpty ? '0' : '${_getLevel(_members.map((m) => m.points).reduce((a, b) => a > b ? a : b)).level}',
                  Icons.emoji_events,
                ),
              ),
            ],
          ),
        ),
        
        // Members List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text(
                            'هنوز عضوی اضافه نشده',
                            style: GoogleFonts.vazirmatn(color: Colors.grey.shade500, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final levelInfo = _getLevel(member.points);
                        return _buildMemberCard(member, levelInfo);
                      },
                    ),        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.2),
            const Color(0xFFEC4899).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.vazirmatn(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.vazirmatn(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member, dynamic levelInfo) {
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
          // Avatar
          CircleAvatar(
            radius: 30,            backgroundColor: const Color(0xFF6366F1),
            backgroundImage: member.avatar != null && member.avatar!.isNotEmpty
                ? (member.avatar!.startsWith('/') ? FileImage(File(member.avatar!)) : null)
                : null,
            child: member.avatar == null || member.avatar!.isEmpty
                ? Text(
                    member.name.isNotEmpty ? member.name[0] : '?',
                    style: GoogleFonts.vazirmatn(fontSize: 24, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                if (member.responsibility != null && member.responsibility!.isNotEmpty)
                  Text(
                    member.responsibility!,
                    style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${levelInfo.emoji} سطح ${levelInfo.level}',
                        style: GoogleFonts.vazirmatn(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${member.points} ⭐',
                      style: GoogleFonts.vazirmatn(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ],                ),
              ],
            ),
          ),
          
          // Actions
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF6366F1)),
                onPressed: () => _editMember(member),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteMember(member),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({int level, String emoji}) _getLevel(int points) {
    const levels = [
      (level: 1, points: 20, emoji: '🌱'),
      (level: 2, points: 50, emoji: '🌿'),
      (level: 3, points: 80, emoji: '🌳'),
      (level: 4, points: 110, emoji: '⭐'),
      (level: 5, points: 140, emoji: '🌟'),
      (level: 6, points: 170, emoji: '✨'),
      (level: 7, points: 200, emoji: '🔥'),
      (level: 8, points: 230, emoji: '⚡'),
      (level: 9, points: 260, emoji: ''),
      (level: 10, points: 290, emoji: '🌙'),
      (level: 11, points: 320, emoji: '☀️'),
      (level: 12, points: 350, emoji: ''),
      (level: 13, points: 380, emoji: '💎'),
      (level: 14, points: 410, emoji: ''),
      (level: 15, points: 440, emoji: '🏆'),
      (level: 16, points: 470, emoji: '🎯'),
      (level: 17, points: 500, emoji: ''),
      (level: 18, points: 530, emoji: '🔮'),
      (level: 19, points: 560, emoji: '🌠'),
      (level: 20, points: 590, emoji: '👼'),
    ];
    
    for (int i = levels.length - 1; i >= 0; i--) {
      if (points >= levels[i].points) {
        return (level: levels[i].level, emoji: levels[i].emoji);      }
    }
    return (level: 0, emoji: '🌱');
  }

  FloatingActionButton get floatingActionButton {
    return FloatingActionButton(
      onPressed: _addMember,
      backgroundColor: const Color(0xFF6366F1),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}

class MemberFormDialog extends StatefulWidget {
  final Member? member;
  const MemberFormDialog({super.key, this.member});

  @override
  State<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _interestsController = TextEditingController();
  final _responsibilityController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _avatarPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _nameController.text = widget.member!.name;
      _birthdateController.text = widget.member!.birthdate ?? '';
      _interestsController.text = widget.member!.interests ?? '';
      _responsibilityController.text = widget.member!.responsibility ?? '';
      _descriptionController.text = widget.member!.description ?? '';
      _avatarPath = widget.member!.avatar;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdateController.dispose();
    _interestsController.dispose();    _responsibilityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _avatarPath = image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.member == null ? '➕ افزودن عضو جدید' : '✏️ ویرایش عضو',
                    style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Avatar
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                  backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                  child: _avatarPath == null
                      ? const Icon(Icons.add_a_photo, size: 30, color: Color(0xFF6366F1))
                      : null,
                ),              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.vazirmatn(color: Colors.white),
                decoration: _inputDecoration('نام *', Icons.person),
                validator: (v) => v == null || v.isEmpty ? 'نام الزامی است' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _birthdateController,
                style: GoogleFonts.vazirmatn(color: Colors.white),
                decoration: _inputDecoration('تاریخ تولد', Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _birthdateController.text = date.toIso8601String().split('T')[0];
                  }
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _interestsController,
                style: GoogleFonts.vazirmatn(color: Colors.white),
                decoration: _inputDecoration('علایق', Icons.favorite),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _responsibilityController,
                style: GoogleFonts.vazirmatn(color: Colors.white),
                decoration: _inputDecoration('مسئولیت', Icons.work),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _descriptionController,
                style: GoogleFonts.vazirmatn(color: Colors.white),
                decoration: _inputDecoration('توضیحات (مخفی)', Icons.description),
                maxLines: 3,
              ),
              const SizedBox(height: 20),              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(
                        context,
                        Member(
                          id: widget.member?.id,
                          name: _nameController.text,
                          birthdate: _birthdateController.text.isEmpty ? null : _birthdateController.text,
                          interests: _interestsController.text.isEmpty ? null : _interestsController.text,
                          responsibility: _responsibilityController.text.isEmpty ? null : _responsibilityController.text,
                          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                          avatar: _avatarPath,
                          points: widget.member?.points ?? 0,
                          createdAt: widget.member?.createdAt ?? DateTime.now().toIso8601String(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.member == null ? 'ذخیره عضو' : 'به‌روزرسانی',
                    style: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
    );
  }
}
