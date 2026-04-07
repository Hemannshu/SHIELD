import 'package:flutter/material.dart';
import 'package:title_proj/child/bottom_screens/ExploreMore.dart';
import 'package:title_proj/child/bottom_screens/add_contacts.dart';
import 'package:title_proj/child/bottom_screens/chat_page.dart';
import 'package:title_proj/child/bottom_screens/child_home_page.dart';
import 'package:title_proj/child/bottom_screens/contacts_page.dart';
import 'package:title_proj/child/bottom_screens/profile_page.dart';
import 'package:title_proj/child/bottom_screens/review_page.dart';

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
  double _iconSize = 28.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
            selectedItemColor: Colors.deepPurpleAccent[700],
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 10,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                label: 'Home',
                icon: Icon(Icons.home_outlined, size: _iconSize),
                activeIcon: Icon(Icons.home_filled, size: _iconSize),
              ),
              BottomNavigationBarItem(
                label: 'Contacts',
                icon: Icon(Icons.contacts_outlined, size: _iconSize),
                activeIcon: Icon(Icons.contact_page, size: _iconSize),
              ),
              BottomNavigationBarItem(
                label: 'Chat',
                icon: Icon(Icons.chat_bubble_outline, size: _iconSize),
                activeIcon: Icon(Icons.chat_bubble, size: _iconSize),
              ),
              BottomNavigationBarItem(
                label: 'Explore',
                icon: Icon(Icons.explore_outlined, size: _iconSize),
                activeIcon: Icon(Icons.explore, size: _iconSize),
              ),
              BottomNavigationBarItem(
                label: 'Reviews',
                icon: Icon(Icons.star_border, size: _iconSize),
                activeIcon: Icon(Icons.star, size: _iconSize),
              ),
            ],
          ),
        ),
      ),
    );
  }
}