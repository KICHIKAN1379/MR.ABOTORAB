import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../models/member.dart';
import '../models/group.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  List<Member> _members = [];
  List<Group> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final memberMaps = await db.query('members', orderBy: 'points DESC');
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

  ({int level, String emoji}) _getLevel(int points) {    const levels = [
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
    ];
    for (int i = levels.length - 1; i >= 0; i--) {
      if (points >= levels[i].points) return (level: levels[i].level, emoji: levels[i].emoji);
    }
    return (level: 0, emoji: '🌱');
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Members Ranking
                Container(
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
                          const Icon(Icons.leaderboard, color: Color(0xFF6366F1), size: 28),
                          const SizedBox(width: 8),
                          Text('رتبه‌بندی اعضا', style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_members.isEmpty)
                        Center(
                          child: Text('هنوز عضوی وجود ندارد', style: GoogleFonts.vazirmatn(color: Colors.grey.shade500)),
                        )
                      else                        ..._members.asMap().entries.map((entry) {
                          final index = entry.key;
                          final member = entry.value;
                          final levelInfo = _getLevel(member.points);
                          final isTop3 = index < 3;
                          final medals = ['🥇', '', '🥉'];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: isTop3
                                  ? LinearGradient(colors: [
                                      const Color(0xFF6366F1).withOpacity(0.2),
                                      const Color(0xFFEC4899).withOpacity(0.2),
                                    ])
                                  : null,
                              color: isTop3 ? null : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isTop3 ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isTop3 ? medals[index] : '${index + 1}',
                                      style: GoogleFonts.vazirmatn(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
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
                                Text('${member.points} ⭐', style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Groups Ranking
                Container(
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
                          const Icon(Icons.group_work, color: Color(0xFFEC4899), size: 28),
                          const SizedBox(width: 8),
                          Text('رتبه‌بندی گروه‌ها', style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_groups.isEmpty)
                        Center(
                          child: Text('هنوز گروهی وجود ندارد', style: GoogleFonts.vazirmatn(color: Colors.grey.shade500)),
                        )
                      else
                        ..._groups.asMap().entries.map((entry) {
                          final index = entry.key;
                          final group = entry.value;
                          final groupMembers = _members.where((m) => group.memberIds.contains(m.id)).toList();
                          final totalPoints = groupMembers.fold(0, (sum, m) => sum + m.points);
                          final isTop3 = index < 3;
                          final medals = ['', '🥈', '🥉'];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: isTop3
                                  ? LinearGradient(colors: [
                                      const Color(0xFFEC4899).withOpacity(0.2),
                                      const Color(0xFF6366F1).withOpacity(0.2),
                                    ])                                  : null,
                              color: isTop3 ? null : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isTop3 ? const Color(0xFFEC4899) : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF6366F1)]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isTop3 ? medals[index] : '${index + 1}',
                                      style: GoogleFonts.vazirmatn(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(group.name, style: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text('${groupMembers.length} عضو', style: GoogleFonts.vazirmatn(fontSize: 12, color: Colors.grey.shade400)),
                                    ],
                                  ),
                                ),
                                Text('$totalPoints ⭐', style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
