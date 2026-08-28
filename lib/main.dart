import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/route_list_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/guest/guest_app.dart';
import 'screens/admin_overview_screen.dart';
import 'services/auth_service.dart';
import 'services/route_provider.dart';
import 'services/location_service.dart';
import 'services/fleet_provider.dart';
import 'services/sync_scheduler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.initialize();
  } catch (e) {
    // GoogleService-Info.plist eksikse (iOS) Firebase burada patlar; push
    // bildirimleri olmadan da uygulama açılabilmeli.
    debugPrint('Firebase baslatilamadi, bildirimler devre disi: $e');
  }
  await initializeDateFormatting('tr_TR');
  final loggedIn = await AuthService.isLoggedIn();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => FleetProvider()),
      ],
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
      title: 'Rota360',
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
            borderRadius: BorderRadius.all(
              Radius.circular(AppTheme.borderRadius),
            ),
            side: BorderSide(color: AppColors.stroke),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
  '/splash': (_) => const SplashScreen(),
  '/welcome': (_) => const WelcomeScreen(),
  '/login': (_) => const LoginScreen(),
  '/register': (_) => const RegisterScreen(),
  '/home': (_) => const MainApp(),
  '/guest': (_) => const GuestApp(),
  '/admin': (_) => const AdminOverviewScreen(),
},
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MapScreen(),
    const RouteListScreen(),
    const CalendarScreen(),
    const ProfileScreen(),
  ];

  // Rota + filo senkronu tek zamanlayıcıda toplanıyor (eskiden iki ayrı
  // provider ayrı ayrı 10sn'lik Timer.periodic çalıştırıyordu). Uygulama
  // arka plana geçince durur, ön plana dönünce anında bir tur çalışıp
  // devam eder.
  late final SyncScheduler _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocationService.startTrackingIfEnabled();

    final routeProvider = context.read<RouteProvider>();
    final fleetProvider = context.read<FleetProvider>();
    routeProvider.addListener(_handleSessionExpiry);
    _sync = SyncScheduler(
      onTick: () async {
        await Future.wait([
          routeProvider.refresh(),
          fleetProvider.load(),
        ]);
      },
    );
    _sync.start();
  }

  // Backend 401/403 döndüğünde (token süresi dolmuş/iptal edilmiş) oturumu
  // temizleyip kullanıcıyı login ekranına atar — aksi halde "giriş yapmış"
  // görünüp hiçbir isteği çalışmayan bir ekranda takılı kalırdı.
  bool _handlingSessionExpiry = false;
  void _handleSessionExpiry() {
    if (_handlingSessionExpiry) return;
    if (!context.read<RouteProvider>().sessionExpired) return;
    _handlingSessionExpiry = true;
    context.read<RouteProvider>().clearSessionExpired();
    AuthService.logout().then((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    });
  }

  // Ön planda periyodik senkron çalışır; arka plana geçince zamanlayıcı
  // durdurulur (pil/veri tasarrufu). Ön plana dönüşte start() hemen bir
  // tur çalıştırır — sürücü uygulamayı dün açıp bugün döndüğünde backend
  // İstanbul saatine göre "bugünün" rotasını servis ettiği için bu tazeleme
  // önemli.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync.start();
    } else {
      _sync.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sync.stop();
    LocationService.stopTracking();
    context.read<RouteProvider>().removeListener(_handleSessionExpiry);
    super.dispose();
  }

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
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana'),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Harita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_rounded),
            label: 'Liste',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
