import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:title_proj/child/bottom_screens/ExploreMore.dart';
import 'package:title_proj/child/bottom_screens/add_contacts.dart';
import 'package:title_proj/child/bottom_screens/chat_page.dart';
import 'package:title_proj/child/bottom_screens/child_home_page.dart';
import 'package:title_proj/child/bottom_screens/contacts_page.dart';
import 'package:title_proj/child/bottom_screens/profile_page.dart';
import 'package:title_proj/child/bottom_screens/review_page.dart';
import 'package:title_proj/utils/app_theme.dart';

class BottomPage extends StatefulWidget {
  const BottomPage({super.key});

  @override
  State<BottomPage> createState() => _BottomPageState();
}

class _BottomPageState extends State<BottomPage> {
  final List<Widget> pages = [
    HomeScreen(),
    AddContactsPage(),
    ChatPage(),
    ExploreMorePage(),
    ReviewPage(),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: pages[_currentIndex],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCard.withOpacity(0.9)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.04),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home', isDark),
                  _buildNavItem(1, Icons.people_rounded, Icons.people_outline_rounded, 'Contacts', isDark),
                  _buildNavItem(2, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat', isDark),
                  _buildNavItem(3, Icons.explore_rounded, Icons.explore_outlined, 'Explore', isDark),
                  _buildNavItem(4, Icons.star_rounded, Icons.star_outline_rounded, 'Reviews', isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPink.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                key: ValueKey(isSelected),
                size: 24,
                color: isSelected
                    ? AppTheme.primaryPink
                    : (isDark ? Colors.white38 : AppTheme.neutralGrey400),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppTheme.primaryPink
                    : (isDark ? Colors.white38 : AppTheme.neutralGrey400),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}