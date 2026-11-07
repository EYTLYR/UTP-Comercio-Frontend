import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../api/mappers.dart';
import '../models/models.dart';
import '../services/location_service.dart';
import '../services/device_actions.dart';
import '../services/internet_call.dart';
import '../services/speech_input.dart';
import '../services/startup_permissions.dart';

part 'app_state_backend.dart';

class PublishDraft {
  int step;
  String? type;
  String? cat;
  String text;
  bool photo;
  Map<String, dynamic>? ai;

  PublishDraft({
    this.step = 1,
    this.type,
    this.cat,
    this.text = '',
    this.photo = false,
    this.ai,
  });

  void reset({
    int step = 1,
    String? type,
    String? cat,
    String text = '',
    bool photo = false,
  }) {
    this.step = step;
    this.type = type;
    this.cat = cat;
    this.text = text;
    this.photo = photo;
    ai = null;
  }
}

class AppState extends ChangeNotifier {
  final deviceActions = DeviceActions();
  late final internetCall = InternetCall(api: api);
  bool callLaunching = false;
  String? otpDevCode;
  int otpResendSeconds = 30;
  bool networkMaps = true;
  bool _disposed = false;
  int toastId = 0;
  static const toastDuration = Duration(milliseconds: 2800);
  void dismissToast() {
    _toastTimer?.cancel();
    toastMessage = null;
    toastIcon = null;
    notifyListeners();
  }

  final List<Timer> _timers = [];
  final SpeechInput voice;
  final StartupPermissions? permissions;

  /// Nearby API. Sin sesión (pruebas, demo) la app usa los datos de ejemplo.
  final ApiClient api;
  final LocationService location;
  final Map<String, GlobalKey> tourTargets = {};
  GlobalKey tourTarget(String name) =>
      tourTargets.putIfAbsent(name, () => GlobalKey(debugLabel: name));
  Timer? _tourTimer;
  Map<String, bool>? _tourVbBefore;
  ({
    bool emergency,
    bool offline,
    String category,
    String service,
    PublishDraft draft,
  })?
  _tourBefore;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void refresh() => notifyListeners();

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _chatTimer?.cancel();
    voice.dispose();
    internetCall.removeListener(refresh);
    internetCall.dispose();
    _tourTimer?.cancel();
    _toastTimer?.cancel();
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  // Backend (ver app_state_backend.dart)
  /// true en la app real (main llama a bootstrap); false en pruebas y demo.
  bool useApi = false;
  bool connected = false;
  bool busy = false;
  bool regPending = false;
  String? userId;
  String role = 'NEIGHBOR';
  String? zoneId;
  String zoneName = 'Zona 3 · Las Flores';
  String effectiveMode = 'NORMAL';
  double? regLat;
  double? regLng;
  Map<String, dynamic>? sosResult;
  Map<String, dynamic>? sosDetail;
  Map<String, dynamic>? incomingSos;
  final Map<String, String> convIds = {};
  final Map<String, List<ReviewItem>> reviews = {};
  final Map<String, String> contactDigits = {};
  Map<String, int> _vbBase = {};
  List<HistoryItem>? remoteInventory;
  List<HistoryItem> myLearnings = [];
  final List<Map<String, Object?>> _outbox = [];
  final List<Future<void> Function()> _pendingCalls = [];
  final Set<String> _seenSos = {};
  final Set<String> _seenMsgIds = {};
  final Map<String, String?> _lastMsgAt = {};
  Timer? _pollTimer;
  Timer? _chatTimer;

  /// Brigada, delegado o Municipalidad. Sin sesión (demo) se muestra todo.
  bool get isBrigade =>
      !connected || const {'BRIGADIST', 'DELEGATE', 'ADMIN'}.contains(role);

  /// Reseñas del oficio (del backend; de ejemplo sin sesión).
  List<ReviewItem> reviewsFor(String serviceId) =>
      connected ? (reviews[serviceId] ?? const []) : kReviews;

  // Navigation
  String screen = 'home';
  List<String> hist = [];

  // Toggles
  bool offline = false;
  bool emergency = false;
  bool lg = false;
  bool hc = false;
  bool dark = false;

  // Emergency origin
  bool zoneEm = false;
  String emSource = 'zona'; // 'zona' or 'yo'
  bool seenEmTour = false;
  bool emNotify = true;

