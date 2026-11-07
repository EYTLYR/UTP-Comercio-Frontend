import 'package:flutter/material.dart';

import '../models/models.dart';

/// Traducción entre el contrato de la API (enums en inglés, lat/lng, ISO-8601)
/// y los modelos de la app (ids en español, posiciones 0..100 en el mapa).
class Api2App {
  // ------------------------------------------------------------ enums

  static const serviceCat = {
    'PLUMBING': 'gasfiteria',
    'ELECTRICITY': 'electricidad',
    'CARPENTRY': 'carpinteria',
    'LOCKSMITH': 'cerrajeria',
    'TUTORING': 'clases',
    'PET_CARE': 'mascotas',
    'SEWING': 'costura',
    'OTHER': 'otros',
  };

  static const postCat = {
    'TOOL_LOAN': 'herramientas',
    'TEMPORARY_HELP': 'temporal',
    'MATERIAL_DONATION': 'materiales',
    'SKILL_EXCHANGE': 'habilidades',
    'SOLIDARITY_RIDE': 'movilidad',
  };

  static const vulnCat = {
    'ELDERLY_ALONE': 'mayor',
    'DISABILITY': 'disc',
    'CHILDREN_ALONE': 'ninos',
    'INJURED': 'herido',
    'PREGNANT': 'gestante',
    'TRAPPED': 'atrapado',
    'OXYGEN_DEPENDENT': 'oxigeno',
  };

  static const resourceType = {
    'WATER': 'agua',
    'FOOD': 'viveres',
    'MEDICINE': 'medicinas',
    'ENERGY': 'energia',
    'SHELTER': 'refugio',
    'TRANSPORT': 'transporte',
  };

  static const sosType = {
    'HEALTH': 'salud',
    'FIRE': 'fuego',
    'ROBBERY': 'robo',
    'EARTHQUAKE': 'sismo',
    'VIOLENCE': 'violencia',
    'OTHER': 'otro',
  };

  /// Etiquetas de la IA (Protocolo Lázaro). Las de mitigación de El Niño no
  /// tienen pantalla en la app y se omiten.
  static const aiTag = {
    'HEIGHT_RESCUE': 'altura',
    'RESCUE_TOOLS': 'rescate',
    'BACKUP_POWER': 'energia',
    'WATER_RESERVE': 'agua',
    'EVAC_TRANSPORT': 'transporte',
    'PARAMEDIC': 'paramedico',
    'TECHNICIAN': 'tecnico',
    'ELDERLY_AT_HOME': 'mayor',
    'REDUCED_MOBILITY': 'movilidad',
    'OXYGEN_DEPENDENT': 'oxigeno',
  };

  static const livesWith = {
    'ELDERLY': 'mayor',
    'CHILDREN': 'ninos',
    'DISABILITY': 'disc',
    'PETS': 'mascotas',
  };

  static const reportStatus = {
    'PENDING': 'p',
    'ON_THE_WAY': 'c',
    'ATTENDED': 'a',
  };

  static String? reverse(Map<String, String> map, String? appValue) {
    if (appValue == null) return null;
    for (final e in map.entries) {
      if (e.value == appValue) return e.key;
    }
    return null;
  }

  static const _serviceTone = {
    'gasfiteria': 'blue',
    'electricidad': 'amber',
    'carpinteria': 'amber',
    'cerrajeria': 'green',
    'clases': 'violet',
    'mascotas': 'green',
    'costura': 'red',
  };

  static const _serviceIcon = {
    'gasfiteria': Icons.plumbing,
    'electricidad': Icons.electrical_services,
    'carpinteria': Icons.carpenter,
    'cerrajeria': Icons.key,
    'clases': Icons.school,
    'mascotas': Icons.pets,
    'costura': Icons.content_cut,
  };

  static String serviceTone(String cat) => _serviceTone[cat] ?? 'green';

  static IconData serviceIcon(String cat) => _serviceIcon[cat] ?? Icons.handyman;

