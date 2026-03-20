import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/route_list_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  await initializeDateFormatting('tr_TR');
  runApp(const RotaMobilApp());
}

class RotaMobilApp extends StatelessWidget {
  const RotaMobilApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rota Mobil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryDark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          primaryContainer: AppColors.primaryDark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MapScreen(),
    const RouteListScreen(),
    const CalendarScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        elevation: 8.0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Harita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Liste',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
