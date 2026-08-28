import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> _launchAppleMaps(double lat, double lng) async {
  final url = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
  if (await canLaunchUrl(url)) {
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
  return false;
}

Future<bool> _launchGoogleMaps(double lat, double lng) async {
  final url = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$lat,$lng&travelmode=driving',
  );
  if (await canLaunchUrl(url)) {
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
  return false;
}

/// Navigasyon butonuna basıldığında hangi harita uygulamasının açılacağını
/// seçtirir. iOS'ta hem Apple Haritalar hem Google Haritalar seçeneği
/// gösterilir (ikisi de sistemde her zaman var/açılabilir); diğer
/// platformlarda Apple Haritalar anlamsız olduğu için doğrudan Google
/// Haritalar açılır, seçim menüsü gösterilmez.
Future<bool> launchNavigation(
  BuildContext context,
  double lat,
  double lng,
) async {
  final isIOS = !kIsWeb && Platform.isIOS;
  if (!isIOS) return _launchGoogleMaps(lat, lng);

  final choice = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Navigasyon uygulaması seç',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map_rounded),
            title: const Text('Apple Haritalar'),
            onTap: () => Navigator.of(sheetContext).pop('apple'),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Google Haritalar'),
            onTap: () => Navigator.of(sheetContext).pop('google'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (choice == 'apple') return _launchAppleMaps(lat, lng);
  if (choice == 'google') return _launchGoogleMaps(lat, lng);
  return false;
}
