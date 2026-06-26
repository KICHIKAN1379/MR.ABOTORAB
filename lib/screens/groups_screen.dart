import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../models/member.dart';
import '../models/group.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Group> _groups = [];
  List<Member> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final memberMaps = await db.query('members');
    final groupMaps = await db.query('groups');
    final groupMemberMaps = await db.query('group_members');

    final members = memberMaps.map((m) => Member.fromMap(m)).toList();
    final groups = <Group>[];
    
    for (final gm in groupMaps) {
      final group = Group.fromMap(gm);
      final memberIds = groupMemberMaps
          .where((x) => x['group_id'] == group.id)
          .map((x) => x['member_id'] as int)
          .toList();
      groups.add(group.copyWith(memberIds: memberIds));
    }

    setState(() {
      _members = members;
      _groups = groups;
      _isLoading = false;
    });
  }

  Future<void> _addGroup() async {    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا باید اعضا را اضافه کنید')),
      );
      return;
    }

    final nameController = TextEditingController();
    int? selectedLeaderId;
    final selectedMemberIds = <int>{};

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('➕ ایجاد گروه جدید', style: GoogleFonts.vazirmatn(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'نام گروه',
                    labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('سرگروه:', style: GoogleFonts.vazirmatn(color: Colors.white)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedLeaderId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                  onChanged: (v) => setState(() => selectedLeaderId = v),
                ),
                const SizedBox(height: 16),
                Text('اعضای گروه:', style: GoogleFonts.vazirmatn(color: Colors.white)),
                const SizedBox(height: 8),                ..._members.map((m) => CheckboxListTile(
                  value: selectedMemberIds.contains(m.id),
                  title: Text(m.name, style: GoogleFonts.vazirmatn(color: Colors.white)),
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) selectedMemberIds.add(m.id!);
                      else selectedMemberIds.remove(m.id);
                    });
                  },
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('انصراف', style: GoogleFonts.vazirmatn())),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedLeaderId != null) {
                  Navigator.pop(context, {'name': nameController.text, 'leaderId': selectedLeaderId, 'memberIds': selectedMemberIds.toList()});
                }
              },
              child: Text('ایجاد', style: GoogleFonts.vazirmatn(color: const Color(0xFF6366F1))),
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result != null) {
        final db = await DatabaseHelper.instance.database;
        final now = DateTime.now().toIso8601String();
        final groupId = await db.insert('groups', {
          'name': result['name'],
          'leader_id': result['leaderId'],
          'points': 0,
          'created_at': now,
        });
        
        final allMemberIds = <int>{result['leaderId'], ...result['memberIds']}.toList();
        for (final mid in allMemberIds) {
          await db.insert('group_members', {'group_id': groupId, 'member_id': mid});
        }
        
        await DatabaseHelper.instance.addLog('ایجاد گروه', 'گروه "${result['name']}" ایجاد شد');
        _loadData();
      }
    });
  }

  Future<void> _deleteGroup(Group group) async {    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('حذف گروه', style: GoogleFonts.vazirmatn(color: Colors.white)),
        content: Text('آیا از حذف "${group.name}" مطمئن هستید؟', style: GoogleFonts.vazirmatn(color: Colors.grey.shade300)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('انصراف', style: GoogleFonts.vazirmatn())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('حذف', style: GoogleFonts.vazirmatn(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('group_members', where: 'group_id = ?', whereArgs: [group.id]);
      await db.delete('groups', where: 'id = ?', whereArgs: [group.id]);
      await DatabaseHelper.instance.addLog('حذف گروه', 'گروه "${group.name}" حذف شد');
      _loadData();
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
                      Text('${_groups.length}', style: GoogleFonts.vazirmatn(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('تعداد گروه‌ها', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Text('${_members.length}', style: GoogleFonts.vazirmatn(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
                      Text('تعداد اعضا', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_work_outlined, size: 80, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text('هنوز گروهی ایجاد نشده', style: GoogleFonts.vazirmatn(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        final leader = _members.firstWhere((m) => m.id == group.leaderId, orElse: () => Member(name: 'نامشخص', createdAt: ''));
                        final groupMembers = _members.where((m) => group.memberIds.contains(m.id)).toList();
                        final totalPoints = groupMembers.fold(0, (sum, m) => sum + m.points);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.group_work, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(group.name, style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                        Text('${groupMembers.length} عضو', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteGroup(group),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('👑 سرگروه: ${leader.name}', style: GoogleFonts.vazirmatn(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text('اعضا:', style: GoogleFonts.vazirmatn(color: Colors.grey.shade400, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: groupMembers.map((m) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(m.name, style: GoogleFonts.vazirmatn(fontSize: 11, color: const Color(0xFF10B981))),
                                      )).toList(),                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('مجموع امتیاز گروه: ', style: GoogleFonts.vazirmatn(color: Colors.white70)),
                                    Text('$totalPoints ⭐', style: GoogleFonts.vazirmatn(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
  }
}
