import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/route_list_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/guest/guest_app.dart';
import 'services/auth_service.dart';
import 'services/route_provider.dart';
import 'services/location_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  final loggedIn = await AuthService.isLoggedIn();
  runApp(
    ChangeNotifierProvider(
      create: (_) => RouteProvider(),
      child: RotaMobilApp(startLoggedIn: loggedIn),
    ),
  );
}

class RotaMobilApp extends StatelessWidget {
  final bool startLoggedIn;
  const RotaMobilApp({super.key, required this.startLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rota Mobil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryDark,
        scaffoldBackgroundColor: AppColors.bgLight,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryDark,
          primary: AppColors.primaryDark,
          primaryContainer: AppColors.accent,
          surface: AppColors.surface,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: AppColors.stroke,
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius)),
            side: BorderSide(color: AppColors.stroke),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const MainApp(),
        '/guest': (_) => const GuestApp(),
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    LocationService.startTracking();
  }

  @override
  void dispose() {
    LocationService.stopTracking();
    super.dispose();
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MapScreen(),
    const RouteListScreen(),
    const CalendarScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.navBg,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.white.withValues(alpha: 0.45),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.list_rounded), label: 'Liste'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Takvim'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}