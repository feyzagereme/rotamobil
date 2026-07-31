// Basic smoke test: verifies the app boots without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rotamobil/main.dart';
import 'package:rotamobil/services/route_provider.dart';
import 'package:rotamobil/services/vehicle_provider.dart';
import 'package:rotamobil/services/fleet_provider.dart';

void main() {
  testWidgets('App boots and shows splash route', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RouteProvider()),
          ChangeNotifierProvider(create: (_) => VehicleProvider()),
          ChangeNotifierProvider(create: (_) => FleetProvider()),
        ],
        child: const RotaMobilApp(startLoggedIn: false),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);

    // SplashScreen schedules a delayed navigation; let it settle before teardown.
    await tester.pump(const Duration(milliseconds: 2500));
  });
}
