part of 'app_state.dart';

/// Conexión de AppState con la Nearby API (Spring Boot).
///
/// Las pantallas siguen leyendo las mismas listas de AppState (services, posts,
/// reports...). Aquí se llenan desde el backend y cada acción se envía a la API.
/// Sin sesión (pruebas, modo demo) la app funciona con los datos de ejemplo.
extension NearbyBackend on AppState {
  // ===================================================================== sesión

  /// Al abrir la app: reanuda la sesión guardada o muestra la bienvenida.
  Future<void> bootstrap() async {
    useApi = true;
    api.onSessionExpired = _sessionExpired;
    await _restoreOutbox();
    _watchConnectivity();
    final saved = await api.store.readRefreshToken();
    if (_disposed) return;
    if (saved == null) {
      _showSplash();
      return;
    }
    try {
      final auth = await api.resume(saved);
      if (auth != null) {
        await _afterLogin(auth);
        screen = 'home';
        hist.clear();
        refresh();
        return;
      }
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _showSplash();
        toast(
          'No pudimos conectar con Nearby. Revisa tu internet.',
          icon: 'cloud_off',
        );
        return;
      }
    }
    _showSplash();
  }

  void _showSplash() {
    screen = 'splash';
    hist.clear();
    refresh();
  }

  void _sessionExpired() {
    if (!connected) return;
    _stopPolling();
    connected = false;
    api.clearSession();
    screen = 'login';
    hist.clear();
    refresh();
    toast('Tu sesión venció. Ingresa otra vez con tu celular.', icon: 'lock');
  }

  /// Paso 1 del ingreso: envía el código SMS al celular de phoneDraft.
  Future<bool> requestOtp() async {
    busy = true;
    refresh();
    try {
      await deviceActions.listenForSms();
      final response = await api.post(
        'auth/otp/request',
        body: {'phone': phoneDraft},
        auth: false,
      );
      otpDevCode = response['devCode'] as String?;
      otpResendSeconds = (response['resendInSeconds'] as num?)?.toInt() ?? 30;
      toast('Código solicitado al +51 $phoneDraft', icon: 'sms');
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    } finally {
      busy = false;
      refresh();
    }
  }

  /// Paso 2: verifica el código. Devuelve null si entró, o el mensaje de error.
  /// isNewUser queda en [regPending] para mostrar el registro.
  Future<String?> verifyOtp(String code) async {
    busy = true;
    refresh();
    try {
      final auth = await api.post(
        'auth/otp/verify',
        body: {'phone': phoneDraft, 'code': code},
        auth: false,
      );
      final map = auth as Map<String, dynamic>;
      final user = map['user'] as Map<String, dynamic>?;
      regPending =
          map['isNewUser'] == true ||
          (user?['name'] as String?) == null ||
          (user?['zone']) == null;
      await _afterLogin(map);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      busy = false;
      refresh();
    }
  }

  Future<void> _afterLogin(Map<String, dynamic> auth) async {
    api.setTokens(
      auth['accessToken'] as String,
      auth['refreshToken'] as String,
    );
    final user = auth['user'] as Map<String, dynamic>?;
    await api.store.save(
      refreshToken: api.refreshToken!,
      phone: user?['phone'] as String?,
    );
    connected = true;
    viewedZone = null;
    zoneViewRevision++;
    _resetToServerData();
    sessionRole = null;
    if (user != null) _applyUser(user);
    sessionRole = role;
    await loadAll();
    _startPolling();
    // Lo que quedó encolado (incluso de antes de cerrar la app) sale apenas hay sesión.
    if (_outbox.isNotEmpty && !offline) unawaited(_flushOutbox());
  }

  /// Sin datos de ejemplo una vez que hay sesión: todo viene del backend.
  void _resetToServerData() {
    conversations = [];
    myStats = const {};
    serviceDetails.clear();
    verified = false;
    municipality = null;
    myMunicipality = const {'status': 'NONE'};
    municipalities = [];
    managedZones = [];
    staff = [];
    adminRequests = [];
    pubLat = null;
    pubLng = null;
    pubPlace = null;
    pubFromGps = false;
    services = [];
    posts = [];
    reports = [];
    resOffers = [];
    groups = [];
    normalPins = [];
    emergencyPins = [];
    remoteInventory = [];
    chats.clear();
    convIds.clear();
    vbGiven.clear();
    helped.clear();
    going.clear();
    joined.clear();
    aiMissions.clear();
    aiNotified.clear();
    aiStatus = 'idle';
    lastCode = null;
    sosResult = null;
    contactBook = [];
    contacts = [];
  }

  void _applyUser(Map<String, dynamic> u) {
    if (tourName != null) return;
    userId = u['id'] as String?;
    final name = u['name'] as String?;
    if (name != null && name.isNotEmpty) userName = name;
    userPhone = (u['phone'] as String?) ?? userPhone;
    role = (u['role'] as String?) ?? 'NEIGHBOR';
    municipality = u['municipality'] as Map<String, dynamic>?;
    verified = u['verified'] == true;
    // Cambió mi rol (p. ej. aprobaron mi Municipalidad): el token viejo aún tiene el rol anterior.
    if (connected && sessionRole != null && sessionRole != role) {
      final approved = role == 'MUNICIPALITY' && sessionRole != 'ADMIN';
      sessionRole = role;
      unawaited(
        api.refreshSession().then((ok) {
          if (ok) unawaited(loadAll());
        }),
      );
      if (approved && screen != 'splash') {
        toast(
          'Tu Municipalidad fue aprobada: ya puedes usar el panel',
          icon: 'verified_user',
        );
      }
    }
    final photo = u['photoUrl'] as String?;
    photoUrl = photo == null || photo.isEmpty ? null : ApiConfig.fileUrl(photo);
    aiConsent = u['aiConsent'] != false;
    final zone = u['zone'] as Map<String, dynamic>?;
    final previousZone = zoneId;
    zoneId = zone?['id'] as String?;
    homeZoneLat = (zone?['centerLat'] as num?)?.toDouble();
    homeZoneLng = (zone?['centerLng'] as num?)?.toDouble();
    if (previousZone != zoneId) {
      viewedZone = null;
      zoneViewRevision++;
    }
    zoneName = (zone?['name'] as String?) ?? 'Sin zona guardada';
    final zoneMode = zone?['mode'] as String?;
    zoneModeSource = zone?['modeSource'] as String?;
    zoneModeReason = zone?['modeReason'] as String?;
    zoneModeAt = DateTime.tryParse(
      (zone?['modeActivatedAt'] as String?) ?? '',
    )?.toLocal();
    final mode = (u['effectiveMode'] as String?) ?? 'NORMAL';
    final wasEmergency = emergency;
    final wasPrevention = prevention;
    this.zoneMode = zoneMode ?? 'NORMAL';
    effectiveMode = mode;
    if (connected && prevention && !wasPrevention && screen != 'splash') {
      toast(
        'Prevención El Niño: la Municipalidad pide reportar riesgos',
        icon: 'flood',
      );
      unawaited(loadRiskReports());
    }
    emergency = mode == 'EMERGENCY';
    zoneEm = zoneMode == 'EMERGENCY';
    emSource = emergency && !zoneEm ? 'yo' : 'zona';
    if (!emergency) {
      emergencySince = null;
      zoneDashboard = const {};
    } else if (zoneEm) {
      emergencySince = zoneModeAt ?? emergencySince ?? DateTime.now();
    } else {
      emergencySince ??= DateTime.now();
    }
    if (connected && emergency && !wasEmergency) unawaited(loadZoneDashboard());
    if (connected && emergency && !wasEmergency && screen != 'splash') {
      toast(
        zoneEm
            ? 'La Municipalidad activó el modo emergencia'
            : 'Modo emergencia activado',
        icon: 'crisis_alert',
      );
    } else if (connected && !emergency && wasEmergency) {
      if (['tablero', 'recursos', 'apoyo'].contains(screen)) {
        screen = 'home';
        hist.clear();
      }
      toast('La zona volvió al modo normal', icon: 'verified_user');
    }
  }

  /// Cerrar sesión en el servidor y en el teléfono.
  Future<void> logout() async {
    _stopPolling();
    try {
      if (connected) await api.post('auth/logout');
    } catch (_) {}
    await api.clearSession();
    connected = false;
    closeMedicalCard();
    // Los pendientes no deben salir después con otra cuenta.
    _outbox.clear();
    await outboxStorage.clear();
    viewedZone = null;
    homeZoneLat = null;
    homeZoneLng = null;
    zoneId = null;
    zoneName = 'Sin zona guardada';
    zoneViewRevision++;
    regPending = false;
    emergency = false;
    zoneEm = false;
    phoneDraft = '';
    go('splash', reset: true);
    toast('Cerraste sesión', icon: 'logout');
  }

  // ================================================================ registro

  /// "Usar mi ubicación actual" en el registro.
  Future<void> locateForRegistration() async {
    regLoc = 'loading';
    refresh();
    final pos = await location.current();
    if (_disposed) return;
    regLat = pos.lat;
    regLng = pos.lng;
    if (pos.real) {
      String? resolvedAddress;

      if (pos.city != null && pos.city!.isNotEmpty) {
        resolvedAddress = pos.region != null
            ? '${pos.city}, ${pos.region}'
            : pos.city;
      }

      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.lat}&lon=${pos.lng}&zoom=18&addressdetails=1',
        );
        final res = await http
            .get(
              uri,
              headers: {'User-Agent': 'NearbyApp/1.0', 'Accept-Language': 'es'},
            )
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final addr = data['address'] as Map<String, dynamic>?;
          if (addr != null) {
            final road =
                addr['road'] ?? addr['pedestrian'] ?? addr['suburb'] ?? '';
            final num = addr['house_number'] ?? '';
            final district =
                addr['city_district'] ??
                addr['suburb'] ??
                addr['city'] ??
                addr['town'] ??
                pos.city ??
                '';
            if (road.isNotEmpty && district.isNotEmpty) {
              resolvedAddress = '$road $num, $district'
                  .replaceAll('  ', ' ')
                  .trim();
            } else if (district.isNotEmpty) {
              resolvedAddress = district;
            }
          }
        }
      } catch (_) {}

      if (_disposed) return;
      regAddress =
          resolvedAddress ??
          'Ubicación actual (${pos.lat.toStringAsFixed(4)}, ${pos.lng.toStringAsFixed(4)})';
    } else {
      regAddress = 'Elige tu casa en el mapa';
    }
    if (pos.real && location.approximate) {
      regAddress = 'Ubicación aproximada: $regAddress';
      toast(
        'Ubicación aproximada por red. Revisa la zona antes de continuar.',
        icon: 'location_on',
      );
    }
    regLoc = 'ok';
    refresh();
    if (!pos.real) {
      toast(
        'No pudimos leer el GPS: toca "Cambiar" y elige tu casa en el mapa',
        icon: 'location_on',
      );
    }
  }

  /// Guarda nombre y ubicación (asigna la zona más cercana).
  Future<bool> completeRegistration() async {
    if (!connected) return true;
    try {
      final me = await api.put('me', body: {'name': userName});
      _applyUser(me as Map<String, dynamic>);
      if (regLat != null && regLng != null) {
        final hint = await _placeParts(regLat!, regLng!);
        final withZone = await api.put(
          'me/location',
          body: {
            'lat': regLat,
            'lng': regLng,
            'addressText': regAddress,
            'zoneName': ?hint?.barrio,
            'district': ?hint?.district,
          },
        );
        _applyUser(withZone as Map<String, dynamic>);
        userAddress = regAddress;
      }
      regPending = false;
      await loadAll();
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }

  // ================================================================ perfil

  /// Actualiza la dirección y/o coordenadas del hogar del usuario.
  Future<bool> updateUserLocation({
    required String address,
    double? lat,
    double? lng,
  }) async {
    userAddress = address.trim();
    regAddress = address.trim();
    if (lat != null) regLat = lat;
    if (lng != null) regLng = lng;
    viewedZone = null;
    zoneViewRevision++;
    refresh();

    if (!connected) return true;
    try {
      final body = <String, Object?>{'addressText': address.trim()};
      if (lat != null && lng != null) {
        body['lat'] = lat;
        body['lng'] = lng;
      } else if (regLat != null && regLng != null) {
        body['lat'] = regLat;
        body['lng'] = regLng;
      }
      // Barrio y distrito de la casa: si ninguna zona la cubre, el backend crea la de este barrio.
      final hLat = body['lat'] as double?, hLng = body['lng'] as double?;
      if (hLat != null && hLng != null) {
        final hint = await _placeParts(hLat, hLng);
        if (hint?.barrio != null) body['zoneName'] = hint!.barrio;
        if (hint?.district != null) body['district'] = hint!.district;
      }
      final withZone = await api.put('me/location', body: body);
      _applyUser(withZone as Map<String, dynamic>);
      unawaited(_loadPins().then((_) => refresh()));
      refresh();
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }

  /// Contactos de confianza elegidos (hasta 3).
  Future<void> saveContacts() async {
    if (!connected) return;
    final body = <Map<String, Object?>>[];
    var pos = 1;
    for (final id in contacts) {
      final c = contactBook.where((x) => x.id == id).firstOrNull;
      final digits = contactDigits[id];
      if (c == null || digits == null) continue;
      body.add({'name': c.name, 'phone': digits, 'position': pos++});
    }
    try {
      await api.put('me/trusted-contacts', body: body);
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  /// Agrega un contacto escrito a mano (nombre + celular de 9 dígitos).
  String? addContact(String name, String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final clean = digits.length == 11 && digits.startsWith('51')
        ? digits.substring(2)
        : digits;
    if (name.trim().length < 2) return 'Escribe el nombre del contacto';
    if (!RegExp(r'^9\d{8}$').hasMatch(clean)) {
      return 'Los celulares en Perú tienen 9 dígitos y empiezan con 9';
    }
    final id = 'tc-$clean';
    if (!contactBook.any((c) => c.id == id)) {
      contactBook.add(
        ContactItem(
          id: id,
          name: name.trim(),
          phone: _maskPhone(clean),
          icon: Icons.person,
        ),
      );
    }
    contactDigits[id] = clean;
    if (!contacts.contains(id) && contacts.length < 3) contacts.add(id);
    refresh();
    return null;
  }

  static String _maskPhone(String d) =>
      d.length == 9 ? '+51 ${d.substring(0, 3)} *** ${d.substring(6)}' : d;

  Future<void> saveMedicalCard() async {
    final card = medical;
    if (!connected || card == null) return;
    // El cuerpo se arma ya: la pantalla borra la ficha de la memoria al cerrarse.
    final body = {
      'bloodType': card.sangre,
      'allergies': card.alergias,
      'conditions': card.condiciones,
      'livesWith': card.vive
          .map((v) => Api2App.reverse(Api2App.livesWith, v))
          .whereType<String>()
          .toList(),
    };
    try {
      await api.put('me/medical-card', body: body);
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  Future<void> setAiConsent(bool value) async {
    aiConsent = value;
    refresh();
    if (!connected) return;
    try {
      await api.put('me/settings', body: {'aiConsent': value});
      await _loadInventory();
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  /// Borrar algo que la IA aprendió de mí (no se vuelve a crear).
  Future<void> removeLearning(HistoryItem item) async {
    aiRemoved['${item.id}${item.tag}'] = true;
    refresh();
    if (!connected) return;
    try {
      await api.delete('me/ai-learnings/${item.id}');
    } on ApiException catch (_) {}
  }

  // ================================================================ carga

  /// Trae todo lo que la app muestra. Cada parte falla por separado.
  Future<void> loadAll() async {
    if (!connected) return;
    await Future.wait([
      _loadMe(),
      _loadLocation(),
      _loadServices(),
      _loadPosts(),
      _loadReports(),
      _loadResources(),
      _loadGroups(),
      _loadPins(),
      _loadInventory(),
      _loadContacts(),
      _loadBrigadeRequest(),
      loadMyMunicipality(),
      loadMyStats(),
      loadConversations(),
      if (prevention) loadRiskReports(),
      if (isAdmin) loadAdminRequests(),
      if (isAdmin) loadManagedZones(),
      if (isPlatformAdmin) loadMunicipalities(),
      if (isMunicipality) loadStaff(),
      // La ficha médica no se carga aquí: solo al abrirla (openMedicalCard).
    ]);
    lastSyncAt = DateTime.now();
    refresh();
    // Con wifi, guarda el mapa de 5 km alrededor de la casa para usarlo sin internet.
    unawaited(ensureOfflineMap());
  }

  Future<void> _quiet(Future<void> Function() load) async {
    try {
      await load();
    } on ApiException catch (_) {
      // Se reintenta en la próxima actualización.
    } catch (_) {}
  }

  Future<void> _loadMe() => _quiet(() async {
    final me = await api.get('me');
    _applyUser(me as Map<String, dynamic>);
  });

  Future<void> _loadServices() => _quiet(() async {
    final page = await api.get(
      'services',
      query: {'size': 50, 'radiusM': 5000, 'sort': 'endorsements'},
    );
    final list = (page['content'] as List).cast<Map<String, dynamic>>();
    if (tourName != null) return;
    services = list.map(Api2App.service).toList();
    vbGiven = {
      for (final j in list) j['id'] as String: j['endorsedByMe'] == true,
    };
    _vbBase = {
      for (final s in services) s.id: s.vb - (vbGiven[s.id] == true ? 1 : 0),
    };
    for (final s in services) {
      s.vb = _vbBase[s.id] ?? s.vb;
    }
  });

  Future<void> _loadServiceDetail(String id) => _quiet(() async {
    final d = await api.get('services/$id') as Map<String, dynamic>;
    serviceDetails[id] = d;
    final updated = Api2App.service(d);
    final i = services.indexWhere((s) => s.id == id);
    vbGiven[id] = d['endorsedByMe'] == true;
    updated.vb = updated.vb - (vbGiven[id] == true ? 1 : 0);
    _vbBase[id] = updated.vb;
    if (i >= 0) {
      services[i] = updated;
    } else {
      services.add(updated);
    }
    final rv = await api.get('services/$id/reviews') as List;
    reviews[id] = rv.cast<Map<String, dynamic>>().map(Api2App.review).toList();
    refresh();
  });

  Future<void> _loadPosts() => _quiet(() async {
    final page = await api.get('posts', query: {'size': 50, 'radiusM': 5000, 'status': 'OPEN'});
    final list = (page['content'] as List).cast<Map<String, dynamic>>();
    posts = list.map(Api2App.post).toList();
    helped = {
      for (final j in list) j['id'] as String: j['respondedByMe'] == true,
    };
  });

  Future<void> _loadReports() => _quiet(() async {
    final page = await api.get('vulnerable-reports', query: {'size': 100});
    final list = (page['content'] as List).cast<Map<String, dynamic>>();
    reports = list.map(Api2App.report).toList();
    for (final j in list) {
      if (j['assignedToMe'] == true) going[j['id']] = true;
    }
  });

  Future<void> _loadResources() => _quiet(() async {
    final list = (await api.get('resources') as List)
        .cast<Map<String, dynamic>>();
    resOffers = list
        .where((j) => j['resourceType'] != null)
        .map(Api2App.resOffer)
        .toList();
    final summary = (await api.get('resources/summary') as List)
        .cast<Map<String, dynamic>>();
    final counts = {
      for (final s in summary)
        Api2App.resourceType[s['type']] ?? '': (
          s['have'] as num? ?? 0,
          s['need'] as num? ?? 0,
        ),
    };
    resources = kResources.map((r) {
      final c = counts[r.id];
      return ResourceItem(
        id: r.id,
        label: r.label,
        icon: r.icon,
        tone: r.tone,
        have: c == null ? 0 : c.$1.toInt(),
        need: c == null ? 0 : c.$2.toInt(),
      );
    }).toList();
  });

  Future<void> _loadGroups() => _quiet(() async {
    final list = (await api.get('support-groups') as List)
        .cast<Map<String, dynamic>>();
    groups = list.map(Api2App.group).toList();
    joined = {
      for (final j in list)
        (j['name'] as String? ?? ''): j['joinedByMe'] == true,
    };
  });

  Future<void> _loadPins() => _quiet(() async {
    final revision = zoneViewRevision;
    final selected = viewedZone;
    final query = <String, Object?>{
      if (selected != null) 'zoneId': selected.id,
      'radiusM': selected?.radius ?? 5000,
    };
    final daily = (await api.get(
      'map/pins',
      query: {...query, 'layer': 'daily'},
    ) as List).cast<Map<String, dynamic>>();
    final em = (await api.get(
      'map/pins',
      query: {...query, 'layer': 'emergency'},
    ) as List).cast<Map<String, dynamic>>();
    if (_disposed || revision != zoneViewRevision) return;
    normalPins = daily.map(Api2App.pin).toList();
    emergencyPins = em.map(Api2App.pin).toList();
    refresh();
  });

  Future<void> loadPinsInBounds({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
  }) => _quiet(() async {
    final revision = zoneViewRevision;
    final query = <String, Object?>{
      'minLat': minLat,
      'maxLat': maxLat,
      'minLon': minLon,
      'maxLon': maxLon,
    };
    final daily = (await api.get(
      'map/pins',
      query: {...query, 'layer': 'daily'},
    ) as List).cast<Map<String, dynamic>>();
    final em = (await api.get(
      'map/pins',
      query: {...query, 'layer': 'emergency'},
    ) as List).cast<Map<String, dynamic>>();
    if (_disposed || revision != zoneViewRevision) return;
    normalPins = daily.map(Api2App.pin).toList();
    emergencyPins = em.map(Api2App.pin).toList();
    refresh();
  });

  Future<void> _loadInventory() => _quiet(() async {
    final list = (await api.get('ai/inventory') as List)
        .cast<Map<String, dynamic>>();
    remoteInventory = list
        .map(Api2App.inventory)
        .whereType<HistoryItem>()
        .toList();
    final mine = (await api.get('me/ai-learnings') as List)
        .cast<Map<String, dynamic>>();
    myLearnings = mine
        .map((j) {
          final tag = Api2App.aiTag[j['tag']];
          if (tag == null) return null;
          return HistoryItem(
            id: j['id'] as String,
            who: userName,
            zona: zoneName,
            src: 'Muro',
            when: '',
            txt:
                (j['evidenceText'] as String?) ?? (j['label'] as String? ?? ''),
            x: 50,
            y: 50,
            tag: tag,
          );
        })
        .whereType<HistoryItem>()
        .toList();
  });

  Future<void> _loadContacts() => _quiet(() async {
    final list = (await api.get('me/trusted-contacts') as List)
        .cast<Map<String, dynamic>>();
    contactBook = [];
    contacts = [];
    for (final j in list) {
      final digits = j['phone'] as String? ?? '';
      final id = 'tc-$digits';
      contactBook.add(
        ContactItem(
          id: id,
          name: j['name'] as String? ?? 'Contacto',
          phone: _maskPhone(digits),
          icon: Icons.person,
        ),
      );
      contactDigits[id] = digits;
      contacts.add(id);
    }
  });

  Future<void> _loadMedicalCard() => _quiet(() async {
    final m = await api.get('me/medical-card') as Map<String, dynamic>;
    medical = MedicalCard(
      sangre: (m['bloodType'] as String?) ?? 'No sé',
      alergias: (m['allergies'] as String?) ?? '',
      condiciones: (m['conditions'] as String?) ?? '',
      vive: ((m['livesWith'] as List?) ?? const [])
          .map((v) => Api2App.livesWith[v])
          .whereType<String>()
          .toList(),
    );
  });

  Future<void> _loadLocation() => _quiet(() async {
    final loc = await api.get('me/location') as Map<String, dynamic>;
    final addr = loc['addressText'] as String?;
    if (addr != null && addr.isNotEmpty) {
      userAddress = addr;
      regAddress = addr;
    }
    final lat = (loc['lat'] as num?)?.toDouble();
    final lng = (loc['lng'] as num?)?.toDouble();
    if (lat != null) regLat = lat;
    if (lng != null) regLng = lng;
    final zName = loc['zoneName'] as String?;
    if (zName != null && zName.isNotEmpty) zoneName = zName;
    // La zona guardada no cubre la casa (cuentas de antes): se vuelve a ubicar en la zona de su barrio.
    if (loc['zoneCoversHome'] == false && lat != null && lng != null) {
      unawaited(
        updateUserLocation(address: userAddress, lat: lat, lng: lng),
      );
    }
  });

  /// Recarga lo que muestra cada pantalla al entrar a ella.
  void _onEnter(String name) {
    if (!connected || tourName != null) return;
    switch (name) {
      case 'perfil':
        _loadLocation().then((_) => refresh());
      case 'servicios':
        _loadServices().then((_) => refresh());
      case 'svc':
        _loadServiceDetail(selService);
      case 'muro':
        _loadPosts().then((_) => refresh());
      case 'tablero':
        _loadReports().then((_) => refresh());
      case 'recursos':
        _loadResources().then((_) => refresh());
      case 'apoyo':
        _loadGroups().then((_) => refresh());
      case 'mapa':
        _loadPins().then((_) => refresh());
      case 'red':
        _loadInventory().then((_) => refresh());
      case 'chat':
        _pollChat();
      case 'sos-sent':
        _pollSos();
    }
  }

  // ================================================================ sondeo

  void _startPolling() {
    if (_disposed) return;
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
    _chatTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (screen == 'chat') _pollChat();
      if (connected && !offline) _incomingVoiceCall();
      if (screen == 'sos-sent') _pollSos();
    });
  }

  Future<void> _incomingVoiceCall() async {
    if (_disposed || internetCall.active || tourName != null) return;
    if (await internetCall.checkIncoming() && !_disposed) {
      final incoming = internetCall.details!;
      final name = incoming['callerName'] as String? ?? 'Vecino';
      callWith = {'name': name, 'icon': Icons.person, 'emergency': false};
      convIds[name] = incoming['conversationId'] as String;
      go('llamada');
    }
  }

  void _stopPolling() {
    unawaited(SoundService.instance.stopAll());
    if (internetCall.active) unawaited(internetCall.end());
    _pollTimer?.cancel();
    _chatTimer?.cancel();
    _pollTimer = null;
    _chatTimer = null;
  }

  Future<void> _poll() async {
    if (!connected || offline || tourName != null) return;
    await _loadMe();
    await _checkNearbySos();
    await _refreshLive();
    if (emergency) await loadZoneDashboard();
    await loadConversations(notify: true);
    lastSyncAt = DateTime.now();
    refresh();
  }

  // ============================================================ Visto Bueno

  Future<void> _syncVb(String serviceId) async {
    if (!connected) return;
    final given = vbGiven[serviceId] == true;
    try {
      final r = given
          ? await api.post('services/$serviceId/endorsements')
          : await api.delete('services/$serviceId/endorsements/me');
      if (r is Map) {
        vbGiven[serviceId] = r['endorsedByMe'] == true;
        final total = (r['endorsementCount'] as num?)?.toInt();
        final s = services.where((x) => x.id == serviceId).firstOrNull;
        if (s != null && total != null) {
          s.vb = total - (vbGiven[serviceId] == true ? 1 : 0);
          _vbBase[serviceId] = s.vb;
        }
        refresh();
      }
    } on ApiException catch (e) {
      vbGiven[serviceId] = !given;
      refresh();
      toast(e.message, icon: 'error');
    }
  }

  // ================================================================ chat

  /// Botón "Mensaje" de un oficio: abre el chat con el dueño.
  Future<void> contactService(ServiceItem s) async {
    if (!connected) {
      openChat(s.name);
      return;
    }
    try {
      final ref =
          await api.post('services/${s.id}/contact') as Map<String, dynamic>;
      openChat(s.name, conversationId: ref['conversationId'] as String?);
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  Future<void> _respondPost(PostItem post) async {
    try {
      await api.post('posts/${post.id}/responses');
      helped[post.id] = true;
      toast('Solicitud enviada al autor', icon: 'check_circle');
      await _loadPosts();
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  Future<void> _acceptPostResponse(String postId, String responseId) async {
    try {
      final ref = await api.post('posts/$postId/responses/$responseId/accept')
          as Map<String, dynamic>;
      toast('Solicitud aceptada. Se abrió el chat.', icon: 'check_circle');
      final convId = ref['conversationId'] as String?;
      await _loadPosts();
      if (convId != null) {
        final post = posts.where((p) => p.id == postId).firstOrNull;
        final resp = post?.incomingResponses
            .where((r) => r.id == responseId)
            .firstOrNull;
        openChat(resp?.responderName ?? 'Vecino', conversationId: convId);
      }
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  Future<void> _rejectPostResponse(String postId, String responseId) async {
    try {
      await api.post('posts/$postId/responses/$responseId/reject');
      toast('Solicitud rechazada');
      await _loadPosts();
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  Future<void> _updatePostStatus(String postId, String status) async {
    try {
      await api.patch('posts/$postId/status', body: {'status': status});
      toast(
        status == 'RESOLVED'
            ? '¡Favor marcado como resuelto!'
            : 'Estado actualizado a $status',
        icon: 'check_circle',
      );
      await Future.wait([
        _loadPosts(),
        _loadPins(),
      ]);
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  Future<void> _loadMessages(
    String userName,
    String conversationId, {
    bool replace = false,
  }) async {
    try {
      final after = replace ? null : _lastMsgAt[conversationId];
      final list = (await api.get(
        'conversations/$conversationId/messages',
        query: {'after': after, 'limit': 100},
      ) as List).cast<Map<String, dynamic>>();
      if (replace) chats[userName] = [];
      final box = chats.putIfAbsent(userName, () => []);
      if (replace == false && list.isNotEmpty) {
        // Quita los "enviando" propios que ya llegaron del servidor.
        box.removeWhere((m) => m.from == 'me' && m.pending && !offline);
      }
      bool receivedNewThem = false;
      for (final m in list) {
        final id = m['id'] as String?;
        if (id != null && !_seenMsgIds.add(id) && !replace) continue;
        final isMe = m['senderId'] == userId;
        if (!isMe && m['system'] != true && !replace) {
          receivedNewThem = true;
        }
        box.add(
          ChatMessage(
            from: m['system'] == true
                ? 'sys'
                : (isMe ? 'me' : 'them'),
            text: (m['text'] as String?) ?? '',
            time: Api2App.clock(m['createdAt']),
          ),
        );
        _lastMsgAt[conversationId] = m['createdAt'] as String?;
      }
      if (receivedNewThem) {
        unawaited(SoundService.instance.playMessagePop());
      }
      refresh();
    } on ApiException catch (_) {}
  }

  void _pollChat() {
    final name = chatWith;
    final convId = name == null ? null : convIds[name];
    if (convId == null || offline) return;
    _loadMessages(name!, convId);
  }

  Future<void> _sendChatRemote(String userName, String text) async {
    final convId = convIds[userName];
    if (convId == null) return;
    final clientId = newClientId();
    if (offline) {
      await _enqueue('MESSAGE', {
        'conversationId': convId,
        'clientId': clientId,
        'text': text,
      });
      return;
    }
    try {
      final m = await api.post(
        'conversations/$convId/messages',
        body: {'clientId': clientId, 'text': text},
      ) as Map<String, dynamic>;
      final id = m['id'] as String?;
      if (id != null) _seenMsgIds.add(id);
      _lastMsgAt[convId] = m['createdAt'] as String?;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  // ============================================================ publicar

  /// Busca dónde está el vecino ahora para lo que va a publicar. Sin GPS usa su casa.
  Future<void> locateForPublish() async {
    if (pubLocating) return;
    pubLocating = true;
    refresh();
    try {
      final pos = await location.current();
      if (_disposed) return;
      if (pos.real) {
        pubLat = pos.lat;
        pubLng = pos.lng;
        pubFromGps = true;
        pubPlace =
            await _placeName(pos.lat, pos.lng) ??
            (location.approximate
                ? 'Cerca de ti (aproximado)'
                : 'Tu ubicación actual');
      } else {
        pubLat = regLat;
        pubLng = regLng;
        pubFromGps = false;
        pubPlace = userAddress.isNotEmpty ? userAddress : null;
      }
    } catch (_) {
      pubLat = regLat;
      pubLng = regLng;
      pubFromGps = false;
      pubPlace = userAddress.isNotEmpty ? userAddress : null;
    } finally {
      pubLocating = false;
      if (!_disposed) refresh();
    }
  }

  /// "Jr. Los Olivos 120, Zárate" a partir de coordenadas (OpenStreetMap). null sin internet.
  Future<String?> _placeName(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json'
        '&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final res = await http
          .get(
            uri,
            headers: {'User-Agent': 'NearbyApp/1.0', 'Accept-Language': 'es'},
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final a =
          (jsonDecode(res.body) as Map<String, dynamic>)['address']
              as Map<String, dynamic>?;
      if (a == null) return null;
      final road = (a['road'] ?? a['pedestrian'] ?? a['footway']) as String?;
      final number = a['house_number'] as String?;
      final area =
          (a['suburb'] ??
                  a['neighbourhood'] ??
                  a['city_district'] ??
                  a['city'] ??
                  a['town'])
              as String?;
      if (road == null) return area;
      final street = number == null ? road : '$road $number';
      return area == null ? street : '$street, $area';
    } catch (_) {
      return null;
    }
  }

  Future<void> _publishRemote({
    required String? type,
    required String? catId,
    required String text,
    String? where,
    String? prio,
  }) async {
    final clientId = newClientId();
    final effLat = pubLat ?? regLat ?? homeZoneLat ?? location.last?.lat;
    final effLng = pubLng ?? regLng ?? homeZoneLng ?? location.last?.lng;
    try {
      switch (type) {
        case 'need':
        case 'offer':
          {
            final ttlHours = type == 'need' ? 24 : 48;
            final expiresAt = DateTime.now()
                .add(Duration(hours: ttlHours))
                .millisecondsSinceEpoch;
            String? uploadedPhotoUrl;
            if (pub.photoBytes != null && !offline && connected) {
              try {
                final uploadRes = await api.upload(
                  'POST',
                  'files',
                  parts: () => [
                    _photoPart(
                      'photo',
                      pub.photoBytes!,
                      pub.photoName ?? 'foto.jpg',
                    ),
                  ],
                ) as Map<String, dynamic>;
                uploadedPhotoUrl = uploadRes['url'] as String?;
              } catch (_) {
                /* Si falla la subida de foto se continúa con la publicación */
              }
            }
            final payload = {
              'clientId': clientId,
              'type': type == 'need' ? 'NEED' : 'OFFER',
              'category':
                  Api2App.reverse(Api2App.postCat, catId) ?? 'TEMPORARY_HELP',
              if (text.isNotEmpty) 'text': text,
              'photoUrl': ?uploadedPhotoUrl,
              'lat': ?effLat,
              'lng': ?effLng,
              'expiresAt': expiresAt,
              'ttl': Duration(hours: ttlHours).inSeconds,
            };
            if (offline) {
              await _enqueue('POST', payload, expiresAt: expiresAt);
            } else {
              try {
                await api.post('posts', body: payload);
                await Future.wait([
                  _loadPosts(),
                  _loadPins(),
                ]);
              } on ApiException catch (e) {
                if (e.isNetwork) {
                  await _enqueue('POST', payload, expiresAt: expiresAt);
                  toast(
                    'Sin internet: tu publicación se enviará cuando vuelva la señal',
                    icon: 'cloud_off',
                  );
                } else {
                  rethrow;
                }
              }
            }
          }
        case 'vulnerable':
          {
            final gps = pubLat != null && pubLng != null
                ? null
                : await location.current();
            final vulnLat = effLat ?? gps?.lat;
            final vulnLng = effLng ?? gps?.lng;
            final payload = {
              'clientId': clientId,
              'category': Api2App.reverse(Api2App.vulnCat, catId) ?? 'INJURED',
              'priority': prio == 'media' ? 'MEDIUM' : 'HIGH',
              if (text.isNotEmpty) 'detail': text,
              'addressText': ?where,
              'lat': ?vulnLat,
              'lng': ?vulnLng,
            };
            if (offline) {
              await _enqueue('VULNERABLE_REPORT', payload);
            } else {
              await api.post('vulnerable-reports', body: payload);
              await Future.wait([
                _loadReports(),
                _loadPins(),
              ]);
            }
          }
        case 'needres':
        case 'offerres':
          await _whenOnline(() async {
            await api.post(
              'resources',
              body: {
                'resourceType':
                    Api2App.reverse(Api2App.resourceType, catId) ?? 'WATER',
                'kind': type == 'needres' ? 'NEED' : 'HAVE',
                'text': text.isNotEmpty
                    ? text
                    : (kResources
                              .where((r) => r.id == catId)
                              .firstOrNull
                              ?.label ??
                          'Recurso'),
              },
            );
            await Future.wait([
              _loadResources(),
              _loadPins(),
            ]);
          });
        case 'service':
          await _whenOnline(() async {
            final cat = kServCats.where((c) => c.id == catId).firstOrNull;
            await api.post(
              'services',
              body: {
                'title': text.isNotEmpty ? text : (cat?.label ?? 'Oficio'),
                'category':
                    Api2App.reverse(Api2App.serviceCat, catId) ?? 'OTHER',
                'availableInEmergency': true,
                'lat': ?effLat,
                'lng': ?effLng,
              },
            );
            await Future.wait([
              _loadServices(),
              _loadPins(),
            ]);
          });
      }
      refresh();
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  /// Lo que no entra en la cola del backend se guarda y se envía al reconectar.
  Future<void> _whenOnline(Future<void> Function() send) async {
    if (offline) {
      _pendingCalls.add(send);
    } else {
      await send();
    }
  }

  /// Intentos que un envío rechazado por el backend (status ERROR) se vuelve a mandar.
  static const _maxOutboxRetries = 3;

  /// Encola un envío hecho sin internet: primero en SQLite (en una transacción) y recién después
  /// en la cola en memoria y la pantalla, para que no se pierda si el sistema cierra la app.
  Future<void> _enqueue(
    String kind,
    Map<String, Object?> payload, {
    int? expiresAt,
  }) async {
    final effectiveExpiresAt =
        expiresAt ?? (payload['expiresAt'] as num?)?.toInt();
    final entry = OutboxEntry(
      id: (payload['clientId'] as String?) ?? newClientId(),
      type: kind,
      payload: payload,
      expiresAt: effectiveExpiresAt,
    );
    await outboxStorage.insert(entry);
    if (_disposed) return;
    _outbox.add(entry);
    refresh();
  }

  /// Evalúa si un elemento en la cola offline ha superado su tiempo de vida (TTL).
  bool _isEntryExpired(OutboxEntry entry, [int? nowMs]) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (entry.expiresAt != null) {
      return now >= entry.expiresAt!;
    }
    final payloadExpiresAt = (entry.payload['expiresAt'] as num?)?.toInt();
    if (payloadExpiresAt != null) {
      return now >= payloadExpiresAt;
    }
    final ageMs = now - entry.createdAt;
    switch (entry.type) {
      case 'POST':
        // Favores: caducan a las 24 horas por defecto
        return ageMs >= const Duration(hours: 24).inMilliseconds;
      case 'SOS':
        // Emergencias en tiempo real: caducan a las 12 horas
        return ageMs >= const Duration(hours: 12).inMilliseconds;
      default:
        // Límite general de seguridad: 48 horas
        return ageMs >= const Duration(hours: 48).inMilliseconds;
    }
  }

  /// Al abrir la app: recupera lo que quedó pendiente en SQLite limpiando los ya caducados.
  Future<void> _restoreOutbox() async {
    final saved = await outboxStorage.loadAll();
    if (_disposed || saved.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expired = saved.where((e) => _isEntryExpired(e, now)).toList();
    if (expired.isNotEmpty) {
      await outboxStorage.delete(expired.map((e) => e.id));
    }
    final valid = saved.where((e) => !_isEntryExpired(e, now)).toList();
    final known = _outbox.map((e) => e.id).toSet();
    _outbox.insertAll(0, valid.where((e) => !known.contains(e.id)));
  }

  /// Escucha los cambios de red. Sin red, la app pasa sola a "sin conexión" (los envíos se
  /// encolan); al volver datos móviles, wifi o ethernet, envía la cola sin que el vecino haga nada.
  void _watchConnectivity() {
    if (_connSub != null) return;
    try {
      _connSub = Connectivity().onConnectivityChanged.listen(
        _onConnectivity,
        onError: (_) {},
      );
    } catch (_) {
      // Sin el plugin (pruebas): no hay aviso automático.
    }
  }

  void _onConnectivity(List<ConnectivityResult> results) {
    if (_disposed) return;
    final online = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
    if (!online) {
      if (!offline) {
        offline = true;
        _autoOffline = true;
        toast(
          'Sin conexión: lo que envíes se guarda y sale solo al volver la señal',
          icon: 'cloud_off',
        );
      }
      return;
    }
    if (_autoOffline) {
      _autoOffline = false;
      offline = false;
      refresh();
    }
    if (!offline && (_outbox.isNotEmpty || _pendingCalls.isNotEmpty)) {
      final n = _outbox.length;
      _flushOutbox().then((_) {
        if (n > 0 && _outbox.isEmpty && !_disposed) {
          toast(
            'Conexión recuperada · $n envío(s) sincronizado(s)',
            icon: 'cloud_done',
          );
        }
      });
    }
  }

  /// Envía la cola en orden (POST /sync/outbox). Solo borra de SQLite lo que el backend
  /// confirmó con una respuesta 2xx; si no hay respuesta, todo queda para el próximo intento.
  Future<void> _flushOutbox() async {
    if (!connected || _isFlushing) return;
    _isFlushing = true;
    try {
      if (_outbox.isNotEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final expired = <OutboxEntry>[];
        final active = <OutboxEntry>[];

        for (final entry in _outbox) {
          if (_isEntryExpired(entry, now)) {
            expired.add(entry);
          } else {
            active.add(entry);
          }
        }

        // Si expiraron publicaciones o alertas mientras no había red, se descartan automáticamente
        if (expired.isNotEmpty) {
          await outboxStorage.delete(expired.map((e) => e.id));
          final expiredIds = expired.map((e) => e.id).toSet();
          _outbox.removeWhere((e) => expiredIds.contains(e.id));
          for (final e in expired) {
            if (e.type == 'POST') {
              final text = (e.payload['text'] as String?) ?? '';
              final cat = (e.payload['category'] as String?) ?? 'favor';
              final topic = text.isNotEmpty
                  ? (text.length > 25 ? '${text.substring(0, 25)}...' : text)
                  : cat;
              toast(
                'Publicación descartada: "$topic" expiró tras más de 24h sin conexión.',
                icon: 'schedule',
              );
            } else if (e.type == 'SOS') {
              toast(
                'Alerta SOS descartada por antigüedad (>12h).',
                icon: 'warning',
              );
            }
          }
          refresh();
        }

        if (active.isEmpty) {
          return;
        }

        final batch = List<OutboxEntry>.from(active);
        try {
          final results = await api.post(
            'sync/outbox',
            body: batch.map((e) => e.toItem()).toList(),
          ) as List;
          // 2xx: el backend procesó la lista en orden; cada resultado es el de su elemento.
          final done = <OutboxEntry>[];
          final retry = <OutboxEntry>[];
          var rejected = 0;
          for (var i = 0; i < batch.length; i++) {
            final r = i < results.length ? results[i] : null;
            if (r is! Map) continue; // sin resultado: se reintenta tal cual
            if (r['status'] == 'ERROR') {
              if (r['code'] == 'EXPIRED') {
                done.add(batch[i]);
                toast(
                  'Publicación descartada por caducidad en el servidor',
                  icon: 'schedule',
                );
                continue;
              }
              final e = batch[i]..retryCount += 1;
              if (e.retryCount >= _maxOutboxRetries) {
                rejected++;
                done.add(e);
              } else {
                retry.add(e);
              }
            } else {
              done.add(batch[i]); // CREATED o DUPLICATE
            }
          }
          await outboxStorage.delete(done.map((e) => e.id));
          await outboxStorage.markRetry(retry);
          final sent = done.map((e) => e.id).toSet();
          _outbox.removeWhere((e) => sent.contains(e.id));
          if (rejected > 0) {
            toast(
              '$rejected envío(s) no se pudieron sincronizar',
              icon: 'error',
            );
          }
          if (_outbox.isNotEmpty) {
            _scheduleOutboxRetry();
          }
        } on ApiException catch (_) {
          // Sin 2xx (sin red o servidor caído): todo sigue en SQLite y en la cola con backoff.
          _scheduleOutboxRetry();
        }
      }
      final calls = List<Future<void> Function()>.from(_pendingCalls);
      _pendingCalls.clear();
      for (final c in calls) {
        try {
          await c();
        } catch (_) {}
      }
      await loadAll();
    } finally {
      _isFlushing = false;
    }
  }

  /// Reintenta la cola con Exponential Backoff y Jitter para proteger la red.
  void _scheduleOutboxRetry() {
    _outboxRetryTimer?.cancel();
    if (_disposed || offline || !connected || _outbox.isEmpty) return;
    final maxRetry = _outbox.map((e) => e.retryCount).fold<int>(0, math.max);
    final backoffSec = math.min(60, 1 << math.min(maxRetry, 6));
    final jitterMs = math.Random().nextInt(500);
    final delay = Duration(seconds: backoffSec, milliseconds: jitterMs);
    _outboxRetryTimer = Timer(delay, () {
      if (!_disposed && !offline && connected && _outbox.isNotEmpty) {
        unawaited(_flushOutbox());
      }
    });
  }

  // ================================================================ SOS

  static const _sosTypes = {
    'salud': 'HEALTH',
    'health': 'HEALTH',
    'fuego': 'FIRE',
    'fire': 'FIRE',
    'robo': 'ROBBERY',
    'robbery': 'ROBBERY',
    'sismo': 'EARTHQUAKE',
    'earthquake': 'EARTHQUAKE',
    'violencia': 'VIOLENCE',
    'violence': 'VIOLENCE',
    'violencia_domestica': 'VIOLENCE',
    'domestic_violence': 'VIOLENCE',
    'otro': 'OTHER',
    'other': 'OTHER',
  };

  /// Envía el SOS (al terminar la cuenta regresiva) con protección contra toques duplicados.
  Future<void> sendSos() async {
    if (_isSendingSos) return;
    _isSendingSos = true;
    try {
      sosResult = null;
      sosDetail = null;
      if (!connected) return;
      final pos = await location.current();
      final payload = {
        'clientId': newClientId(),
        'lat': pos.lat,
        'lng': pos.lng,
        if (sosType != null) 'type': _sosTypes[sosType] ?? 'OTHER',
      };
      if (offline) {
        await _enqueue('SOS', payload);
        return;
      }
      try {
        final r = await api.post('sos', body: payload) as Map<String, dynamic>;
        sosResult = r;
        lastCode = r['smsCode'] as String? ?? lastCode;
        if (r['zoneEmergencyActivated'] == true) await _loadMe();
        refresh();
      } on ApiException catch (e) {
        if (e.isNetwork) {
          await _enqueue('SOS', payload);
          toast(
            'Sin internet: tu alerta se envía apenas vuelva la señal',
            icon: 'cloud_off',
          );
        } else {
          toast(e.message, icon: 'error');
        }
      }
    } finally {
      _isSendingSos = false;
    }
  }

  Future<void> _pollSos() async {
    final id = sosResult?['id'] as String?;
    if (id == null || offline) return;
    try {
      sosDetail = await api.get('sos/$id') as Map<String, dynamic>;
      refresh();
    } on ApiException catch (_) {}
  }

  /// "Estoy a salvo · cerrar alerta".
  Future<void> sosSafe() async {
    if (isSilentMode) {
      unawaited(setSilentMode(false));
    }
    final id = sosResult?['id'] as String?;
    if (id == null || !connected) return;
    try {
      await api.post('sos/$id/safe');
      sosResult = null;
      sosDetail = null;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  /// Check-in "Estoy bien" / "Necesito ayuda".
  Future<int?> sendCheckIn(bool safe) async {
    if (!connected) return null;
    final status = safe ? 'SAFE' : 'NEED_HELP';
    if (offline) {
      await _enqueue('CHECK_IN', {'status': status});
      return null;
    }
    try {
      final r = await api.post(
        'check-ins',
        body: {'status': status},
      ) as Map<String, dynamic>;
      unawaited(loadZoneDashboard());
      return (r['contactsNotified'] as num?)?.toInt();
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return null;
    }
  }

  /// SOS de vecinos cercanos: abre la pantalla de alerta recibida.
  Future<void> _checkNearbySos() => _quiet(() async {
    final list = (await api.get('sos/nearby') as List)
        .cast<Map<String, dynamic>>();
    final mine = sosResult?['id'];
    for (final s in list) {
      final id = s['id'] as String?;
      if (id == null || id == mine || _seenSos.contains(id)) continue;
      _seenSos.add(id);
      if ((s['minutesAgo'] as num? ?? 99) > 30) continue;
      incomingSos = s;
      if (![
        'sos',
        'sos-countdown',
        'sos-sent',
        'llamada',
        'splash',
        'login',
        'otp',
      ].contains(screen)) {
        go('alerta-recibida');
      }
      break;
    }
  });

  /// Respuesta a una alerta recibida: GOING o DECLINED.
  Future<void> respondSos(bool going) async {
    unawaited(SoundService.instance.stopSosAlarm());
    final id = incomingSos?['id'] as String?;
    if (id == null || !connected) return;
    try {
      await api.post(
        'sos/$id/responses',
        body: {'status': going ? 'GOING' : 'DECLINED'},
      );
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  // ===================================================== emergencia y tablero

  Future<void> _syncEmergency(bool on, String source) async {
    if (!connected) return;
    // Municipalidad o delegado: cambia el modo de toda la zona y avisa a los vecinos.
    if ((role == 'ADMIN' || role == 'DELEGATE') && zoneId != null) {
      try {
        await api.post(
          'admin/zones/$zoneId/mode',
          body: {
            'mode': on ? 'EMERGENCY' : 'NORMAL',
            'reason': on
                ? 'Activado desde la app por $userName'
                : 'Fin de la emergencia',
          },
        );
        await _loadMe();
        refresh();
        toast(
          on
              ? 'Avisamos a todos los vecinos de $zoneName'
              : 'La zona volvió al modo normal',
          icon: on ? 'campaign' : 'verified_user',
        );
      } on ApiException catch (e) {
        toast(e.message, icon: 'error');
      }
      return;
    }
    final action = on
        ? 'ACTIVATE_LOCAL_EMERGENCY'
        : (source == 'yo' ? 'CLEAR_LOCAL' : 'DISMISS');
    try {
      final me = await api.post('me/mode', body: {'action': action});
      _applyUser(me as Map<String, dynamic>);
      refresh();
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  /// "Voy yo" en un reporte del tablero.
  Future<void> goToReport(ReportItem r) async {
    going[r.id] = true;
    refresh();
    if (!connected || r.id is! String) return;
    try {
      final d = await api.post(
        'vulnerable-reports/${r.id}/assign',
      ) as Map<String, dynamic>;
      r.status = Api2App.reportStatus[d['status']] ?? 'c';
      r.by = d['assignedLabel'] as String? ?? firstName;
      refresh();
    } on ApiException catch (e) {
      going[r.id] = false;
      refresh();
      toast(e.message, icon: 'error');
    }
  }

  /// Marcar un reporte como atendido (quien va o la brigada).
  Future<void> markAttended(ReportItem r) async {
    r.status = 'a';
    refresh();
    if (!connected || r.id is! String) return;
    try {
      await api.patch(
        'vulnerable-reports/${r.id}/status',
        body: {'status': 'ATTENDED'},
      );
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      await _loadReports();
      refresh();
    }
  }

  Future<void> joinGroup(GroupItem g) async {
    joined[g.name] = true;
    refresh();
    if (!connected || g.id == null) return;
    try {
      await api.post('support-groups/${g.id}/members');
      await _loadGroups();
      refresh();
    } on ApiException catch (e) {
      joined[g.name] = false;
      refresh();
      toast(e.message, icon: 'error');
    }
  }

  // ======================================================= IA · Protocolo Lázaro

  /// Plan de rescate en el backend (brigada). Devuelve false si no aplica.
  Future<bool> _runAiRemote() async {
    if (!connected || !isBrigade) return false;
    try {
      final plan = await api.post('ai/rescue-plans') as Map<String, dynamic>;
      await _loadReports();
      aiMissions.clear();
      for (final m
          in (plan['missions'] as List? ?? const [])
              .cast<Map<String, dynamic>>()) {
        final report = reports.where((r) => r.id == m['reportId']).firstOrNull;
        aiMissions[m['reportId']] = (m['assignments'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .where((a) => Api2App.aiTag[a['tag']] != null)
            .map((a) {
              final tag = Api2App.aiTag[a['tag']];
              final inv = remoteInventory
                  ?.where((h) => h.who == a['userName'] && h.tag == tag)
                  .firstOrNull;
              return HistoryItem(
                id: (a['userId'] as String?) ?? '',
                who: (a['userName'] as String?) ?? 'Vecino',
                zona: inv?.zona ?? zoneName,
                src: inv?.src ?? 'IA',
                when: inv?.when ?? '',
                txt: (a['reason'] as String?) ?? (a['label'] as String? ?? ''),
                x: inv?.x ?? report?.x ?? 50.0,
                y: inv?.y ?? report?.y ?? 50.0,
                tag: tag,
              );
            })
            .toList();
      }
      aiMs = (plan['durationMs'] as num?)?.toDouble() ?? aiMs;
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }

  Future<void> _notifyMissionRemote(dynamic reportId) async {
    if (!connected || reportId is! String) return;
    try {
      final r = await api.post(
        'ai/missions/$reportId/notify',
      ) as Map<String, dynamic>;
      final rep = reports.where((x) => x.id == reportId).firstOrNull;
      if (rep != null) {
        rep.status = 'c';
        rep.by = r['assignedLabel'] as String? ?? rep.by;
      }
      refresh();
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  /// Micrófono inteligente con la IA del backend (con respaldo local).
  Future<Map<String, dynamic>> classifyRemote(String text) async {
    final local = classify(text);
    if (!connected || offline || text.trim().isEmpty) return local;
    try {
      final r = await api.post(
        'ai/classify',
        body: {'text': text, 'mode': emergency ? 'EMERGENCY' : 'NORMAL'},
      ) as Map<String, dynamic>;
      final type = r['type'] as String?;
      final kind = r['kind'] as String?;
      final cat = r['category'] as String?;
      final String? appType = switch (type) {
        'VULNERABLE' => 'vulnerable',
        'RESOURCE' => kind == 'OFFER' ? 'offerres' : 'needres',
        'OFFER' => 'offer',
        'NEED' => 'need',
        _ => local['type'] as String?,
      };
      final appCat =
          Api2App.vulnCat[cat] ??
          Api2App.resourceType[cat] ??
          Api2App.postCat[cat] ??
          local['cat'] as String?;
      final loc = (r['location'] as String?) ?? local['loc'] as String?;
      final prio = r['priority'] == 'HIGH' ? 'alta' : 'media';
      final chips = <List<String>>[];
      for (final c in (r['chips'] as List?) ?? const []) {
        chips.add([chips.isEmpty ? 'category' : 'auto_awesome', '$c']);
      }
      if (type == 'VULNERABLE') {
        chips.add([
          'priority_high',
          'Prioridad ${prio == 'alta' ? 'alta' : 'media'}',
        ]);
      }
      if (loc != null) chips.add(['location_on', loc]);
      return {
        'type': appType,
        'cat': appCat,
        'prio': prio,
        'loc': loc,
        'chips': chips.isNotEmpty ? chips : local['chips'],
        'label': chips.isNotEmpty
            ? chips.map((c) => c[1]).join(' · ')
            : local['label'],
      };
    } on ApiException catch (_) {
      return local;
    }
  }

  // ================================================================ SMS

  /// Brigadista: reporte recibido por SMS y descomprimido en el teléfono.
  Future<void> _reportFromSmsRemote(String code, Map<String, dynamic> d) async {
    if (!connected) return;
    try {
      // El backend decodifica solo el código; el GPS (#G:lat,lng) va aparte.
      final gps = smsCoordinates(code);
      code = extractSosCode(code) ?? code;
      final decoded = await api.post(
        'sms/decode',
        body: {'code': code},
      ) as Map<String, dynamic>;
      final typeLetter = code.length > 7 ? code[7] : 'H';
      final catKey = kTypeCode.entries
          .where((e) => e.value == typeLetter)
          .map((e) => e.key)
          .firstOrNull;
      final decodedType = decoded['type'] as String?;
      final category = Api2App.vulnCat.containsKey(decodedType)
          ? decodedType!
          : (Api2App.reverse(Api2App.vulnCat, catKey) ?? 'INJURED');
      await api.post(
        'vulnerable-reports',
        body: {
          'clientId': newClientId(),
          'category': category,
          'priority':
              decoded['priority'] == 'MEDIA' || decoded['priority'] == 'MEDIUM'
              ? 'MEDIUM'
              : 'HIGH',
          'detail': 'Recibido por SMS sin internet ($code)',
          'addressText': decoded['addressText'] ?? d['where'],
          if (gps != null) ...{
            'lat': gps.lat,
            'lng': gps.lng,
          } else if (decoded['lat'] != null) ...{
            'lat': decoded['lat'],
            'lng': decoded['lng'],
          },
        },
      );
      await _loadReports();
      refresh();
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  // ============================================== foto, roles y modo Prevención

  static http.MultipartFile _photoPart(
    String field,
    List<int> bytes,
    String filename,
  ) {
    final png = filename.toLowerCase().endsWith('.png');
    return http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: png ? 'foto.png' : 'foto.jpg',
      contentType: MediaType('image', png ? 'png' : 'jpeg'),
    );
  }

  /// Sube la foto de perfil (ya comprimida por el selector). true si quedó guardada.
  Future<bool> uploadProfilePhoto(List<int> bytes, String filename) async {
    if (!connected) {
      toast('Necesitas iniciar sesión para cambiar tu foto', icon: 'lock');
      return false;
    }
    try {
      final me = await api.upload(
        'PUT',
        'me/photo',
        parts: () => [_photoPart('photo', bytes, filename)],
      );
      _applyUser(me as Map<String, dynamic>);
      refresh();
      toast('Tu foto quedó lista', icon: 'check_circle');
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }

  Future<void> removeProfilePhoto() async {
    if (!connected) return;
    try {
      final me = await api.delete('me/photo');
      _applyUser(me as Map<String, dynamic>);
      refresh();
      toast('Quitamos tu foto', icon: 'check_circle');
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  Future<void> _loadBrigadeRequest() => _quiet(() async {
    if (role != 'NEIGHBOR') return;
    final r = await api.get('me/brigade-request') as Map<String, dynamic>;
    brigadeRequest = (r['status'] as String?) ?? 'NONE';
  });

  /// El vecino pide ser brigadista. La Municipalidad lo aprueba desde su panel.
  Future<bool> requestBrigade(String skills) async {
    if (!connected) {
      toast('Necesitas iniciar sesión', icon: 'lock');
      return false;
    }
    try {
      final r = await api.post(
        'me/brigade-request',
        body: {'skills': skills.trim().isEmpty ? null : skills.trim()},
      ) as Map<String, dynamic>;
      brigadeRequest = (r['status'] as String?) ?? 'PENDING';
      refresh();
      toast(
        'Enviamos tu solicitud. Te avisaremos cuando la Municipalidad responda.',
        icon: 'shield_person',
      );
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }

  Future<void> loadAdminRequests() => _quiet(() async {
    if (!isAdmin) return;
    final list = await api.get('admin/brigade-requests') as List;
    adminRequests = list.cast<Map<String, dynamic>>();
    refresh();
  });

  /// Aprobar o rechazar una solicitud de brigadista.
  Future<void> decideBrigadeRequest(String id, {required bool approve}) async {
    try {
      await api.post(
        'admin/brigade-requests/$id/${approve ? 'approve' : 'reject'}',
      );
      adminRequests.removeWhere((r) => r['id'] == id);
      refresh();
      toast(
        approve ? 'Ahora es brigadista' : 'Solicitud rechazada',
        icon: approve ? 'verified_user' : 'close',
      );
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      unawaited(loadAdminRequests());
    }
  }

  /// Busca un vecino por celular para cambiarle el rol (solo Municipalidad).
  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    try {
      return await api.get('admin/users', query: {'phone': phone})
          as Map<String, dynamic>;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> changeUserRole(
    String userId,
    String newRole,
  ) async {
    try {
      final u = await api.put(
        'admin/users/$userId/role',
        body: {'role': newRole},
      ) as Map<String, dynamic>;
      toast('Rol actualizado', icon: 'check_circle');
      return u;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return null;
    }
  }

  /// Municipalidad: cambia el modo de toda la zona (NORMAL, PREVENTION o EMERGENCY) y avisa.
  Future<bool> setZoneMode(String mode, String reason) async {
    if (!isAdmin || zoneId == null) {
      toast(
        'Solo la Municipalidad puede cambiar el modo de la zona',
        icon: 'lock',
      );
      return false;
    }
    try {
      await api.post(
        'admin/zones/$zoneId/mode',
        body: {
          'mode': mode,
          'reason': reason.trim().isEmpty ? null : reason.trim(),
        },
      );
      await _loadMe();
      if (prevention) await loadRiskReports();
      refresh();
      toast(switch (mode) {
        'PREVENTION' => 'Activamos Prevención El Niño en $zoneName',
        'EMERGENCY' => 'Activamos el modo emergencia en $zoneName',
        _ => '$zoneName volvió al modo normal',
      }, icon: 'campaign');
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }

  /// El vecino vuelve al modo normal solo en su app (la zona sigue en su modo).
  Future<void> dismissZoneMode() async {
    if (!connected) {
      effectiveMode = 'NORMAL';
      if (screen == 'prevencion') go('home', reset: true);
      refresh();
      return;
    }
    try {
      final me = await api.post('me/mode', body: {'action': 'DISMISS'});
      _applyUser(me as Map<String, dynamic>);
      if (screen == 'prevencion') go('home', reset: true);
      refresh();
      toast('Volviste al modo normal en tu app', icon: 'check_circle');
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  // ============================================================ mensajes y perfil

  /// Lo que publican los demás vecinos: muro y mapa siempre; oficios, tablero, recursos y grupos según
  /// la pantalla o el modo. Avisa cuando alguien cercano pide u ofrece ayuda.
  Future<void> _refreshLive() async {
    final before = posts.map((p) => p.id).toSet();
    await Future.wait([
      _loadPosts(),
      _loadPins(),
      if (screen == 'servicios' || screen == 'home') _loadServices(),
      if (emergency || screen == 'tablero') _loadReports(),
      if (emergency || screen == 'recursos') _loadResources(),
      if (emergency || screen == 'apoyo') _loadGroups(),
      if (prevention || screen == 'prevencion') loadRiskReports(),
    ]);
    final fresh = posts
        .where((p) => !p.mine && !before.contains(p.id))
        .toList();
    if (before.isNotEmpty && fresh.isNotEmpty && screen != 'muro') {
      final p = fresh.first;
      toast(
        p.type == 'need'
            ? '${p.user} pide ayuda cerca de ti'
            : '${p.user} ofrece ayuda cerca de ti',
        icon: 'volunteer_activism',
      );
    }
  }

  /// Tablero de mi zona: cuántos vecinos dijeron «Estoy bien» desde que empezó la emergencia, etc.
  Future<void> loadZoneDashboard() => _quiet(() async {
    if (!connected || zoneId == null) return;
    zoneDashboard =
        await api.get('zones/$zoneId/dashboard') as Map<String, dynamic>;
    refresh();
  });

  Future<void> loadMyStats() => _quiet(() async {
    if (!connected) return;
    myStats = await api.get('me/stats') as Map<String, dynamic>;
  });

  /// Bandeja de mensajes. Con [notify], avisa si llegó algo nuevo fuera del chat.
  Future<void> loadConversations({bool notify = false}) => _quiet(() async {
    if (!connected) return;
    final before = unreadMessages;
    final list = await api.get('conversations') as List;
    conversations = list.cast<Map<String, dynamic>>();
    if (notify && unreadMessages > before && screen != 'chat') {
      final c = conversations.firstWhere(
        (c) => ((c['unread'] as num?)?.toInt() ?? 0) > 0,
        orElse: () => const {},
      );
      toast(
        'Nuevo mensaje de ${c['otherUserName'] ?? 'un vecino'}',
        icon: 'chat',
      );
    }
    refresh();
  });

  /// Abre una conversación de la bandeja.
  void openConversation(Map<String, dynamic> c) {
    final name = (c['otherUserName'] as String?) ?? 'Vecino';
    c['unread'] = 0;
    final contextText =
        (c['contextText'] as String?) ?? (c['serviceTitle'] as String?);
    openChat(
      name,
      conversationId: c['id'] as String?,
      contextText: contextText,
    );
  }

  /// Barrio (urbanización) y distrito de un punto, según OpenStreetMap. null sin internet.
  Future<({String? barrio, String? district})?> _placeParts(
    double lat,
    double lng,
  ) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json'
        '&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final res = await http
          .get(
            uri,
            headers: {'User-Agent': 'NearbyApp/1.0', 'Accept-Language': 'es'},
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final a =
          (jsonDecode(res.body) as Map<String, dynamic>)['address']
              as Map<String, dynamic>?;
      if (a == null) return null;
      final barrio =
          (a['neighbourhood'] ??
                  a['quarter'] ??
                  a['residential'] ??
                  a['hamlet'] ??
                  a['village'])
              as String?;
      final district =
          (a['city_district'] ??
                  a['suburb'] ??
                  a['town'] ??
                  a['city'] ??
                  a['county'])
              as String?;
      return (barrio: barrio, district: district);
    } catch (_) {
      return null;
    }
  }

  // ============================================================ Municipalidades

  /// Municipalidad: crea una zona de su distrito (el ADMIN indica el distrito).
  Future<bool> createZone({
    required String name,
    required double lat,
    required double lng,
    required int radiusM,
    String? district,
  }) async {
    try {
      final staff = isPlatformAdmin || isMunicipality;
      // Un vecino no escribe el distrito: sale del mapa (OpenStreetMap).
      final place = staff ? null : await _placeParts(lat, lng);
      final d = (district != null && district.trim().isNotEmpty)
          ? district.trim()
          : place?.district;
      await api.post(
        staff ? 'municipality/zones' : 'zones',
        body: {
          'name': name.trim(),
          'lat': lat,
          'lng': lng,
          'radiusM': radiusM,
          'district': ?d,
        },
      );
      if (staff) await loadManagedZones();
      toast('Zona «${name.trim()}» creada', icon: 'check_circle');
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }

  Future<void> loadMyMunicipality() => _quiet(() async {
    if (!connected) return;
    final r = await api.get('municipalities/mine') as Map<String, dynamic>;
    myMunicipality = r;
    refresh();
  });

  Future<void> loadMunicipalityDistricts() => _quiet(() async {
    if (!connected) return;
    final list = await api.get('municipalities/districts') as List;
    muniDistricts = list.cast<String>();
    refresh();
  });

  /// Registra la Municipalidad del responsable que ingresó. Queda pendiente hasta que Nearby la apruebe.
  Future<bool> registerMunicipality({
    required String name,
    required String district,
    required String ruc,
    required String contactName,
    required String contactPosition,
    required String email,
  }) async {
    if (!connected) {
      go('muni-registro');
      return false;
    }
    try {
      final r =
          await api.post(
                'municipalities',
                body: {
                  'name': name.trim(),
                  'district': district.trim(),
                  'ruc': ruc.trim(),
                  'contactName': contactName.trim(),
                  'contactPosition': contactPosition.trim().isEmpty
                      ? null
                      : contactPosition.trim(),
                  'email': email.trim(),
                },
              )
              as Map<String, dynamic>;
      myMunicipality = r;
      // Cuenta nueva: el nombre del responsable queda como su nombre en Nearby.
      if (regPending) {
        try {
          final me = await api.put('me', body: {'name': contactName.trim()});
          _applyUser(me as Map<String, dynamic>);
        } on ApiException catch (_) {}
      }
      refresh();
      toast(
        'Recibimos el registro. Te avisaremos cuando Nearby lo apruebe.',
        icon: 'check_circle',
      );
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }

  Future<void> loadMunicipalities() => _quiet(() async {
    if (!isPlatformAdmin) return;
    final list = await api.get('admin/municipalities') as List;
    municipalities = list.cast<Map<String, dynamic>>();
    refresh();
  });

  /// Plataforma: aprueba o rechaza el registro de una Municipalidad.
  Future<void> decideMunicipality(
    String id, {
    required bool approve,
    String? reason,
  }) async {
    try {
      await api.post(
        'admin/municipalities/$id/${approve ? 'approve' : 'reject'}',
        body: approve
            ? null
            : {
                'reason': reason == null || reason.trim().isEmpty
                    ? null
                    : reason.trim(),
              },
      );
      toast(
        approve ? 'Municipalidad aprobada' : 'Registro rechazado',
        icon: approve ? 'verified_user' : 'close',
      );
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
    await loadMunicipalities();
  }

  Future<void> loadManagedZones() => _quiet(() async {
    if (!isAdmin) return;
    final list = await api.get('municipality/zones') as List;
    managedZones = list.cast<Map<String, dynamic>>();
    refresh();
  });

  /// Cambia el modo de una zona de mi jurisdicción y avisa a sus vecinos.
  Future<bool> setModeOfZone(
    String id,
    String name,
    String mode,
    String reason,
  ) async {
    try {
      await api.post(
        'admin/zones/$id/mode',
        body: {
          'mode': mode,
          'reason': reason.trim().isEmpty ? null : reason.trim(),
        },
      );
      await loadManagedZones();
      if (id == zoneId) {
        await _loadMe();
        if (prevention) await loadRiskReports();
      }
      refresh();
      toast(switch (mode) {
        'PREVENTION' => 'Activamos Prevención El Niño en $name',
        'EMERGENCY' => 'Activamos el modo emergencia en $name',
        _ => '$name volvió al modo normal',
      }, icon: 'campaign');
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }

  Future<void> loadStaff() => _quiet(() async {
    if (!isMunicipality) return;
    final list = await api.get('municipality/staff') as List;
    staff = list.cast<Map<String, dynamic>>();
    refresh();
  });

  /// Agrega a un funcionario a mi Municipalidad por su celular.
  Future<bool> addStaff(String phone) async {
    try {
      await api.post('municipality/staff', body: {'phone': phone});
      await loadStaff();
      toast('Agregamos a tu equipo', icon: 'check_circle');
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }

  Future<void> removeStaff(String userId) async {
    try {
      await api.delete('municipality/staff/$userId');
      staff.removeWhere((s) => s['id'] == userId);
      refresh();
      toast('Ya no es parte del equipo', icon: 'check_circle');
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }

  Future<void> loadRiskReports() => _quiet(() async {
    if (!connected) return;
    final list = await api.get('risk-reports', query: {'hours': 48}) as List;
    riskReports = list.cast<Map<String, dynamic>>();
    refresh();
  });

  /// Reporte de riesgo (El Niño) con foto opcional. Usa la ubicación actual si hay GPS.
  Future<bool> reportRisk({
    required String category,
    required String text,
    List<int>? photo,
    String? photoName,
  }) async {
    if (!connected) {
      toast('Necesitas iniciar sesión para reportar', icon: 'lock');
      return false;
    }
    double? lat = regLat, lng = regLng;
    try {
      final pos = await location.current();
      lat = pos.lat;
      lng = pos.lng;
    } catch (_) {}
    final data = <String, Object?>{
      'clientId': newClientId(),
      'category': category,
      'text': text.trim().isEmpty ? null : text.trim(),
      'lat': lat,
      'lng': lng,
    };
    try {
      final Map<String, dynamic> created;
      if (photo != null) {
        created = await api.upload(
          'POST',
          'risk-reports',
          parts: () => [
            http.MultipartFile.fromString(
              'data',
              jsonEncode(data),
              contentType: MediaType('application', 'json'),
            ),
            _photoPart('photo', photo, photoName ?? 'riesgo.jpg'),
          ],
        ) as Map<String, dynamic>;
      } else {
        created =
            await api.post('risk-reports', body: data) as Map<String, dynamic>;
      }
      toast(
        created['escalated'] == true
            ? 'Gracias. Varios vecinos reportaron lo mismo: avisamos a la brigada.'
            : 'Gracias. Tu reporte ayuda a actuar antes.',
        icon: 'check_circle',
      );
      await loadRiskReports();
      return true;
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
      return false;
    }
  }
}