  /// Íconos Material que manda el backend por nombre (mapa, grupos de apoyo).
  static IconData icon(String? name) {
    const icons = <String, IconData>{
      'accessible': Icons.accessible,
      'bolt': Icons.bolt,
      'carpenter': Icons.carpenter,
      'child_care': Icons.child_care,
      'construction': Icons.construction,
      'crisis_alert': Icons.crisis_alert,
      'elderly': Icons.elderly,
      'electrical_services': Icons.electrical_services,
      'flag': Icons.flag,
      'flashlight_on': Icons.flashlight_on,
      'flood': Icons.flood,
      'front_hand': Icons.front_hand,
      'group': Icons.group,
      'handyman': Icons.handyman,
      'home_work': Icons.home_work,
      'key': Icons.key,
      'landslide': Icons.landslide,
      'local_shipping': Icons.local_shipping,
      'medical_services': Icons.medical_services,
      'night_shelter': Icons.night_shelter,
      'personal_injury': Icons.personal_injury,
      'pets': Icons.pets,
      'plumbing': Icons.plumbing,
      'pregnant_woman': Icons.pregnant_woman,
      'psychology': Icons.psychology,
      'pulmonology': Icons.air,
      'restaurant': Icons.restaurant,
      'roofing': Icons.roofing,
      'school': Icons.school,
      'soup_kitchen': Icons.soup_kitchen,
      'styler': Icons.content_cut,
      'volunteer_activism': Icons.volunteer_activism,
      'warning': Icons.warning,
      'water': Icons.water,
      'water_damage': Icons.water_damage,
      'water_drop': Icons.water_drop,
      'water_pump': Icons.water_drop,
      'waves': Icons.waves,
    };
    return icons[name] ?? Icons.place;
  }

  static String _groupTone(String? icon) {
    switch (icon) {
      case 'medical_services':
        return 'red';
      case 'bolt':
      case 'electrical_services':
        return 'amber';
      case 'soup_kitchen':
        return 'green';
      case 'psychology':
        return 'violet';
      default:
        return 'blue';
    }
  }

  // ------------------------------------------------------------ mapa

  /// La Zona 3 · Las Flores se dibuja en una grilla 0..100. Es la misma
  /// conversión que usa el backend al cargar los datos de la demo.
  static const double _lat0 = -11.9790;
  static const double _lng0 = -77.0030;
  static const double _latPerUnit = 0.000108;
  static const double _lngPerUnit = 0.000110;

  static double x(num? lng) =>
      lng == null ? 50 : (50 + (lng - _lng0) / _lngPerUnit).clamp(3, 97).toDouble();

  static double y(num? lat) =>
      lat == null ? 50 : (50 - (lat - _lat0) / _latPerUnit).clamp(3, 97).toDouble();

  static double lat(double y) => _lat0 + (50 - y) * _latPerUnit;

  static double lng(double x) => _lng0 + (x - 50) * _lngPerUnit;

  // ------------------------------------------------------------ textos

  static DateTime? date(Object? iso) =>
      iso is String ? DateTime.tryParse(iso)?.toLocal() : null;

  static String ago(Object? iso) {
    final d = date(iso);
    if (d == null) return 'ahora';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    final weeks = diff.inDays ~/ 7;
    if (weeks < 5) return weeks == 1 ? 'hace 1 semana' : 'hace $weeks semanas';
    final months = diff.inDays ~/ 30;
    return months <= 1 ? 'hace 1 mes' : 'hace $months meses';
  }