  // User
  String userName = 'María Quispe';
  String userPhone = '987654321';
  String phoneDraft = '';
  String regName = '';
  String? regLoc; // null, 'loading', 'ok'
  String regAddress = 'Detectando ubicación…';
  Map<String, bool> perms = {
    'loc': false,
    'notif': false,
    'sms': false,
    'ai': false,
  };

  // Contacts
  List<String> contacts = ['mama', 'carlos', 'rosa'];
  String contactsMode = 'manage'; // 'setup' or 'manage'

  // Ficha
  String sangre = 'O+';
  String alergias = 'Penicilina';
  String condiciones = '';
  List<String> vive = ['mayor'];

  // Selections & filters
  String servCat = 'all';
  String selService = 'julio';
  String muroSeg = 'all';
  String? muroCat;
  String mapFilter = 'all';
  String? mapSel;
  String resSel = 'agua';
  String tabFilter = 'all';
  String redFilter = 'all';

  // Publish
  PublishDraft pub = PublishDraft();

  // Stats / Counters
  int pending = 0;
  String? sosType;
  Map<String, bool> vbGiven = {};
  Map<String, bool> helped = {};
  Map<dynamic, bool> going = {};
  bool checkin = false;
  Map<String, bool> joined = {};

  // Chat & Call
  String? chatWith;
  Map<String, dynamic>? callWith;
  Map<String, dynamic>? routeTo;
  bool muted = false;
  bool speaker = false;
  Map<String, List<ChatMessage>> chats = {};

  // IA Nearby · Protocolo Lázaro
  bool aiConsent = true;
  Map<String, bool> aiRemoved = {};
  String aiStatus = 'idle'; // 'idle', 'running', 'done'
  int aiStep = 0;
  double aiMs = 0;
  Map<dynamic, List<HistoryItem>> aiMissions = {};
  Map<dynamic, bool> aiNotified = {};
  String? lastCode;
  bool decoded = false;

  // Sheets
  Map<String, dynamic>? sheet;

  // Toast
  String? toastMessage;
  String? toastIcon;
  Timer? _toastTimer;

  // Dynamic Lists
  late List<ServiceItem> services;
  late List<PostItem> posts;
  late List<ReportItem> reports;
  late List<ResOfferItem> resOffers;
  List<ResourceItem> resources = List.of(kResources);
  List<GroupItem> groups = List.of(kGroups);
  List<MapPin> normalPins = List.of(kNormalPins);
  List<MapPin> emergencyPins = List.of(kEmergencyPins);
  List<ContactItem> contactBook = List.of(kAllContacts);

  // Interactive Tour
  String? tourName;
  int tourIndex = 0;
  bool tourBusy = false;

  AppState({
    SpeechInput? voice,
    this.permissions,
    ApiClient? api,
    LocationService? location,
  }) : voice = voice ?? DeviceSpeechInput(),
       api = api ?? ApiClient(),
       location = location ?? LocationService() {
    internetCall.addListener(refresh);
    services = kInitialServices
        .map(
          (s) => ServiceItem(
            id: s.id,
            name: s.name,
            job: s.job,
            cat: s.cat,
            icon: s.icon,
            tone: s.tone,
            vb: s.vb,
            dist: s.dist,
            price: s.price,
            hours: s.hours,
            emerg: s.emerg,
          ),
        )
        .toList();
    posts = List.from(kInitialPosts);
    reports = kInitialReports
        .map(
          (r) => ReportItem(
            id: r.id,
            cat: r.cat,
            who: r.who,
            where: r.where,
            detail: r.detail,
            prio: r.prio,
            status: r.status,
            by: r.by,
            time: r.time,
            x: r.x,
            y: r.y,
            ai: r.ai,
          ),
        )
        .toList();
    resOffers = List.from(kInitialResOffers);
  }

  String get firstName => userName.split(' ').first;

