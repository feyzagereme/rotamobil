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
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'screens/calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/guest/guest_app.dart';
import 'services/auth_service.dart';
import 'services/route_provider.dart';
import 'services/location_service.dart';
import 'services/vehicle_provider.dart';
import 'services/fleet_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: kIsWeb
          ? const FirebaseOptions(
              apiKey: "AIzaSyDNntalqnmuOiJrgrpahfI3RRg8r9cM91w",
              authDomain: "rota360-35ce3.firebaseapp.com",
              projectId: "rota360-35ce3",
              storageBucket: "rota360-35ce3.firebasestorage.app",
              messagingSenderId: "434121736536",
              appId: "1:434121736536:web:e8a409cb916d03dec7e52d",
            )
          : null,
    );
    await NotificationService.initialize();
  } catch (e) {
    // GoogleService-Info.plist eksikse (iOS) Firebase burada patlar; push
    // bildirimleri olmadan da uygulama açılabilmeli.
    debugPrint('Firebase baslatilamadi, bildirimler devre disi: $e');
  }
  await initializeDateFormatting('tr_TR');
  final loggedIn = await AuthService.isLoggedIn();

  // assigned_vehicle_id'i burada senkron okuyoruz; VehicleProvider'a
  // ilk değer olarak veriyoruz. Böylece _handleVehicleChange()'in
  // async _restore()'dan önce ateşlenmesi durumunda bile doğru araç
  // yüklenir (ör. ilk oturum açılışında selected_vehicle_id henüz yok).
  final startPrefs = await SharedPreferences.getInstance();
  final assignedVehicleId = startPrefs.getInt('assigned_vehicle_id');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(
          create: (_) => VehicleProvider(initialVehicleId: assignedVehicleId),
        ),
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

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MapScreen(),
    const RouteListScreen(),
    const CalendarScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    LocationService.startTrackingIfEnabled();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VehicleProvider>().addListener(_handleVehicleChange);
      context.read<RouteProvider>().addListener(_handleSessionExpiry);
      _handleVehicleChange();
    });
  }

  // VehicleProvider (araç seçici) değiştiğinde RouteProvider ve FleetProvider'ı
  // seçilen araca göre senkron tutar.
  void _handleVehicleChange() {
    final vehicleId = context.read<VehicleProvider>().selectedVehicleId;
    context.read<RouteProvider>().switchVehicle(vehicleId);
    context.read<FleetProvider>().switchVehicle(vehicleId);
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

  @override
  void dispose() {
    LocationService.stopTracking();
    context.read<VehicleProvider>().removeListener(_handleVehicleChange);
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
