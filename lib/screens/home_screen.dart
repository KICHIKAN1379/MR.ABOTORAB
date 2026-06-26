import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';
import 'members_screen.dart';
import 'points_screen.dart';
import 'groups_screen.dart';
import 'sessions_screen.dart';
import 'rankings_screen.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';
import 'logs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    MembersScreen(),
    PointsScreen(),
    GroupsScreen(),
    SessionsScreen(),
    RankingsScreen(),
    RewardsScreen(),
    SettingsScreen(),
    LogsScreen(),
  ];

  final List<String> _titles = [
    'اعضا',
    'امتیازات',
    'گروه‌ها',
    'جلسات',
    'رتبه‌بندی',
    'جوایز',
    'تنظیمات',
    'لاگ',
  ];

  final List<IconData> _icons = [
    Icons.people,
    Icons.stars,
    Icons.group_work,
    Icons.event,    Icons.leaderboard,
    Icons.card_giftcard,
    Icons.settings,
    Icons.list_alt,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MR.ABOTORAB',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,                            ),
                          ),
                          Text(
                            _titles[_currentIndex],
                            style: GoogleFonts.vazirmatn(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF6366F1).withOpacity(0.2),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },          destinations: [
            NavigationDestination(
              icon: Icon(_icons[0], color: _currentIndex == 0 ? const Color(0xFF6366F1) : Colors.grey),
              label: _titles[0],
            ),
            NavigationDestination(
              icon: Icon(_icons[1], color: _currentIndex == 1 ? const Color(0xFF6366F1) : Colors.grey),
              label: _titles[1],
            ),
            NavigationDestination(
              icon: Icon(_icons[2], color: _currentIndex == 2 ? const Color(0xFF6366F1) : Colors.grey),
              label: _titles[2],
            ),
            NavigationDestination(
              icon: Icon(_icons[3], color: _currentIndex == 3 ? const Color(0xFF6366F1) : Colors.grey),
              label: _titles[3],
            ),
            NavigationDestination(
              icon: Icon(_icons[4], color: _currentIndex == 4 ? const Color(0xFF6366F1) : Colors.grey),
              label: _titles[4],
            ),
            NavigationDestination(
              icon: Icon(_icons[5], color: _currentIndex == 5 ? const Color(0xFF6366F1) : Colors.grey),
              label: _titles[5],
            ),
            NavigationDestination(
              icon: Icon(_icons[6], color: _currentIndex == 6 ? const Color(0xFF6366F1) : Colors.grey),
              label: _titles[6],
            ),
            NavigationDestination(
              icon: Icon(_icons[7], color: _currentIndex == 7 ? const Color(0xFF6366F1) : Colors.grey),
              label: _titles[7],
            ),
          ],
        ),
      ),
    );
  }
}
