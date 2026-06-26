import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../models/member.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  List<Map<String, dynamic>> _rewards = [];
  List<Member> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final rewardMaps = await db.query('rewards', orderBy: 'required_level ASC');
    final memberMaps = await db.query('members');

    setState(() {
      _rewards = rewardMaps;
      _members = memberMaps.map((m) => Member.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  ({int level, String emoji}) _getLevel(int points) {
    const levels = [
      (level: 1, points: 20, emoji: '🌱'), (level: 2, points: 50, emoji: '🌿'),
      (level: 3, points: 80, emoji: '🌳'), (level: 4, points: 110, emoji: '⭐'),
      (level: 5, points: 140, emoji: '🌟'), (level: 6, points: 170, emoji: '✨'),
      (level: 7, points: 200, emoji: '🔥'), (level: 8, points: 230, emoji: '⚡'),
      (level: 9, points: 260, emoji: '💫'), (level: 10, points: 290, emoji: ''),
      (level: 11, points: 320, emoji: '☀️'), (level: 12, points: 350, emoji: '🌈'),
      (level: 13, points: 380, emoji: '💎'), (level: 14, points: 410, emoji: '🔷'),
      (level: 15, points: 440, emoji: '🏆'), (level: 16, points: 470, emoji: ''),
      (level: 17, points: 500, emoji: ''), (level: 18, points: 530, emoji: ''),
      (level: 19, points: 560, emoji: ''), (level: 20, points: 590, emoji: '👼'),
    ];    for (int i = levels.length - 1; i >= 0; i--) {
      if (points >= levels[i].points) return (level: levels[i].level, emoji: levels[i].emoji);
    }
    return (level: 0, emoji: '🌱');
  }

  Future<void> _addReward() async {
    final nameController = TextEditingController();
    int? selectedLevel;
    String? imagePath;
    final picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('➕ افزودن جایزه', style: GoogleFonts.vazirmatn(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() => imagePath = image.path);
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(imagePath!), fit: BoxFit.cover),
                          )
                        : const Icon(Icons.add_a_photo, size: 40, color: Color(0xFF6366F1)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                  decoration: InputDecoration(                    labelText: 'نام جایزه',
                    labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedLevel,
                  dropdownColor: const Color(0xFF1E293B),
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'سطح مورد نیاز',
                    labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: List.generate(20, (i) => DropdownMenuItem(value: i + 1, child: Text('سطح ${i + 1}'))),
                  onChanged: (v) => setState(() => selectedLevel = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('انصراف', style: GoogleFonts.vazirmatn())),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedLevel != null) {
                  Navigator.pop(context, {'name': nameController.text, 'level': selectedLevel, 'image': imagePath});
                }
              },
              child: Text('ذخیره', style: GoogleFonts.vazirmatn(color: const Color(0xFF6366F1))),
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result != null) {
        final db = await DatabaseHelper.instance.database;
        await db.insert('rewards', {
          'name': result['name'],
          'required_level': result['level'],
          'image': result['image'],
          'created_at': DateTime.now().toIso8601String(),
        });
        await DatabaseHelper.instance.addLog('افزودن جایزه', 'جایزه "${result['name']}" برای سطح ${result['level']} اضافه شد');
        _loadData();
      }    });
  }

  Future<void> _deleteReward(Map<String, dynamic> reward) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('حذف جایزه', style: GoogleFonts.vazirmatn(color: Colors.white)),
        content: Text('آیا از حذف "${reward['name']}" مطمئن هستید؟', style: GoogleFonts.vazirmatn(color: Colors.grey.shade300)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('انصراف', style: GoogleFonts.vazirmatn())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('حذف', style: GoogleFonts.vazirmatn(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('rewards', where: 'id = ?', whereArgs: [reward['id']]);
      await DatabaseHelper.instance.addLog('حذف جایزه', 'جایزه "${reward['name']}" حذف شد');
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('جوایز', style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${_rewards.length} جایزه تعریف شده', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _rewards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard_outlined, size: 80, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text('هنوز جایزه‌ای اضافه نشده', style: GoogleFonts.vazirmatn(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _rewards.length,
                      itemBuilder: (context, index) {
                        final reward = _rewards[index];
                        final eligibleMembers = _members.where((m) => _getLevel(m.points).level >= reward['required_level']).toList();
                        
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
                              Row(
                                children: [
                                  if (reward['image'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(reward['image']),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.card_giftcard, color: Colors.white, size: 40),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(reward['name'], style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('سطح ${reward['required_level']} مورد نیاز', style: GoogleFonts.vazirmatn(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteReward(reward),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('اعضای واجد شرایط (${eligibleMembers.length} نفر):', style: GoogleFonts.vazirmatn(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    if (eligibleMembers.isEmpty)
                                      Text('هنوز کسی به این سطح نرسیده', style: GoogleFonts.vazirmatn(color: Colors.grey.shade400, fontSize: 12))
                                    else
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,                                        children: eligibleMembers.map((m) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(m.name, style: GoogleFonts.vazirmatn(fontSize: 11, color: const Color(0xFF10B981))),
                                        )).toList(),
                                      ),
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
