import 'package:flutter/material.dart';
import 'guest_home_screen.dart';
import 'guest_map_screen.dart';
import 'guest_history_screen.dart';
import 'guest_favorites_screen.dart';

class GuestApp extends StatefulWidget {
  const GuestApp({super.key});
  @override
  State<GuestApp> createState() => _GuestAppState();
}

class _GuestAppState extends State<GuestApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const GuestHomeScreen(),
    const GuestMapScreen(),
    const GuestHistoryScreen(),
    const GuestFavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0A1628),
        selectedItemColor: const Color(0xFF53D6FF),
        unselectedItemColor: Colors.white.withValues(alpha: 0.4),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Geçmiş'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Favoriler'),
        ],
      ),
    );
  }
}