import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';

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
  final List<Timer> _timers = [];

  void refresh() => notifyListeners();

  @override
  void dispose() {
    _toastTimer?.cancel();
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

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
  Map<int, bool> helped = {};
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

  // Interactive Tour
  String? tourName;
  int tourIndex = 0;
  bool tourBusy = false;

  AppState() {
    services = List.from(kInitialServices);
    posts = List.from(kInitialPosts);
    reports = List.from(kInitialReports);
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
    toastMessage = msg;
    toastIcon = icon;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2800), () {
      toastMessage = null;
      toastIcon = null;
      notifyListeners();
    });
  }

  void go(String name, {bool reset = false}) {
    if (reset) {
      hist.clear();
    } else if (screen != name) {
      hist.add(screen);
    }
    screen = name;
    sheet = null;
    notifyListeners();
    checkTourEvent('screen:$name');
  }

  void back() {
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
    } else if (offline) {
      toast('Sin conexión: la app sigue funcionando', icon: 'cloud_off');
    }
    notifyListeners();
  }

  void toggleEmergency() {
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
  }

  // --- Help post ---
  void helpPost(int postId) {
    final post = posts.firstWhere((p) => p.id == postId);
    final first = !(helped[postId] ?? false);
    helped[postId] = true;
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
  void openChat(String userName, {String? sysMsg}) {
    if (!chats.containsKey(userName)) {
      chats[userName] = [];
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
    go('llamada');
  }

  // --- Publishing ---
  void finishPublish() {
    final type = pub.type;
    final catId = pub.cat;
    final text = pub.text;
    final cat = _findCat(type, catId);

    if (offline) pending++;

    if (type == 'need' || type == 'offer') {
      posts.insert(
        0,
        PostItem(
          id: DateTime.now().millisecondsSinceEpoch,
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
    sheet = null;
    screen = 'home';
    hist.clear();
    if (name == 'main') {
      emergency = false;
      offline = false;
    }
    tourName = name;
    tourIndex = 0;
    tourBusy = false;
    notifyListeners();
  }

  void nextTourStep() {
    tourIndex++;
    notifyListeners();
  }

  void endTour([bool completed = false]) {
    final n = tourName;
    tourName = null;
    tourIndex = 0;
    if (n == 'em') seenEmTour = true;
    notifyListeners();
    if (completed && n == 'main') {
      toast('Tutorial completado. ¡Bien hecho!', icon: 'celebration');
    }
  }

  void checkTourEvent(String event) {
    if (tourName == null || tourBusy) return;
    // Map event to tour advancement
    if (tourName == 'main') {
      final stepEvents = {
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
      if (stepEvents[tourIndex] == event) {
        tourBusy = true;
        _timers.add(
          Timer(const Duration(milliseconds: 320), () {
            tourBusy = false;
            nextTourStep();
          }),
        );
      }
    } else if (tourName == 'em') {
      if (tourIndex == 3 && event == 'sheet:em') {
        tourBusy = true;
        _timers.add(
          Timer(const Duration(milliseconds: 320), () {
            tourBusy = false;
            nextTourStep();
          }),
        );
      }
    }
  }

  String nowTime() => _nowTime();

  String _nowTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  void addReportFromPuente(Map<String, dynamic> d) {
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
