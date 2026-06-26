import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../models/member.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  List<Member> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('members', orderBy: 'points DESC');
    setState(() {
      _members = maps.map((m) => Member.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  Future<void> _changePoints(Member member) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('تغییر امتیاز ${member.name}', style: GoogleFonts.vazirmatn(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('امتیاز فعلی: ${member.points}', style: GoogleFonts.vazirmatn(color: Colors.grey.shade300)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.vazirmatn(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'مقدار تغییر (مثبت یا منفی)',
                labelStyle: GoogleFonts.vazirmatn(color: Colors.grey),                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('انصراف', style: GoogleFonts.vazirmatn())),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) Navigator.pop(context, value);
            },
            child: Text('تایید', style: GoogleFonts.vazirmatn(color: const Color(0xFF6366F1))),
          ),
        ],
      ),
    );

    if (result != null) {
      final db = await DatabaseHelper.instance.database;
      final newPoints = (member.points + result).clamp(0, 99999);
      await db.update('members', {'points': newPoints}, where: 'id = ?', whereArgs: [member.id]);
      await DatabaseHelper.instance.addLog('تغییر امتیاز', '${member.name}: ${member.points} → $newPoints (${result > 0 ? '+' : ''}$result)');
      _loadMembers();
      
      final oldLevel = _getLevel(member.points).level;
      final newLevel = _getLevel(newPoints).level;
      if (newLevel > oldLevel) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ${member.name} به سطح $newLevel رسید!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    }
  }

  ({int level, String emoji}) _getLevel(int points) {
    const levels = [
      (level: 1, points: 20, emoji: '🌱'), (level: 2, points: 50, emoji: '🌿'),
      (level: 3, points: 80, emoji: '🌳'), (level: 4, points: 110, emoji: '⭐'),
      (level: 5, points: 140, emoji: '🌟'), (level: 6, points: 170, emoji: '✨'),
      (level: 7, points: 200, emoji: '🔥'), (level: 8, points: 230, emoji: '⚡'),
      (level: 9, points: 260, emoji: '💫'), (level: 10, points: 290, emoji: ''),
      (level: 11, points: 320, emoji: '☀️'), (level: 12, points: 350, emoji: '🌈'),      (level: 13, points: 380, emoji: '💎'), (level: 14, points: 410, emoji: '🔷'),
      (level: 15, points: 440, emoji: '🏆'), (level: 16, points: 470, emoji: '🎯'),
      (level: 17, points: 500, emoji: '👑'), (level: 18, points: 530, emoji: ''),
      (level: 19, points: 560, emoji: ''), (level: 20, points: 590, emoji: '👼'),
    ];
    for (int i = levels.length - 1; i >= 0; i--) {
      if (points >= levels[i].points) return (level: levels[i].level, emoji: levels[i].emoji);
    }
    return (level: 0, emoji: '🌱');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '⭐ سیستم امتیازات - سطح ۱ = ۲ امتیاز، هر سطح +۳۰',
            style: GoogleFonts.vazirmatn(color: Colors.grey.shade400, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stars_outlined, size: 80, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text('هنوز عضوی وجود ندارد', style: GoogleFonts.vazirmatn(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final levelInfo = _getLevel(member.points);
                        final nextLevel = levelInfo.level < 20 ? _getLevel(levelInfo.level == 0 ? 20 : [0,20,50,80,110,140,170,200,230,260,290,320,350,380,410,440,470,500,530,560,590][levelInfo.level]) : null;
                        final progress = nextLevel != null ? ((member.points - (levelInfo.level == 0 ? 0 : [0,20,50,80,110,140,170,200,230,260,290,320,350,380,410,440,470,500,530,560][levelInfo.level])) / 30 * 100).clamp(0.0, 100.0) : 100.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(                            color: const Color(0xFF1E293B).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: const Color(0xFF6366F1),
                                    child: Text(member.name.isNotEmpty ? member.name[0] : '?', style: GoogleFonts.vazirmatn(color: Colors.white)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(member.name, style: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                        Text('${levelInfo.emoji} سطح ${levelInfo.level}', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400)),
                                      ],
                                    ),
                                  ),
                                  Text('${member.points}', style: GoogleFonts.vazirmatn(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress / 100,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _changePoints(member),
                                  icon: const Icon(Icons.stars),
                                  label: Text('تغییر امتیاز', style: GoogleFonts.vazirmatn()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),                              ),
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