  static String clock(Object? iso) {
    final d = date(iso) ?? DateTime.now();
    return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String dist(Object? meters) {
    final m = meters is num ? meters.round() : null;
    if (m == null || m <= 0) return 'aquí';
    if (m >= 1000) return 'a ${(m / 1000).toStringAsFixed(1)} km';
    return 'a $m m';
  }

  static String _s(Object? v, [String fallback = '']) =>
      v is String && v.isNotEmpty ? v : fallback;

  static int _i(Object? v) => v is num ? v.round() : 0;

  // ------------------------------------------------------------ modelos

  static ServiceItem service(Map<String, dynamic> j) {
    final cat = serviceCat[j['category']] ?? 'otros';
    return ServiceItem(
      id: j['id'] as String,
      name: _s(j['ownerName'], 'Vecino'),
      job: _s(j['title'], _s(j['categoryLabel'], 'Oficio')),
      cat: cat,
      icon: serviceIcon(cat),
      tone: serviceTone(cat),
      vb: _i(j['endorsementCount']),
      dist: dist(j['distanceM']),
      price: _s(j['priceText'], 'A convenir'),
      hours: _s(j['scheduleText'], 'Por coordinar'),
      emerg: j['availableInEmergency'] == true,
    );
  }

  static ReviewItem review(Map<String, dynamic> j) => ReviewItem(
    who: _s(j['authorName'], 'Vecino'),
    when: ago(j['createdAt']),
    txt: _s(j['text']),
  );

  static PostItem post(Map<String, dynamic> j) => PostItem(
    id: j['id'] as String,
    type: j['type'] == 'OFFER' ? 'offer' : 'need',
    cat: postCat[j['category']] ?? 'temporal',
    title: _s(j['text'], _s(j['categoryLabel'])),
    user: _s(j['authorName'], 'Vecino'),
    dist: j['mine'] == true ? 'tú' : dist(j['distanceM']),
    time: ago(j['createdAt']),
  );

  static ReportItem report(Map<String, dynamic> j) => ReportItem(
    id: j['id'] as String,
    cat: vulnCat[j['category']] ?? 'herido',
    who: _s(j['categoryLabel'], 'Vecino vulnerable'),
    where: _s(j['addressText'], 'Zona 3'),
    detail: _s(j['detail']),
    prio: j['priority'] == 'MEDIUM' ? 'media' : 'alta',
    status: reportStatus[j['status']] ?? 'p',
    by: (j['assignedLabel'] as String?),
    time: clock(j['createdAt']),
    x: x(j['lng'] as num?),
    y: y(j['lat'] as num?),
    ai: j['source'] == 'AI_PREVENTIVE',
  );

  static ResOfferItem resOffer(Map<String, dynamic> j) => ResOfferItem(
    res: resourceType[j['resourceType']] ?? 'agua',
    type: j['kind'] == 'NEED' ? 'need' : 'offer',
    title: _s(j['text'], _s(j['label'], 'Recurso')),
    user: _s(j['ownerName'], 'Vecino'),
    where: _s(j['locationText'], dist(j['distanceM'])),
  );

  static GroupItem group(Map<String, dynamic> j) => GroupItem(
    id: j['id'] as String?,
    name: _s(j['name'], 'Grupo'),
    icon: icon(j['icon'] as String?),
    tone: _groupTone(j['icon'] as String?),
    members: _i(j['membersCount']),
    desc: _s(j['description'], _s(j['scheduleText'], 'Grupo de apoyo de la zona')),
    live: j['activeNow'] == true,
    phone: j['contactPhone'] as String?,
  );

  static MapPin pin(Map<String, dynamic> j) {
    final kind = _s(j['kind'], 'svc');
    final refType = j['refType'] as String?;
    final String? goTo = switch (refType) {
      'post' => 'muro',
      'vulnerable_report' => 'tablero',
      'resource' => 'recursos',
      'support_group' => 'apoyo',
      _ => null,
    };
    return MapPin(
      id: j['id'] as String,
      kind: kind,
      x: x(j['lng'] as num?),
      y: y(j['lat'] as num?),
      icon: icon(j['icon'] as String?),
      title: _s(j['title']),
      sub: _s(j['subtitle']),
      svc: refType == 'service' ? j['refId'] as String? : null,
      go: goTo,
    );
  }

  /// Hallazgo del inventario de la IA. null si la etiqueta no existe en la app.
  static HistoryItem? inventory(Map<String, dynamic> j) {
    final tag = aiTag[j['tag']];
    if (tag == null) return null;
    final src = switch (j['sourceType']) {
      'SERVICE' => 'Oficios',
      'REVIEW' => 'Reseña',
      'RESOURCE_LISTING' => 'Recursos',
      _ => 'Muro',
    };
    return HistoryItem(
      id: j['id'] as String,
      who: _s(j['displayName'], 'Vecino'),
      zona: _s(j['zoneLabel'], 'Zona 3'),
      src: src,
      when: _s(j['sourceAgo'], 'reciente'),
      txt: _s(j['evidenceText'], _s(j['label'])),
      x: x(j['lng'] as num?),
      y: y(j['lat'] as num?),
      tag: tag,
    );
  }
}
