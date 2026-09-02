import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/address_model.dart';
import '../config/app_config.dart';

class RouteProvider extends ChangeNotifier {
  static const String _baseUrl = AppConfig.backendBaseUrl;
  static const String _cacheKeyRoute = 'cached_route_json';

  List<Address> _addresses = [];
  String? _activeRouteId;
  String? _activeRouteName;
  String _routeStatus = 'active';
  bool _isLoading = false;
  String? _errorMessage;

  // Ağ bağlantısı olmadığında, cihazda daha önce kaydedilmiş son rota
  // gösteriliyorsa true olur. Kullanıcıya "çevrimdışı, eski veri" bilgisi
  // vermek için kullanılır.
  bool _isOffline = false;
  DateTime? _cachedAt;

  bool _isOptimizing = false;
  String? _optimizeError;

  // Sürücü durak sırasını değiştirdiğinde bu flag true olur ve
  // backend'e persist çağrısı tamamlanana kadar otomatik sync'in
  // adres listesini üzerine yazması engellenir.
  bool _persistPending = false;

  // Backend, token süresi dolmuş/iptal edilmiş durumları gövdede
  // code: "SESSION_EXPIRED" ile işaretler (bkz. server.js authenticateToken).
  // 403 ayrıca sahiplik/rol reddi için de kullanıldığından (canAccessUser,
  // requireRole) sadece statusCode'a bakmak yanlış pozitiflere yol açıyordu
  // — ör. başka bir kullanıcının rotası tamamlanmaya çalışılınca dönen
  // "Bu veriye erişim yetkiniz yok" 403'ü oturum bitmiş sanılıp kullanıcı
  // gereksiz yere login'e atılıyordu. Artık sadece gerçek SESSION_EXPIRED
  // işaretinde tetikleniyor.
  bool _sessionExpired = false;
  bool get sessionExpired => _sessionExpired;
  void clearSessionExpired() => _sessionExpired = false;
  void _flagIfSessionError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map && decoded['code'] == 'SESSION_EXPIRED') {
        _sessionExpired = true;
      }
    } catch (_) {}
  }

  RouteProvider() {
    loadActiveRoute();
  }

  List<Address> get addresses => _addresses;
  String? get activeRouteId => _activeRouteId;
  String? get activeRouteName => _activeRouteName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  DateTime? get cachedAt => _cachedAt;

  bool get isOptimizing => _isOptimizing;
  String? get optimizeError => _optimizeError;

  int get totalStops => _addresses.length;
  int get completedStops => _addresses.where((a) => a.isCompleted).length;
  double get completionPercentage =>
      _addresses.isEmpty ? 0 : (completedStops / totalStops) * 100;
  bool get isRouteCompleted => _routeStatus == 'completed';
  bool get allStopsCompleted =>
      _addresses.isNotEmpty && completedStops == totalStops;

  void _applyRouteData(Map<String, dynamic> decoded) {
    final routeJson = _asMap(decoded['route_json']);
    final stopsRaw = routeJson['stops'] ?? routeJson['addresses'] ?? [];
    final stops = stopsRaw is List ? stopsRaw : [];

    _activeRouteId = decoded['id']?.toString();
    _activeRouteName = decoded['name']?.toString();
    _routeStatus = decoded['status']?.toString() ?? 'active';
    var parsedAddresses =
        stops
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList()
            .asMap()
            .entries
            .map(
              (entry) => Address.fromRouteStop(
                entry.value,
                fallbackOrder: entry.key + 1,
              ),
            )
            .where(
              (address) => address.latitude != 0 && address.longitude != 0,
            )
            .toList()
          ..sort((a, b) => a.orderNumber.compareTo(b.orderNumber));

    // Rota, "ev -> duraklar -> ev" şeklinde kapalı bir döngü olarak
    // oluşturuluyor (bkz. backend /routes/optimize). İlk durak
    // (başlangıç/hastane) otomatik tamamlanmış sayılır — sürücü zaten
    // orada. Son durak (hastaneye dönüş) diğer duraklar gibi elle
    // tamamlanır, sadece görünümü farklıdır. İkisi de sayaca dahildir.
    //
    // Takvim senkronundan gelen günlerde ortada ayrıca bir "öğlen hastaneye
    // dönüş" düğümü olabilir (stop.midday=true -> Address.isMiddayReturn).
    // O düğüm middle içinde olduğu gibi korunuyor; elle tamamlanır ve
    // sayaca dahildir, tıpkı son duraktaki hastane gibi.
    if (parsedAddresses.length > 2) {
      final first = parsedAddresses.first;
      final last = parsedAddresses.last;
      const epsilon = 0.0001; // ~11 metre tolerans
      final isClosedLoop =
          (first.latitude - last.latitude).abs() < epsilon &&
          (first.longitude - last.longitude).abs() < epsilon;
      if (isClosedLoop) {
        final middle = parsedAddresses.sublist(1, parsedAddresses.length - 1);
        parsedAddresses = [
          first.copyWith(isStartPoint: true, isCompleted: true),
          ...middle,
          last.copyWith(isReturnToBase: true),
        ];
      }
    }

    _addresses = parsedAddresses;
  }

  Future<void> loadActiveRoute() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      _addresses = [];
      _activeRouteId = null;
      _activeRouteName = null;
      _errorMessage =
          'Kullanıcı bilgisi bulunamadı. Lütfen tekrar giriş yapın.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final Uri uri = Uri.parse('$_baseUrl/routes/$userId/active');
     final response = await http
          .get(uri, headers: await AuthService.authHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        _addresses = [];
        _activeRouteId = null;
        _activeRouteName = null;
        _errorMessage = null;
        _isOffline = false;
        await prefs.remove(_cacheKeyRoute);
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _flagIfSessionError(response.body);
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      // Sürücü sürükleme ile sıra değiştirdiyse ve backend'e henüz
      // kaydedilmediyse, sync verisi adres listesini ezmemeli. Bu, hem
      // persist sırasını (_persistPending) hem de onay bekleyen bir
      // sürükleme varken (_pendingDragPinned != null — kullanıcı henüz
      // "Onayla"ya basmadı) geçerli: aksi halde 10sn'lik otomatik senkron
      // araya girip pinlenen durağın referansını geçersiz kılıyor, "Onayla"
      // basıldığında hangi durağın sabitleneceği bulunamayıp tüm segment
      // yanlışlıkla baştan optimize ediliyordu. Persist tamamlandıktan
      // sonraki sync doğru sırayı getirir.
      if (!_persistPending && _pendingDragPinned == null) {
        _applyRouteData(decoded);
      }
      _isOffline = false;
      _cachedAt = DateTime.now();
      _errorMessage = null;

      // Başarılı veriyi cihaza kaydet — internet kesilirse ya da uygulama
      // kapatılıp açılırsa bu son bilinen rota gösterilebilsin diye.
      await prefs.setString(_cacheKeyRoute, jsonEncode(decoded));
      await prefs.setString(
        '${_cacheKeyRoute}_time',
        _cachedAt!.toIso8601String(),
      );
    } catch (e) {
      // Ağ hatası: cihazda daha önce kaydedilmiş bir rota varsa onu göster,
      // kullanıcı tamamen boş bir ekranla karşılaşmasın.
      final cachedJson = prefs.getString(_cacheKeyRoute);

      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          _applyRouteData(decoded);
          _isOffline = true;
          final cachedTimeRaw = prefs.getString('${_cacheKeyRoute}_time');
          _cachedAt = cachedTimeRaw != null
              ? DateTime.tryParse(cachedTimeRaw)
              : null;
          _errorMessage = null;
        } catch (_) {
          _errorMessage = 'Rota yüklenirken hata oluştu: $e';
        }
      } else {
        final isGuest = prefs.getBool('is_guest') ?? true;
        if (isGuest) {
          _addresses = [];
          _errorMessage = null;
        } else {
          _errorMessage = 'Rota yüklenirken hata oluştu: $e';
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Periyodik senkron artık [SyncScheduler] tarafından yürütülüyor
  // (bkz. main.dart / MainApp). Provider yalnızca tek seferlik yükleme
  // ve tazeleme sunar.
  Future<void> refresh() => loadActiveRoute();

  // Sürükle-bırak yapıldığında ama henüz sürücü onaylamadığında bekleyen
  // durum. `_pendingDragSnapshot`, ilk sürüklemeden önceki listeyi tutar —
  // "Vazgeç" bu listeye geri döner. `_pendingDragPinned`, en son
  // sürüklenen durağı tutar — "Onayla" bu durağı sabit kabul edip gerisini
  // onun konumundan itibaren yeniden hesaplar.
  List<Address>? _pendingDragSnapshot;
  Address? _pendingDragPinned;
  bool get hasPendingReorder => _pendingDragPinned != null;
  Address? get pendingDragPinned => _pendingDragPinned;

  /// Sürücü bir durağı elle sürükleyip bıraktığında çağrılır. Sadece
  /// GÖRSEL olarak taşır — backend'e kaydetmez, yeniden hesaplamaz.
  /// Onay bekler (bkz. [confirmPendingReorder] / [cancelPendingReorder]).
  void previewReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex < 0 || oldIndex >= _addresses.length) return;

    bool isStructural(Address a) =>
        a.isStartPoint || a.isReturnToBase || a.isMiddayReturn;
    // "Taşınabilir" = bekleyen ziyaret durağı. Tamamlanmış duraklar ve
    // yapısal düğümler (başlangıç / hastaneye dönüş / öğle dönüşü) yerinde
    // kalır — ne sürüklenebilir ne de araya bırakılabilir.
    bool isMovable(Address a) => !isStructural(a) && !a.isCompleted;

    if (_isOptimizing) return; // önceki onay hâlâ işleniyor

    final pinned = _addresses[oldIndex];
    if (!isMovable(pinned)) return;

    // İlk sürüklemeden önceki hali sakla — "Vazgeç" buraya döner. Onay
    // bekleyen ardışık sürüklemeler aynı snapshot'ı paylaşır.
    _pendingDragSnapshot ??= List<Address>.from(_addresses);

    final working = List<Address>.from(_addresses);
    working.removeAt(oldIndex);

    // Bırakma hedefini bekleyen bölgeye kıstır: durak, tamamlanmış
    // duraklardan önceye ya da hastaneye dönüş düğümünden sonraya
    // düşemesin (aksi halde bekleyen bir durak "geçmiş" bölgesine
    // karışıp segment hesabını ve kapalı-döngü tespitini bozuyordu).
    final lo = working.indexWhere(isMovable);
    final hi = working.lastIndexWhere(isMovable);
    if (lo != -1) {
      if (newIndex < lo) newIndex = lo;
      if (newIndex > hi + 1) newIndex = hi + 1;
    }
    if (newIndex < 0) newIndex = 0;
    if (newIndex > working.length) newIndex = working.length;

    working.insert(newIndex, pinned);
    _addresses = working;
    _pendingDragPinned = pinned;
    notifyListeners();
  }

  /// Sürükleyerek yapılan değişiklikten vazgeçer, sürüklemeden önceki
  /// sıraya geri döner.
  void cancelPendingReorder() {
    if (_pendingDragSnapshot != null) {
      _addresses = _pendingDragSnapshot!;
    }
    _pendingDragSnapshot = null;
    _pendingDragPinned = null;
    notifyListeners();
  }

  /// Sürücü, sürükleyip bıraktığı durağı onaylar. Onaylanan durak = "bu
  /// durağa öncelik ver" sinyali: durak bırakıldığı pozisyonda sabit
  /// kalır, ONDAN SONRA gelen (aynı vardiya segmentindeki, tamamlanmamış,
  /// yapısal olmayan) duraklar backend'de bu durağın konumu origin
  /// alınarak yeniden optimize edilir (bkz. server.js /routes/optimize).
  /// Bu durağın ÖNCESİndeki duraklara dokunulmaz.
  Future<bool> confirmPendingReorder() async {
    final pinned = _pendingDragPinned;
    if (pinned == null) return false;
    // Onay barı, işlem bitene kadar (finally'de) "Hesaplanıyor..." ile
    // görünür kalsın diye _pendingDragPinned burada henüz temizlenmiyor.

    bool isStructural(Address a) =>
        a.isStartPoint || a.isReturnToBase || a.isMiddayReturn;

    _isOptimizing = true;
    _optimizeError = null;
    notifyListeners();

    try {
      final pinnedIdx = _addresses.indexOf(pinned);

      // [optimizeRoute] ile aynı vardiya-segmenti mantığı: yalnızca ilk
      // bekleyen yapısal düğüme kadar olan duraklar taşınabilir.
      final firstPendingStructuralIdx = _addresses.indexWhere(
        (a) => isStructural(a) && !a.isCompleted,
      );
      final segmentEnd = firstPendingStructuralIdx == -1
          ? _addresses.length
          : firstPendingStructuralIdx;

      final afterIndices = <int>[];
      for (var i = pinnedIdx + 1; i < segmentEnd; i++) {
        final a = _addresses[i];
        if (!a.isCompleted && !isStructural(a)) afterIndices.add(i);
      }

      if (afterIndices.length >= 2) {
        final after = afterIndices.map((i) => _addresses[i]).toList();
        final response = await http.post(
          Uri.parse('$_baseUrl/routes/optimize'),
          headers: await AuthService.authHeaders(),
          body: jsonEncode({
            'origin': {
              'latitude': pinned.latitude,
              'longitude': pinned.longitude,
            },
            'stops': after
                .map((a) => {
                      'id': a.id,
                      'latitude': a.latitude,
                      'longitude': a.longitude,
                    })
                .toList(),
          }),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode < 200 || response.statusCode >= 300) {
          _flagIfSessionError(response.body);
          _optimizeError =
              'Kalan duraklar optimize edilemedi: ${response.statusCode}';
          // Sürükleme sırası yine de kaydedilsin — en azından kullanıcının
          // elle verdiği sıra kaybolmasın.
          for (int i = 0; i < _addresses.length; i++) {
            _addresses[i] = _addresses[i].copyWith(orderNumber: i + 1);
          }
          notifyListeners();
          await _persistStopOrder();
          return false;
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final optimizedOrder = List<int>.from(decoded['optimizedOrder']);
        final reordered =
            optimizedOrder.map((i) => after[i]).toList(growable: false);

        final newList = List<Address>.from(_addresses);
        for (var k = 0; k < afterIndices.length; k++) {
          newList[afterIndices[k]] = reordered[k];
        }
        _addresses = newList;
      }

      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(orderNumber: i + 1);
      }

      notifyListeners();
      final persisted = await _persistStopOrder();
      if (!persisted) {
        _optimizeError =
            'Yeni sıra kaydedilemedi. Birkaç saniye içinde otomatik senkron eski sırayı geri getirebilir — tekrar dener misin?';
        return false;
      }
      _optimizeError = null;
      return true;
    } catch (e) {
      _optimizeError = 'Rota yeniden hesaplanırken hata oluştu: $e';
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(orderNumber: i + 1);
      }
      notifyListeners();
      await _persistStopOrder();
      return false;
    } finally {
      _isOptimizing = false;
      _pendingDragSnapshot = null;
      _pendingDragPinned = null;
      notifyListeners();
    }
  }

  /// Sürücünün değiştirdiği durak sırasını backend'e gönderir. Başarılı
  /// kayıt olduysa true döner. ÖNEMLİ: yalnızca ağ hatasını değil, HTTP
  /// durum kodunu da kontrol eder — daha önce burada sadece exception
  /// yakalanıyordu, backend 4xx/5xx dönse bile "başarılı" sayılıyordu.
  /// Bu yüzden onaylanan bir sürükleme local'de doğru görünüp birkaç
  /// saniye sonraki senkronda (kayıt aslında hiç gitmediği için) sessizce
  /// eski sıraya dönüyordu. Artık çağıran taraf (bkz. confirmPendingReorder)
  /// false dönünce kullanıcıya açıkça hata gösteriyor.
  Future<bool> _persistStopOrder() async {
    if (_activeRouteId == null || _addresses.isEmpty) return false;
    _persistPending = true;
    try {
      // Konum da gönderiliyor: takvim senkronundan gelen duraklarda `id`
      // stabil değil (Address.id sırasız durumda pozisyondan uyduruluyor),
      // backend bu yüzden eşleştirmeyi öncelikle lat/lng ile yapıyor.
      final stops = _addresses
          .asMap()
          .entries
          .map((e) => {
                'id': e.value.id,
                'order': e.key + 1,
                'latitude': e.value.latitude,
                'longitude': e.value.longitude,
              })
          .toList();
      final response = await http.patch(
        Uri.parse('$_baseUrl/routes/$_activeRouteId/stops'),
        headers: await AuthService.authHeaders(),
        body: jsonEncode({'stops': stops}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _flagIfSessionError(response.body);
        return false;
      }
      // Backend 200 dönse bile hiçbir durağı eşleyemediyse (matched == 0)
      // kayıt aslında yapılmadı — başarısız say ki çağıran hata göstersin.
      try {
        final body = jsonDecode(response.body);
        if (body is Map &&
            body['total'] is num &&
            (body['total'] as num) > 0 &&
            body['matched'] is num &&
            (body['matched'] as num) == 0) {
          return false;
        }
      } catch (_) {
        // gövde beklenen formatta değil — eski backend olabilir, 2xx'e güven
      }
      return true;
    } catch (_) {
      // Ağ hatası — sessizce geç, sonraki sync düzeltir
      return false;
    } finally {
      _persistPending = false;
    }
  }

  /// Haritadan seçilen konumu hem yerel listeye hem backend'e kaydeder.
  /// Başarı → null döner. Hata → Türkçe hata mesajı döner.
  /// Backend başarısız olursa optimistik ekleme geri alınır; 10 sn sync
  /// bozuk veri bırakmaz.
  Future<String?> addAddressAndPersist(Address address) async {
    if (_activeRouteId == null) {
      return 'Aktif rota bulunamadı. Lütfen rotanın yüklendiğinden emin olun.';
    }

    // Optimistik güncelleme — UI anında tepki verir
    _addresses.add(address);
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/routes/$_activeRouteId/stops'),
        headers: await AuthService.authHeaders(),
        body: jsonEncode({
          'stop': {
            'street': address.street,
            'district': address.district,
            'city': address.city,
            'postalCode': address.postalCode,
            'latitude': address.latitude,
            'longitude': address.longitude,
            'customerName': address.customerName,
            'customerType': address.customerType,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend'den gelen gerçek ID ile lokal kaydı senkronize et
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final backendStop = decoded['stop'] as Map<String, dynamic>?;
          if (backendStop != null) {
            final updated = Address.fromRouteStop(
              backendStop,
              fallbackOrder: address.orderNumber,
            );
            _addresses[_addresses.length - 1] = updated;
            notifyListeners();
          }
        } catch (_) {
          // ID güncellenemedi — lokal veri kalır, sıradaki sync tamamlar
        }
        return null; // Başarılı
      }

      _flagIfSessionError(response.body);
      // Optimistik eklemeyi geri al
      if (_addresses.isNotEmpty) _addresses.removeLast();
      notifyListeners();
      return 'Durak eklenemedi (${response.statusCode})';
    } catch (_) {
      // Ağ hatası — optimistik eklemeyi geri al
      if (_addresses.isNotEmpty) _addresses.removeLast();
      notifyListeners();
      return 'Sunucuya bağlanılamadı';
    }
  }

  void removeAddress(int index) {
    _addresses.removeAt(index);
    notifyListeners();
  }

  // Backend'e gerçekten kaydedilip kaydedilmediğini çağıran tarafın
  // bilebilmesi için bool dönüyor — önceden void dönüyordu ve
  // AddressDetailScreen bu sonucu hiç kontrol etmeden ekranda her zaman
  // "Tamamlandı" gösteriyordu, kayıt sessizce başarısız olsa bile.
  Future<bool> toggleCompleted(int index) async {
    if (index < 0 || index >= _addresses.length) return false;

    final current = _addresses[index];
    final updated = current.copyWith(isCompleted: !current.isCompleted);
    _addresses[index] = updated;
    notifyListeners();

    if (_activeRouteId == null) {
      _addresses[index] = current;
      _errorMessage = 'Aktif rota bulunamadı, tamamlanma bilgisi kaydedilemedi.';
      notifyListeners();
      return false;
    }

    try {
      final response = await http.patch(
        Uri.parse(
          '$_baseUrl/routes/$_activeRouteId/stops/${updated.id}/complete',
        ),
        headers: await AuthService.authHeaders(),
        body: jsonEncode({'completed': updated.isCompleted}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _flagIfSessionError(response.body);
        _addresses[index] = current;
        _errorMessage =
            'Tamamlandı bilgisi kaydedilemedi: ${response.statusCode}';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _addresses[index] = current;
      _errorMessage = 'Tamamlandı bilgisi gönderilemedi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> updateNote(int index, String note) async {
    if (index < 0 || index >= _addresses.length) return;

    final current = _addresses[index];
    final updated = current.copyWith(notes: note);
    _addresses[index] = updated;
    notifyListeners();

    if (_activeRouteId == null) return;

    try {
      final response = await http.patch(
        Uri.parse(
          '$_baseUrl/routes/$_activeRouteId/stops/${updated.id}/note',
        ),
        headers: await AuthService.authHeaders(),
        body: jsonEncode({'note': note}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _flagIfSessionError(response.body);
        _addresses[index] = current;
        _errorMessage = 'Not kaydedilemedi: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _addresses[index] = current;
      _errorMessage = 'Not gönderilemedi: $e';
      notifyListeners();
    }
  }

  /// Sürücü, günün rotasını (tüm gerçek durakları tamamlayıp hastaneye
  /// dönünce) bitirdiğinde çağrılır. Durak tamamlamadan ayrı bir kavram —
  /// rotanın kendisini "completed" yapar.
  Future<bool> completeRoute() async {
    if (_activeRouteId == null) return false;

    final previousStatus = _routeStatus;
    _routeStatus = 'completed';
    notifyListeners();

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/routes/$_activeRouteId/complete'),
        headers: await AuthService.authHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _flagIfSessionError(response.body);
        _routeStatus = previousStatus;
        _errorMessage = 'Rota tamamlanamadı: ${response.statusCode}';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _routeStatus = previousStatus;
      _errorMessage = 'Rota tamamlanamadı: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> optimizeRoute() async {
    if (_addresses.isEmpty) return false;

    _isOptimizing = true;
    _optimizeError = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _optimizeError = 'Konum servisleri kapalı. Lütfen GPS\'i açın.';
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _optimizeError = 'Konum izni reddedildi.';
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _optimizeError =
            'Konum izni kalıcı olarak reddedildi. Ayarlardan izin verin.';
        return false;
      }

      final position = await Geolocator.getCurrentPosition();

      // Yapısal düğümler (başlangıç, öğlen hastaneye dönüş, son dönüş) sabah
      // ve öğle turlarının sınırıdır — optimize edilmez, yerleri korunur.
      // Yalnızca İÇİNDE bulunulan vardiya segmentinin bekleyen ziyaret
      // durakları yeniden sıralanır: ilk bekleyen yapısal düğüme kadar olan,
      // henüz tamamlanmamış normal duraklar. Böylece "Optimize" iki vardiyayı
      // tek tura birleştirmez.
      bool isStructural(Address a) =>
          a.isStartPoint || a.isReturnToBase || a.isMiddayReturn;

      final firstPendingStructuralIdx = _addresses.indexWhere(
        (a) => isStructural(a) && !a.isCompleted,
      );
      final segmentEnd = firstPendingStructuralIdx == -1
          ? _addresses.length
          : firstPendingStructuralIdx; // bu index hariç

      final optimizable = <Address>[];
      final optimizableIndices = <int>[];
      for (var i = 0; i < segmentEnd; i++) {
        final a = _addresses[i];
        if (!a.isCompleted && !isStructural(a)) {
          optimizable.add(a);
          optimizableIndices.add(i);
        }
      }

      if (optimizable.length < 2) {
        _optimizeError =
            'Bu vardiyada optimize edilecek yeterli durak yok (en az 2).';
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/routes/optimize'),
        headers: await AuthService.authHeaders(),
        body: jsonEncode({
          'origin': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'stops': optimizable
              .map((a) => {
                    'id': a.id,
                    'latitude': a.latitude,
                    'longitude': a.longitude,
                  })
              .toList(),
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _flagIfSessionError(response.body);
        _optimizeError = 'Rota optimize edilemedi: ${response.statusCode}';
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final optimizedOrder = List<int>.from(decoded['optimizedOrder']);

      final reordered =
          optimizedOrder.map((i) => optimizable[i]).toList(growable: false);

      // Optimize edilen durakları, orijinal listede işgal ettikleri
      // konumlara sırayla geri yerleştir; tamamlanan duraklar ve yapısal
      // düğümler yerinde kalır.
      final newList = List<Address>.from(_addresses);
      for (var k = 0; k < optimizableIndices.length; k++) {
        newList[optimizableIndices[k]] = reordered[k];
      }
      _addresses = newList;

      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(orderNumber: i + 1);
      }

      _optimizeError = null;
      return true;
    } catch (e) {
      _optimizeError = 'Rota optimizasyonu sırasında hata oluştu: $e';
      return false;
    } finally {
      _isOptimizing = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }
}