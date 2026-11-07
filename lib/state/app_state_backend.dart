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
    _resetToServerData();
    if (user != null) _applyUser(user);
    await loadAll();
    _startPolling();
  }

  /// Sin datos de ejemplo una vez que hay sesión: todo viene del backend.
  void _resetToServerData() {
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
    userId = u['id'] as String?;
    final name = u['name'] as String?;
    if (name != null && name.isNotEmpty) userName = name;
    userPhone = (u['phone'] as String?) ?? userPhone;
    role = (u['role'] as String?) ?? 'NEIGHBOR';
    aiConsent = u['aiConsent'] != false;
    final zone = u['zone'] as Map<String, dynamic>?;
    zoneId = zone?['id'] as String?;
    zoneName = (zone?['name'] as String?) ?? zoneName;
    final zoneMode = zone?['mode'] as String?;
    final mode = (u['effectiveMode'] as String?) ?? 'NORMAL';
    final wasEmergency = emergency;
    effectiveMode = mode;
    emergency = mode == 'EMERGENCY';
    zoneEm = zoneMode == 'EMERGENCY';
    emSource = emergency && !zoneEm ? 'yo' : 'zona';
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
      String? resolvedZone;

      if (pos.city != null && pos.city!.isNotEmpty) {
        resolvedZone = pos.city;
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
              resolvedZone = district;
            } else if (district.isNotEmpty) {
              resolvedZone = district;
              resolvedAddress = district;
            }
          }
        }
      } catch (_) {}

      if (resolvedZone != null && resolvedZone.isNotEmpty) {
        zoneName = resolvedZone;
      }
      if (_disposed) return;
      regAddress =
          resolvedAddress ??
          'Ubicación actual (${pos.lat.toStringAsFixed(4)}, ${pos.lng.toStringAsFixed(4)})';
    } else {
      regAddress = 'Jr. Las Flores 245, SJL';
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
        'No pudimos leer el GPS: usamos la zona por defecto',
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
        final withZone = await api.put(
          'me/location',
          body: {'lat': regLat, 'lng': regLng, 'addressText': regAddress},
        );
        _applyUser(withZone as Map<String, dynamic>);
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
    if (!connected) return;
    try {
      await api.put(
        'me/medical-card',
        body: {
          'bloodType': sangre,
          'allergies': alergias,
          'conditions': condiciones,
          'livesWith': vive
              .map((v) => Api2App.reverse(Api2App.livesWith, v))
              .whereType<String>()
              .toList(),
        },
      );
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
      _loadServices(),
      _loadPosts(),
      _loadReports(),
      _loadResources(),
      _loadGroups(),
      _loadPins(),
      _loadInventory(),
      _loadContacts(),
      _loadMedicalCard(),
    ]);
    refresh();
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
      query: {'size': 50, 'sort': 'endorsements'},
    );
    final list = (page['content'] as List).cast<Map<String, dynamic>>();
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
    final page = await api.get('posts', query: {'size': 50});
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
    final daily = (await api.get('map/pins', query: {'layer': 'daily'}) as List)
        .cast<Map<String, dynamic>>();
    normalPins = daily.map(Api2App.pin).toList();
    final em = (await api.get(
      'map/pins',
      query: {'layer': 'emergency'},
    ) as List).cast<Map<String, dynamic>>();
    emergencyPins = em.map(Api2App.pin).toList();
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
    sangre = (m['bloodType'] as String?) ?? sangre;
    alergias = (m['allergies'] as String?) ?? '';
    condiciones = (m['conditions'] as String?) ?? '';
    vive = ((m['livesWith'] as List?) ?? const [])
        .map((v) => Api2App.livesWith[v])
        .whereType<String>()
        .toList();
  });

  /// Recarga lo que muestra cada pantalla al entrar a ella.
  void _onEnter(String name) {
    if (!connected) return;
    switch (name) {
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
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _poll());
    _chatTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (screen == 'chat') _pollChat();
      if (screen == 'sos-sent') _pollSos();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _chatTimer?.cancel();
    _pollTimer = null;
    _chatTimer = null;
  }

  Future<void> _poll() async {
    if (!connected || offline) return;
    await _loadMe();
    await _checkNearbySos();
    if (emergency) await _loadReports();
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
      final ref =
          await api.post('posts/${post.id}/responses') as Map<String, dynamic>;
      openChat(post.user, conversationId: ref['conversationId'] as String?);
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
      for (final m in list) {
        final id = m['id'] as String?;
        if (id != null && !_seenMsgIds.add(id) && !replace) continue;
        box.add(
          ChatMessage(
            from: m['system'] == true
                ? 'sys'
                : (m['senderId'] == userId ? 'me' : 'them'),
            text: (m['text'] as String?) ?? '',
            time: Api2App.clock(m['createdAt']),
          ),
        );
        _lastMsgAt[conversationId] = m['createdAt'] as String?;
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
      _outbox.add({
        'kind': 'MESSAGE',
        'payload': {
          'conversationId': convId,
          'clientId': clientId,
          'text': text,
        },
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

  Future<void> _publishRemote({
    required String? type,
    required String? catId,
    required String text,
    String? where,
    String? prio,
  }) async {
    final clientId = newClientId();
    try {
      switch (type) {
        case 'need':
        case 'offer':
          {
            final payload = {
              'clientId': clientId,
              'type': type == 'need' ? 'NEED' : 'OFFER',
              'category':
                  Api2App.reverse(Api2App.postCat, catId) ?? 'TEMPORARY_HELP',
              if (text.isNotEmpty) 'text': text,
            };
            if (offline) {
              _outbox.add({'kind': 'POST', 'payload': payload});
            } else {
              await api.post('posts', body: payload);
              await _loadPosts();
            }
          }
        case 'vulnerable':
          {
            final pos = await location.current();
            final payload = {
              'clientId': clientId,
              'category': Api2App.reverse(Api2App.vulnCat, catId) ?? 'INJURED',
              'priority': prio == 'media' ? 'MEDIUM' : 'HIGH',
              if (text.isNotEmpty) 'detail': text,
              'addressText': ?where,
              'lat': pos.lat,
              'lng': pos.lng,
            };
            if (offline) {
              _outbox.add({'kind': 'VULNERABLE_REPORT', 'payload': payload});
            } else {
              await api.post('vulnerable-reports', body: payload);
              await _loadReports();
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
            await _loadResources();
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
              },
            );
            await _loadServices();
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

  /// Al volver la conexión: envía la cola en orden (POST /sync/outbox).
  Future<void> _flushOutbox() async {
    if (!connected) return;
    if (_outbox.isNotEmpty) {
      final items = List<Map<String, Object?>>.from(_outbox);
      _outbox.clear();
      try {
        final results = await api.post('sync/outbox', body: items) as List;
        final errors = results
            .where((r) => r is Map && r['status'] == 'ERROR')
            .length;
        if (errors > 0) {
          toast('$errors envío(s) no se pudieron sincronizar', icon: 'error');
        }
      } on ApiException catch (_) {
        _outbox.insertAll(0, items);
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
  }

  // ================================================================ SOS

  static const _sosTypes = {
    'salud': 'HEALTH',
    'fuego': 'FIRE',
    'robo': 'ROBBERY',
    'sismo': 'EARTHQUAKE',
    'violencia': 'VIOLENCE',
    'otro': 'OTHER',
  };

  /// Envía el SOS (al terminar la cuenta regresiva).
  Future<void> sendSos() async {
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
      _outbox.add({'kind': 'SOS', 'payload': payload});
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
        _outbox.add({'kind': 'SOS', 'payload': payload});
        toast(
          'Sin internet: tu alerta se envía apenas vuelva la señal',
          icon: 'cloud_off',
        );
      } else {
        toast(e.message, icon: 'error');
      }
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
      _outbox.add({
        'kind': 'CHECK_IN',
        'payload': {'status': status},
      });
      return null;
    }
    try {
      final r = await api.post(
        'check-ins',
        body: {'status': status},
      ) as Map<String, dynamic>;
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
          if (decoded['lat'] != null) 'lat': decoded['lat'],
          if (decoded['lng'] != null) 'lng': decoded['lng'],
        },
      );
      await _loadReports();
      refresh();
    } on ApiException catch (e) {
      toast(e.message, icon: 'error');
    }
  }
}