  String get initials {
    final clean = userName.replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚÑáéíóúñ ]'), '');
    final parts = clean.split(' ').where((w) => w.isNotEmpty).take(2).toList();
    if (parts.isEmpty) return 'MQ';
    return parts.map((w) => w[0]).join().toUpperCase();
  }

  void toast(String msg, {String icon = 'check_circle'}) {
    if (_disposed) return;
    toastId++;
    toastMessage = msg;
    toastIcon = icon;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(toastDuration, () {
      toastMessage = null;
      toastIcon = null;
      notifyListeners();
    });
  }

  void go(String name, {bool reset = false}) {
    if (screen == 'llamada' && name != 'llamada' && internetCall.active) {
      unawaited(internetCall.end());
    }
    _toastTimer?.cancel();
    toastMessage = null;
    toastIcon = null;
    if (!isBrigade && const {'tablero', 'red', 'puente'}.contains(name)) {
      toast('Esta vista es solo para la brigada de tu zona', icon: 'lock');
      return;
    }
    if (reset) {
      hist.clear();
    } else if (screen != name) {
      hist.add(screen);
    }
    screen = name;
    sheet = null;
    notifyListeners();
    checkTourEvent('screen:$name');
    _onEnter(name);
  }

  void back() {
    if (screen == 'llamada' && internetCall.active) {
      unawaited(internetCall.end());
    }
    if (hist.isNotEmpty) {
      screen = hist.removeLast();
    } else {
      screen = 'home';
    }
    sheet = null;
    notifyListeners();
    checkTourEvent('screen:$screen');
  }

  void selectTab(String tabId) {
    if (tabId == 'publicar') {
      pub.reset();
    }
    go(tabId, reset: true);
  }

  // --- Theme toggles ---
  void toggleOffline() {
    final wasOffline = offline;
    offline = !offline;
    if (wasOffline && pending > 0) {
      toast(
        'Conexión recuperada · $pending envío(s) sincronizado(s)',
        icon: 'cloud_done',
      );
      pending = 0;
      _flushOutbox();
    } else if (wasOffline) {
      _flushOutbox();
    } else if (offline) {
      toast('Sin conexión: la app sigue funcionando', icon: 'cloud_off');
    }
    notifyListeners();
  }

  void activateEmergencyFromProfile() {
    if (emergency) return;
    emergency = true;
    emSource = zoneEm ? 'zona' : 'yo';
    sheet = null;
    notifyListeners();
    toast('Modo emergencia activado', icon: 'crisis_alert');
    if (tourName == null) _syncEmergency(true, emSource);
  }

  void toggleEmergency() {
    final previousSource = emSource;
    emergency = !emergency;
    zoneEm = emergency;
    emSource = 'zona';
    sheet = null;
    mapFilter = 'all';
    mapSel = null;
    if (!emergency && ['tablero', 'recursos', 'apoyo'].contains(screen)) {
      hist.clear();
      screen = 'home';
    }
    if (screen == 'publicar') {
      pub.reset();
    }
    notifyListeners();
    toast(
      emergency ? 'Modo emergencia activado' : 'Volviste al modo normal',
      icon: emergency ? 'crisis_alert' : 'verified_user',
    );
    if (tourName == null) {
      _syncEmergency(emergency, emergency ? 'yo' : previousSource);
    }
  }

  /// "Activar modo emergencia" solo en mi app (después de un SOS).
  void activateLocalEmergency() {
    emergency = true;
    emSource = 'yo';
    notifyListeners();
    _syncEmergency(true, 'yo');
  }

  void toggleDark() {
    dark = !dark;
    notifyListeners();
  }

  void toggleLg() {
    lg = !lg;
    notifyListeners();
  }

  void toggleHc() {
    hc = !hc;
    notifyListeners();
  }

  // --- Sheet management ---
  void openSheet(String type, {dynamic id}) {
    sheet = {'type': type, 'id': id};
    notifyListeners();
    checkTourEvent('sheet:$type');
  }

  void closeSheet() {
    sheet = null;
    notifyListeners();
  }

  // --- Visto Bueno ---
  void toggleVb(String serviceId) {
    vbGiven[serviceId] = !(vbGiven[serviceId] ?? false);
    notifyListeners();
    if (vbGiven[serviceId] == true) {
      toast('Diste tu Visto Bueno Vecinal', icon: 'verified');
    }
    checkTourEvent('vb');
    if (tourName == null) _syncVb(serviceId);
  }

  // --- Help post ---
  void helpPost(String postId) {
    final post = posts.firstWhere((p) => p.id == postId);
    final first = !(helped[postId] ?? false);
    helped[postId] = true;
    if (connected) {
      _respondPost(post);
      return;
    }
    openChat(
      post.user,
      sysMsg: first
          ? (post.type == 'need'
                ? 'Le ofreciste ayuda: «${post.title}»'
                : 'Te interesa: «${post.title}»')
          : null,
    );
  }

  // --- Chat ---
  void openChat(String userName, {String? sysMsg, String? conversationId}) {
    if (!chats.containsKey(userName)) {
      chats[userName] = [];
    }
    if (conversationId != null) {
      convIds[userName] = conversationId;
      _loadMessages(userName, conversationId, replace: true);
    }
    if (sysMsg != null) {
      chats[userName]!.add(
        ChatMessage(from: 'sys', text: sysMsg, time: _nowTime()),
      );
    }
    chatWith = userName;
    go('chat');
  }

  void sendChat(String text) {
    final t = text.trim();
    if (t.isEmpty || chatWith == null) return;
    chats[chatWith]!.add(
      ChatMessage(from: 'me', text: t, time: _nowTime(), pending: offline),
    );
    notifyListeners();

    if (connected) {
      // Con sesión las respuestas son reales (llegan por el sondeo del chat).
      _sendChatRemote(chatWith!, t);
      return;
    }
    if (!offline) {
      final target = chatWith!;
      _timers.add(
        Timer(const Duration(milliseconds: 1400), () {
          const replies = [
            '¡Gracias! ¿Te queda bien en 15 minutos?',
            'Perfecto, te espero en la puerta.',
            'Dale, nos vemos. ¡Gracias por la ayuda!',
            'Listo, te escribo cuando esté en camino.',
          ];
          final reply =
              replies[(DateTime.now().millisecondsSinceEpoch ~/ 100) %
                  replies.length];
          chats[target]?.add(
            ChatMessage(from: 'them', text: reply, time: _nowTime()),
          );
          notifyListeners();
        }),
      );
    }
  }

  // --- Call ---
  void startCall(String target) {
    if (internetCall.active) {
      go('llamada');
      return;
    }
    internetCall.resetSelection();
    final c = kCalls.where((x) => x.num == target).firstOrNull;
    if (c != null) {
      callWith = {
        'name': '${c.label} · ${c.num}',
        'icon': c.icon,
        'emergency': true,
      };
    } else {
      callWith = {'name': target, 'icon': Icons.person, 'emergency': false};
    }
    muted = false;
    speaker = false;
    callWith!['number'] =
        contactBook
            .where((contact) => contact.name == target)
            .firstOrNull
            ?.phone ??
        target;
    go('llamada');
  }

  Future<void> launchCurrentCall({bool dialOnly = false}) async {
    if (callLaunching) return;
    final number = (callWith?['number'] as String? ?? '').replaceAll(
      RegExp(r'[\s()\-]'),
      '',
    );
    if (!RegExp(r'^\+?[0-9]{3,15}$').hasMatch(number)) {
      toast('Este contacto todavía no tiene un número registrado');
      return;
    }
    callLaunching = true;
    refresh();
    try {
      final opened = await deviceActions.call(
        number,
        emergency: callWith?['emergency'] == true,
        dialOnly: dialOnly,
      );
      if (!opened && !_disposed) {
        toast('No se pudo abrir el teléfono. Marca $number manualmente');
      }
    } finally {
      callLaunching = false;
      refresh();
    }
  }

  Future<void> startInternetCall() async {
    if (!connected || offline) {
      toast(
        'Inicia sesión y conéctate a internet para llamar dentro de Nearby',
      );
      return;
    }
    final target = callWith?['name'] as String? ?? '';
    var conversation = convIds[target];
    try {
      if (conversation == null) {
        final service = services.where((s) => s.name == target).firstOrNull;
        if (service != null) {
          final ref = await api.post('services/${service.id}/contact') as Map;
          conversation = ref['conversationId'] as String?;
          if (conversation != null) convIds[target] = conversation;
        }
      }
      if (conversation == null) {
        toast(
          'Abre primero una conversación con este vecino para llamarlo por internet',
        );
        return;
      }
      await internetCall.start(conversation);
    } on ApiException catch (error) {
      toast(error.message, icon: 'error');
    }
  }

  // --- Publishing ---
  void finishPublish() {
    if (tourName == 'main') {
      pub.step = 3;
      notifyListeners();
      checkTourEvent('publish');
      return;
    }
    final type = pub.type;
    final catId = pub.cat;
    final text = pub.text;
    final cat = _findCat(type, catId);

    if (offline) pending++;
    if (connected) {
      _publishRemote(
        type: type,
        catId: catId,
        text: text,
        where: pub.ai?['loc'] as String?,
        prio: pub.ai?['prio'] as String?,
      );
    }

    if (type == 'need' || type == 'offer') {
      posts.insert(
        0,
        PostItem(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          type: type!,
          cat: catId!,
          title: text.isNotEmpty
              ? text
              : (type == 'need' ? 'Necesito: ' : 'Ofrezco: ') +
                    (cat?.label.toLowerCase() ?? ''),
          user: userName,
          dist: 'aquí',
          time: 'ahora',
        ),
      );
    } else if (type == 'vulnerable') {
      final where = (pub.ai?['loc'] as String?) ?? 'Jr. Las Flores 245';
      final prio = (pub.ai?['prio'] as String?) ?? 'alta';
      reports.insert(
        0,
        ReportItem(
          id: DateTime.now().millisecondsSinceEpoch,
          cat: catId ?? 'herido',
          who: cat?.label ?? 'Vecino vulnerable',
          where: where,
          detail: text.isNotEmpty ? text : 'Reportado por $firstName',
          prio: prio,
          status: 'p',
          time: _nowTime(),
          x: 50,
          y: 50,
        ),
      );
      lastCode = compressSOS(cat: catId ?? 'herido', loc: where, prio: prio);
    } else if (type == 'needres' || type == 'offerres') {
      resOffers.insert(
        0,
        ResOfferItem(
          res: catId ?? resSel,
          type: type == 'needres' ? 'need' : 'offer',
          title: text.isNotEmpty ? text : (cat?.label ?? 'Recurso'),
          user: userName,
          where: 'Jr. Las Flores 245',
        ),
      );
      if (catId != null) resSel = catId;
    } else if (type == 'service') {
      if (!services.any((s) => s.id == 'yo')) {
        services.add(
          ServiceItem(
            id: 'yo',
            name: userName,
            job: cat?.label ?? 'Oficio',
            cat: catId ?? 'gasfiteria',
            icon: cat?.icon ?? Icons.handyman,
            tone: 'green',
            vb: 0,
            dist: 'tú',
            price: 'A convenir',
            hours: 'Por coordinar',
          ),
        );
      }
    }

    pub.step = 3;
    notifyListeners();
    checkTourEvent('publish');
  }

  CategoryItem? _findCat(String? type, String? catId) {
    if (type == 'need' || type == 'offer') {
      return kPostCats.where((c) => c.id == catId).firstOrNull;
    } else if (type == 'service') {
      return kServCats.where((c) => c.id == catId).firstOrNull;
    } else if (type == 'vulnerable') {
      return kVulnCats.where((c) => c.id == catId).firstOrNull;
    } else {
      final r = kResources.where((c) => c.id == catId).firstOrNull;
      if (r != null) {
        return CategoryItem(id: r.id, label: r.label, icon: r.icon);
      }
    }
    return null;
  }

  // --- AI Lazarus Protocol ---
  List<HistoryItem> buildInventory() {
    final remote = remoteInventory;
    if (connected && remote != null) {
      final out = <HistoryItem>[];
      for (final h in remote) {
        if (h.who == userName && !aiConsent) continue;
        if (aiRemoved['${h.id}${h.tag}'] ?? false) continue;
        out.add(h);
      }
      for (final h in myLearnings) {
        if (!aiConsent || (aiRemoved['${h.id}${h.tag}'] ?? false)) continue;
        if (!out.any((e) => e.id == h.id)) out.add(h);
      }
      return out;
    }
    final out = <HistoryItem>[];
    for (final h in kHistory) {
      if (h.who == '@me' && !aiConsent) continue;
      final who = h.who == '@me' ? userName : h.who;
      final t = h.txt.toLowerCase();
      kAiTags.forEach((k, tag) {
        if (tag.kw.any((w) => t.contains(w)) &&
            !(aiRemoved['${h.id}$k'] ?? false)) {
          out.add(h.copyWith(who: who, tag: k));
        }
      });
    }
    return out;
  }

  List<HistoryItem> assignMission(ReportItem r) {
    final inv = buildInventory()
        .where((e) => kAiTags[e.tag]?.kind != 'vuln')
        .toList();
    final used = <String>{};
    final out = <HistoryItem>[];
    final needs = kMissionNeeds[r.cat] ?? ['paramedico'];

    for (final need in needs) {
      final candidates = inv
          .where((e) => e.tag == need && !used.contains(e.who))
          .map((e) {
            return e.copyWith(dist: distM(e.x, e.y, r.x, r.y));
          })
          .toList();
      candidates.sort(
        (a, b) =>
            distM(a.x, a.y, r.x, r.y).compareTo(distM(b.x, b.y, r.x, r.y)),
      );
      if (candidates.isNotEmpty) {
        final c = candidates.first;
        used.add(c.who);
        out.add(c);
      }
    }
    return out;
  }

  List<ReportItem> preventiveReports() {
    final vul = buildInventory()
        .where((e) => kAiTags[e.tag]?.kind == 'vuln' && e.who != userName)
        .toList();
    final seen = <String>{};
    final out = <ReportItem>[];
    for (final e in vul) {
      if (seen.contains(e.id) ||
          reports.any((r) => distM(r.x, r.y, e.x, e.y) < 60)) {
        continue;
      }
      seen.add(e.id);
      final cat = e.tag == 'oxigeno'
          ? 'oxigeno'
          : (e.tag == 'mayor' ? 'mayor' : 'disc');
      final who = cat == 'oxigeno'
          ? 'Paciente con oxígeno sin luz'
          : (cat == 'mayor'
                ? 'Adulta mayor que no camina sola'
                : 'Persona con movilidad reducida');
      final where = e.zona + (cat == 'oxigeno' ? ' lote 1' : ' lote 7');
      final detail =
          'Nadie lo ha reportado. La IA lo sabe por el ${e.src.toLowerCase()} (${e.when}): «${e.txt}».${cat == 'oxigeno' ? ' Con el corte de luz, su equipo puede apagarse.' : ''}';

      out.add(
        ReportItem(
          id: 'ai-${e.id}',
          ai: true,
          cat: cat,
          x: e.x,
          y: e.y,
          prio: 'alta',
          status: 'p',
          time: 'IA',
          who: who,
          where: where,
          detail: detail,
        ),
      );
    }
    return out;
  }

  void runAi() {
    if (aiStatus == 'running') return;
    aiStatus = 'running';
    aiStep = 0;
    openSheet('ai-run');
    notifyListeners();

    _timers.add(
      Timer.periodic(const Duration(milliseconds: 460), (timer) {
        aiStep++;
        if (aiStep < 5) {
          notifyListeners();
        } else {
          timer.cancel();
          if (connected) {
            _runAiRemote().then((ok) {
              aiStatus = ok ? 'done' : 'idle';
              aiStep = 0;
              sheet = null;
              tabFilter = 'all';
              notifyListeners();
              if (ok) {
                final total = aiMissions.values.fold(
                  0,
                  (sum, m) => sum + m.length,
                );
                toast(
                  'Plan de rescate listo: $total vecinos asignados',
                  icon: 'auto_awesome',
                );
              }
            });
            return;
          }
          final sw = Stopwatch()..start();
          final prev = preventiveReports().reversed.toList();
          for (final r in prev) {
            if (!reports.any((existing) => existing.id == r.id)) {
              reports.insert(0, r);
            }
          }
          aiMissions.clear();
          for (final r in reports.where((x) => x.status != 'a')) {
            aiMissions[r.id] = assignMission(r);
          }
          sw.stop();
          aiStatus = 'done';
          aiStep = 0;
          aiMs = (sw.elapsedMicroseconds / 1000.0);
          if (aiMs < 0.1) aiMs = 0.8;
          sheet = null;
          tabFilter = 'all';
          notifyListeners();
          final totalAssigned = aiMissions.values.fold(
            0,
            (sum, m) => sum + m.length,
          );
          toast(
            'Plan de rescate listo: $totalAssigned vecinos asignados',
            icon: 'auto_awesome',
          );
        }
      }),
    );
  }

  void notifyAiMission(dynamic reportId) {
    aiNotified[reportId] = true;
    if (connected) _notifyMissionRemote(reportId);
    final r = reports.where((x) => x.id == reportId).firstOrNull;
    final m = aiMissions[reportId] ?? [];
    if (r != null && r.status == 'p') {
      r.status = 'c';
      r.by = m.map((a) => a.who.split(' ').first).join(' y ');
    }
    notifyListeners();
    final names = m.map((a) => a.who.split(' ').first).join(' y ');
    toast(
      offline
          ? 'Sin internet: avisamos por SMS a los vecinos'
          : 'Avisamos a $names',
      icon: 'notifications_active',
    );
  }

  // --- Voice AI classifier ---
  Map<String, dynamic> classify(String text) {
    final t = text.toLowerCase();
    bool has(List<String> words) => words.any((w) => t.contains(w));

    String? type;
    String? cat;
    String prio = 'media';
    String? loc;
    final chips = <List<String>>[];

    // Loc detection
    final m = RegExp(r'(los pinos|las flores|las rosas|principal)\s*(\d{1,4})')
        .firstMatch(t);
    final mz = RegExp(
      r'manzana\s*([a-z])\s*lote\s*(\d+)|mz\.?\s*([a-z])\s*(?:lote|lt\.?)\s*(\d+)',
    ).firstMatch(t);

    if (m != null) {
      final name = {
        'los pinos': 'Jr. Los Pinos',
        'las flores': 'Jr. Las Flores',
        'las rosas': 'Pje. Las Rosas',
        'principal': 'Av. Principal',
      }[m.group(1)]!;
      loc = '$name ${m.group(2)}';
    } else if (mz != null) {
      final ltr = (mz.group(1) ?? mz.group(3))!.toUpperCase();
      final num = mz.group(2) ?? mz.group(4);
      loc = 'Mz. $ltr lote $num';
    }

    if (emergency) {
      if (has([
            'agua',
            'comida',
            'víveres',
            'viveres',
            'medicina',
            'carga',
            'refugio',
            'transporte',
          ]) &&
          !has(['herid', 'atrapad', 'sangr'])) {
        type = has(['tengo', 'ofrezco', 'regalo', 'comparto', 'presto'])
            ? 'offerres'
            : 'needres';
        cat = has(['agua'])
            ? 'agua'
            : (has(['comida', 'víveres', 'viveres'])
                  ? 'viveres'
                  : (has(['medicina'])
                        ? 'medicinas'
                        : (has(['carga'])
                              ? 'energia'
                              : (has(['refugio'])
                                    ? 'refugio'
                                    : 'transporte'))));
      } else {
        type = 'vulnerable';
        cat = has(['herid', 'sangr', 'fractur', 'golpe'])
            ? 'herido'
            : (has(['atrapad', 'se cayó', 'se cayo', 'escombro', 'derrumb'])
                  ? 'atrapado'
                  : (has(['oxígeno', 'oxigeno'])
                        ? 'oxigeno'
                        : (has(['abuel', 'adulto mayor', 'anciano'])
                              ? 'mayor'
                              : (has(['niño', 'niña', 'niños', 'bebé'])
                                    ? 'ninos'
                                    : (has(['embarazada', 'gestante'])
                                          ? 'gestante'
                                          : (has([
                                                  'silla de ruedas',
                                                  'discapacidad',
                                                ])
                                                ? 'disc'
                                                : null))))));
      }
      if (has([
        'herid',
        'sangr',
        'atrapad',
        'no respira',
        'inconsciente',
        'fuego',
        'incendio',
        'se cayó',
        'derrumb',
      ])) {
        prio = 'alta';
      }
    } else {
      type =
          has([
            'presto',
            'ofrezco',
            'regalo',
            'tengo',
            'enseño',
            'puedo',
            'dono',
          ])
          ? 'offer'
          : 'need';
      cat = has(['escalera', 'taladro', 'herramienta', 'martillo', 'alicate'])
          ? 'herramientas'
          : (has(['acompañ', 'cuidar', 'cuida', 'ayudar a mover'])
                ? 'temporal'
                : (has(['ladrillo', 'cemento', 'madera', 'material', 'pintura'])
                      ? 'materiales'
                      : (has(['enseñ', 'clase', 'aprender', 'tarea'])
                            ? 'habilidades'
                            : (has([
                                    'llevar',
                                    'lleven',
                                    'auto',
                                    'asiento',
                                    'movilidad',
                                    'mercado',
                                    'cita',
                                  ])
                                  ? 'movilidad'
                                  : null))));
    }

    final catObj = _findCat(type, cat);
    if (catObj != null) {
      chips.add(['category', 'Categoría: ${catObj.label}']);
    }
    if (emergency && type == 'vulnerable') {
      chips.add([
        'priority_high',
        'Prioridad ${prio == 'alta' ? 'alta' : 'media'}',
      ]);
    }
    if (loc != null) {
      chips.add(['location_on', loc]);
    }
    if (emergency && cat != null) {
      chips.add(['hub', 'Cruzando con Brigada Z3']);
    }

    return {
      'type': type,
      'cat': cat,
      'prio': prio,
      'loc': loc,
      'chips': chips,
      'label': chips.map((c) => c[1]).join(' · '),
    };
  }

  // --- Interactive Tour ---
  void startTour(String name) {
    _tourTimer?.cancel();
    if (tourName != null) endTour();
    _tourVbBefore = Map.of(vbGiven);
    _tourBefore = (
      emergency: emergency,
      offline: offline,
      category: servCat,
      service: selService,
      draft: PublishDraft(
        step: pub.step,
        type: pub.type,
        cat: pub.cat,
        text: pub.text,
        photo: pub.photo,
        ai: pub.ai == null ? null : Map.of(pub.ai!),
      ),
    );
    sheet = null;
    screen = 'home';
    hist.clear();
    pub.reset();
    servCat = 'all';
    emergency = name == 'em';
    offline = false;
    tourName = name;
    tourIndex = 0;
    tourBusy = false;
    notifyListeners();
  }

  void nextTourStep() {
    if (tourName == null) return;
    _tourTimer?.cancel();
    tourBusy = false;
    tourIndex++;
    if (tourIndex >= (tourName == 'main' ? 17 : 5)) {
      endTour(true);
      return;
    }
    notifyListeners();
  }

  void endTour([bool completed = false]) {
    final name = tourName;
    _tourTimer?.cancel();
    tourName = null;
    tourIndex = 0;
    tourBusy = false;
    if (_tourVbBefore != null) vbGiven = _tourVbBefore!;
    _tourVbBefore = null;
    final before = _tourBefore;
    _tourBefore = null;
    if (before != null) {
      emergency = before.emergency;
      offline = before.offline;
      servCat = before.category;
      selService = before.service;
      pub = before.draft;
    }
    sheet = null;
    if (name == 'em') seenEmTour = true;
    screen = 'home';
    hist.clear();
    notifyListeners();
    if (completed && name == 'main') {
      toast('Tutorial completado. ¡Bien hecho!', icon: 'celebration');
    }
  }

  void checkTourEvent(String event) {
    if (tourName == null || tourBusy) return;
    const events = {
      1: 'sos-hold',
      3: 'screen:servicios',
      4: 'servcat',
      5: 'screen:svc',
      7: 'vb',
      8: 'screen:servicios',
      9: 'screen:publicar',
      10: 'ptype',
      11: 'pcat',
      12: 'publish',
      13: 'screen:home',
    };
    final matches = tourName == 'main'
        ? events[tourIndex] == event
        : tourIndex == 3 && event == 'sheet:em';
    if (!matches) return;
    final name = tourName;
    final index = tourIndex;
    tourBusy = true;
    _tourTimer = Timer(const Duration(milliseconds: 320), () {
      if (tourName == name && tourIndex == index) nextTourStep();
    });
  }

  String nowTime() => _nowTime();

  String _nowTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  void addReportFromPuente(Map<String, dynamic> d, {String? code}) {
    if (connected && code != null) {
      _reportFromSmsRemote(code, d);
      toast('Reporte agregado al tablero del barrio', icon: 'add_location');
      return;
    }
    final catEntry = kTypeCode.entries.firstWhere(
      (e) => kTypeName[e.value] == d['type'],
      orElse: () => const MapEntry('herido', 'H'),
    );
    final posMap = {
      'Jr. Los Pinos': [66.0, 62.0],
      'Jr. Las Flores': [50.0, 50.0],
      'Pje. Las Rosas': [40.0, 72.0],
      'Av. Principal': [60.0, 36.0],
    };
    List<double> pos = [48.0, 40.0];
    for (final street in kStreets.values) {
      if ((d['where'] as String).startsWith(street)) {
        pos = posMap[street] ?? [48.0, 40.0];
        break;
      }
    }
    final int injured = d['injured'] is int ? d['injured'] as int : 1;
    reports.insert(
      0,
      ReportItem(
        id: DateTime.now().millisecondsSinceEpoch,
        cat: kVulnCats.any((x) => x.id == catEntry.key)
            ? catEntry.key
            : 'herido',
        who: '${d['type']}${injured > 1 ? " ($injured)" : ""}',
        where: d['where'] ?? '',
        detail: 'Recibido por SMS sin internet y descomprimido en el teléfono del brigadista.',
        prio: d['prio'] == 'Alta' ? 'alta' : 'media',
        status: 'p',
        time: nowTime(),
        x: pos[0],
        y: pos[1],
      ),
    );
    emergency = true;
    zoneEm = true;
    notifyListeners();
    toast('Reporte agregado al tablero del barrio', icon: 'add_location');
  }
}
