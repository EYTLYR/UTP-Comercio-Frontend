import 'dart:math';

import 'package:flutter/material.dart';

class CallItem {
  final String num;
  final String label;
  final IconData icon;

  const CallItem({required this.num, required this.label, required this.icon});
}

class CategoryItem {
  final String id;
  final String label;
  final String? short;
  final IconData icon;

  const CategoryItem({
    required this.id,
    required this.label,
    this.short,
    required this.icon,
  });
}

class ServiceItem {
  final String id;
  final String name;
  final String job;
  final String cat;
  final IconData icon;
  final String tone;
  int vb;
  final String dist;
  final String price;
  final String hours;
  final bool emerg;

  ServiceItem({
    required this.id,
    required this.name,
    required this.job,
    required this.cat,
    required this.icon,
    required this.tone,
    required this.vb,
    required this.dist,
    required this.price,
    required this.hours,
    this.emerg = false,
  });
}

class ReviewItem {
  final String who;
  final String when;
  final String txt;

  const ReviewItem({required this.who, required this.when, required this.txt});
}

class PostItem {
  final String id; // UUID del backend
  final String type; // 'need' or 'offer'
  final String cat;
  final String title;
  final String user;
  final String dist;
  final String time;

  PostItem({
    required this.id,
    required this.type,
    required this.cat,
    required this.title,
    required this.user,
    required this.dist,
    required this.time,
  });
}

class ReportItem {
  final dynamic id;
  final String cat;
  final String who;
  final String where;
  final String detail;
  final String prio; // 'alta' or 'media'
  String status; // 'p' (pendiente), 'c' (en camino), 'a' (atendido)
  String? by;
  final String time;
  final double x;
  final double y;
  final bool ai;

  ReportItem({
    required this.id,
    required this.cat,
    required this.who,
    required this.where,
    required this.detail,
    required this.prio,
    required this.status,
    this.by,
    required this.time,
    required this.x,
    required this.y,
    this.ai = false,
  });
}

class ResourceItem {
  final String id;
  final String label;
  final IconData icon;
  final String tone;
  final int have;
  final int need;

  const ResourceItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.tone,
    required this.have,
    required this.need,
  });
}

class ResOfferItem {
  final String res;
  final String type; // 'offer' or 'need'
  final String title;
  final String user;
  final String where;

  const ResOfferItem({
    required this.res,
    required this.type,
    required this.title,
    required this.user,
    required this.where,
  });
}

class GroupItem {
  final String? id; // UUID del backend (null en los datos de ejemplo)
  final String? phone;
  final String name;
  final IconData icon;
  final String tone;
  final int members;
  final String desc;
  final bool live;

  const GroupItem({
    this.id,
    this.phone,
    required this.name,
    required this.icon,
    required this.tone,
    required this.members,
    required this.desc,
    required this.live,
  });
}

class PublishType {
  final String id;
  final String label;
  final String desc;
  final IconData icon;
  final String tone;
  final String q;
  final String ph;
  final String cta;

  const PublishType({
    required this.id,
    required this.label,
    required this.desc,
    required this.icon,
    required this.tone,
    required this.q,
    required this.ph,
    required this.cta,
  });
}

class BrowseZone {
  final String id, name, district;
  final double latitude, longitude;
  final int radius;
  const BrowseZone({
    required this.id,
    required this.name,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });
  factory BrowseZone.fromJson(Map<String, dynamic> json) => BrowseZone(
    id: json['id'] as String,
    name: json['name'] as String,
    district: json['district'] as String? ?? '',
    latitude: (json['centerLat'] as num).toDouble(),
    longitude: (json['centerLng'] as num).toDouble(),
    radius: (json['radiusM'] as num).toInt(),
  );
}

class MapPin {
  final double? latitude;
  final double? longitude;
  final String id;
  final String kind;
  final double x;
  final double y;
  final IconData icon;
  final String title;
  final String sub;
  final String? svc;
  final String? go;

  const MapPin({
    this.latitude,
    this.longitude,
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    required this.icon,
    required this.title,
    required this.sub,
    this.svc,
    this.go,
  });
}

class ContactItem {
  final String id;
  final String name;
  final String phone;
  final IconData icon;

  const ContactItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.icon,
  });
}

class HistoryItem {
  final String id;
  final String who;
  final String zona;
  final String src;
  final String when;
  final String txt;
  final double x;
  final double y;
  String? tag;

  HistoryItem({
    required this.id,
    required this.who,
    required this.zona,
    required this.src,
    required this.when,
    required this.txt,
    required this.x,
    required this.y,
    this.tag,
  });

  HistoryItem copyWith({String? who, String? tag, int? dist}) {
    return HistoryItem(
      id: id,
      who: who ?? this.who,
      zona: zona,
      src: src,
      when: when,
      txt: txt,
      x: x,
      y: y,
      tag: tag ?? this.tag,
    );
  }
}

class AiTag {
  final String l;
  final IconData i;
  final String kind; // 'res', 'skill', 'vuln'
  final String tone;
  final List<String> kw;

  const AiTag({
    required this.l,
    required this.i,
    required this.kind,
    required this.tone,
    required this.kw,
  });
}

class ChatMessage {
  final String from; // 'me', 'them', 'sys'
  final String text;
  final String time;
  final bool pending;

  ChatMessage({
    required this.from,
    required this.text,
    required this.time,
    this.pending = false,
  });
}

// ----------------- Seed Data -----------------

final List<CallItem> kCalls = [
  const CallItem(num: '105', label: 'Policía', icon: Icons.local_police),
  const CallItem(
    num: '116',
    label: 'Bomberos',
    icon: Icons.local_fire_department,
  ),
  const CallItem(num: '106', label: 'SAMU', icon: Icons.medical_services),
  const CallItem(num: '115', label: 'Defensa Civil', icon: Icons.shield),
];

final List<CategoryItem> kServCats = [
  const CategoryItem(id: 'all', label: 'Todos', icon: Icons.apps),
  const CategoryItem(
    id: 'gasfiteria',
    label: 'Gasfitería',
    icon: Icons.plumbing,
  ),
  const CategoryItem(
    id: 'electricidad',
    label: 'Electricidad',
    icon: Icons.electrical_services,
  ),
  const CategoryItem(
    id: 'carpinteria',
    label: 'Carpintería',
    icon: Icons.carpenter,
  ),
  const CategoryItem(id: 'cerrajeria', label: 'Cerrajería', icon: Icons.key),
  const CategoryItem(id: 'clases', label: 'Clases', icon: Icons.school),
  const CategoryItem(id: 'mascotas', label: 'Mascotas', icon: Icons.pets),
  const CategoryItem(id: 'costura', label: 'Costura', icon: Icons.content_cut),
];

final List<ServiceItem> kInitialServices = [
  ServiceItem(
    id: 'julio',
    name: 'Julio Quispe',
    job: 'Gasfitería',
    cat: 'gasfiteria',
    icon: Icons.plumbing,
    tone: 'blue',
    vb: 48,
    dist: 'a 3 cuadras',
    price: 'Desde S/ 35',
    hours: 'Lun a sáb · 7:00 a 19:00',
    emerg: true,
  ),
  ServiceItem(
    id: 'luis',
    name: 'Luis Mendoza',
    job: 'Electricidad',
    cat: 'electricidad',
    icon: Icons.electrical_services,
    tone: 'amber',
    vb: 41,
    dist: 'a 250 m',
    price: 'Desde S/ 40',
    hours: 'Todos los días · 8:00 a 20:00',
    emerg: true,
  ),
  ServiceItem(
    id: 'rosa',
    name: 'Rosa Flores',
    job: 'Clases de matemática',
    cat: 'clases',
    icon: Icons.school,
    tone: 'violet',
    vb: 37,
    dist: 'a 2 cuadras',
    price: 'S/ 20 la hora',
    hours: 'Lun a vie · 15:00 a 19:00',
  ),
  ServiceItem(
    id: 'pedro',
    name: 'Pedro Ramos',
    job: 'Carpintería',
    cat: 'carpinteria',
    icon: Icons.carpenter,
    tone: 'amber',
    vb: 33,
    dist: 'a 5 cuadras',
    price: 'Según el trabajo',
    hours: 'Lun a sáb · 8:00 a 18:00',
    emerg: true,
  ),
  ServiceItem(
    id: 'miguel',
    name: 'Miguel Ccori',
    job: 'Cerrajería',
    cat: 'cerrajeria',
    icon: Icons.key,
    tone: 'green',
    vb: 29,
    dist: 'a 400 m',
    price: 'Desde S/ 25',
    hours: '24 horas',
    emerg: true,
  ),
  ServiceItem(
    id: 'carmen',
    name: 'Carmen Huamán',
    job: 'Costura y arreglos',
    cat: 'costura',
    icon: Icons.content_cut,
    tone: 'red',
    vb: 26,
    dist: 'a 300 m',
    price: 'Desde S/ 8',
    hours: 'Lun a sáb · 9:00 a 18:00',
  ),
  ServiceItem(
    id: 'ana',
    name: 'Ana Torres',
    job: 'Paseo de mascotas',
    cat: 'mascotas',
    icon: Icons.pets,
    tone: 'green',
    vb: 22,
    dist: 'a 1 cuadra',
    price: 'S/ 10 el paseo',
    hours: 'Mañanas y tardes',
  ),
];

final List<ReviewItem> kReviews = [
  const ReviewItem(
    who: 'Elena Vargas',
    when: 'hace 1 semana',
    txt: 'Llegó a la hora, explicó todo y cobró lo justo. Lo recomiendo.',
  ),
  const ReviewItem(
    who: 'Jorge Paredes',
    when: 'hace 3 semanas',
    txt: 'Vecino de confianza. Volvió al día siguiente a revisar que todo esté bien.',
  ),
  const ReviewItem(
    who: 'Teresa Rojas',
    when: 'hace 1 mes',
    txt: 'Me atendió un domingo por una urgencia. Muy amable.',
  ),
];

final List<CategoryItem> kPostCats = [
  const CategoryItem(
    id: 'herramientas',
    label: 'Préstamo de herramientas',
    short: 'Herramientas',
    icon: Icons.build,
  ),
  const CategoryItem(
    id: 'temporal',
    label: 'Ayuda temporal',
    short: 'Ayuda temporal',
    icon: Icons.schedule,
  ),
  const CategoryItem(
    id: 'materiales',
    label: 'Donación de materiales',
    short: 'Materiales',
    icon: Icons.inventory_2,
  ),
  const CategoryItem(
    id: 'habilidades',
    label: 'Intercambio de habilidades',
    short: 'Habilidades',
    icon: Icons.swap_horiz,
  ),
  const CategoryItem(
    id: 'movilidad',
    label: 'Movilidad solidaria',
    short: 'Movilidad',
    icon: Icons.directions_car,
  ),
];

final List<PostItem> kInitialPosts = [
  PostItem(
    id: '1',
    type: 'need',
    cat: 'herramientas',
    title: 'Necesito un taladro por 2 horas para colgar una repisa',
    user: 'Elena Vargas',
    dist: 'a 2 cuadras',
    time: 'hace 15 min',
  ),
  PostItem(
    id: '2',
    type: 'offer',
    cat: 'movilidad',
    title: 'Voy al mercado a las 4 pm, tengo 2 asientos libres',
    user: 'Jorge Paredes',
    dist: 'a 300 m',
    time: 'hace 30 min',
  ),
  PostItem(
    id: '3',
    type: 'offer',
    cat: 'materiales',
    title: 'Regalo 10 ladrillos y medio saco de cemento',
    user: 'Familia Ríos',
    dist: 'a 4 cuadras',
    time: 'hace 1 h',
  ),
  PostItem(
    id: '4',
    type: 'need',
    cat: 'temporal',
    title: '¿Alguien puede acompañar a mi abuela 1 hora el jueves?',
    user: 'Lucía Mamani',
    dist: 'a 1 cuadra',
    time: 'hace 2 h',
  ),
  PostItem(
    id: '5',
    type: 'offer',
    cat: 'habilidades',
    title: 'Enseño a usar el celular a cambio de ayuda con mi jardín',
    user: 'Óscar Díaz',
    dist: 'a 500 m',
    time: 'hace 3 h',
  ),
  PostItem(
    id: '6',
    type: 'need',
    cat: 'movilidad',
    title: 'Necesito que lleven a mi papá a su cita médica el lunes',
    user: 'Carla Soto',
    dist: 'a 3 cuadras',
    time: 'ayer',
  ),
];

final List<CategoryItem> kVulnCats = [
  const CategoryItem(
    id: 'mayor',
    label: 'Adulto mayor solo',
    icon: Icons.elderly,
  ),
  const CategoryItem(
    id: 'disc',
    label: 'Persona con discapacidad',
    icon: Icons.accessible,
  ),
  const CategoryItem(
    id: 'ninos',
    label: 'Niños sin un adulto',
    icon: Icons.child_care,
  ),
  const CategoryItem(
    id: 'herido',
    label: 'Persona herida',
    icon: Icons.personal_injury,
  ),
  const CategoryItem(
    id: 'gestante',
    label: 'Gestante',
    icon: Icons.pregnant_woman,
  ),
  const CategoryItem(
    id: 'atrapado',
    label: 'Persona atrapada',
    icon: Icons.warning,
  ),
  const CategoryItem(
    id: 'oxigeno',
    label: 'Depende de oxígeno',
    icon: Icons.air,
  ),
];

final List<ReportItem> kInitialReports = [
  ReportItem(
    id: 1,
    cat: 'mayor',
    who: 'Adulta mayor sola',
    where: 'Mz. C lote 12',
    detail: 'La Sra. Teresa (82) vive sola en un 2do piso y no responde. La escalera de su casa se cayó.',
    prio: 'alta',
    status: 'p',
    time: '10:51',
    x: 34,
    y: 34,
  ),
  ReportItem(
    id: 2,
    cat: 'herido',
    who: 'Persona herida',
    where: 'Jr. Los Pinos 340',
    detail: 'Corte en el brazo por vidrios. Está consciente.',
    prio: 'alta',
    status: 'c',
    by: 'Brigada Z3',
    time: '10:49',
    x: 66,
    y: 62,
  ),
  ReportItem(
    id: 3,
    cat: 'disc',
    who: 'Persona con discapacidad',
    where: 'Mz. F lote 3',
    detail: 'Usa silla de ruedas y vive en un 2do piso.',
    prio: 'media',
    status: 'c',
    by: 'Luis M.',
    time: '10:46',
    x: 55,
    y: 28,
  ),
  ReportItem(
    id: 4,
    cat: 'ninos',
    who: 'Niños sin un adulto',
    where: 'Pje. Las Rosas 18',
    detail: 'Dos niños solos; la mamá trabaja en el centro.',
    prio: 'alta',
    status: 'a',
    by: 'Rosa F.',
    time: '10:44',
    x: 40,
    y: 72,
  ),
];

final List<ResourceItem> kResources = [
  const ResourceItem(
    id: 'agua',
    label: 'Agua',
    icon: Icons.water_drop,
    tone: 'blue',
    have: 14,
    need: 9,
  ),
  const ResourceItem(
    id: 'viveres',
    label: 'Víveres',
    icon: Icons.shopping_basket,
    tone: 'amber',
    have: 8,
    need: 12,
  ),
  const ResourceItem(
    id: 'medicinas',
    label: 'Botiquín y medicinas',
    icon: Icons.medication,
    tone: 'red',
    have: 5,
    need: 7,
  ),
  const ResourceItem(
    id: 'energia',
    label: 'Carga de celular',
    icon: Icons.battery_charging_full,
    tone: 'green',
    have: 6,
    need: 15,
  ),
  const ResourceItem(
    id: 'refugio',
    label: 'Refugio o techo',
    icon: Icons.night_shelter,
    tone: 'violet',
    have: 3,
    need: 4,
  ),
  const ResourceItem(
    id: 'transporte',
    label: 'Transporte',
    icon: Icons.directions_car,
    tone: 'blue',
    have: 4,
    need: 2,
  ),
];

final List<ResOfferItem> kInitialResOffers = [
  const ResOfferItem(
    res: 'agua',
    type: 'offer',
    title: '20 litros de agua potable',
    user: 'Familia Ríos',
    where: 'Mz. B lote 4',
  ),
  const ResOfferItem(
    res: 'agua',
    type: 'need',
    title: 'Agua para 4 personas (1 bebé)',
    user: 'Carla Soto',
    where: 'Jr. Los Pinos 210',
  ),
  const ResOfferItem(
    res: 'agua',
    type: 'offer',
    title: 'Cisterna comunal: reparto a las 14:00',
    user: 'Junta vecinal',
    where: 'Local comunal',
  ),
  const ResOfferItem(
    res: 'viveres',
    type: 'offer',
    title: 'Arroz, menestras y atún para 3 familias',
    user: 'Bodega Don Pepe',
    where: 'Av. Principal 120',
  ),
  const ResOfferItem(
    res: 'viveres',
    type: 'need',
    title: 'Leche y pañales para bebé',
    user: 'Lucía Mamani',
    where: 'Mz. D lote 7',
  ),
  const ResOfferItem(
    res: 'medicinas',
    type: 'offer',
    title: 'Botiquín completo y gasas',
    user: 'Óscar Díaz',
    where: 'Mz. A lote 9',
  ),
  const ResOfferItem(
    res: 'energia',
    type: 'offer',
    title: 'Generador: carga tu celular de 4 a 6 pm',
    user: 'Taller Mendoza',
    where: 'Jr. Las Flores 300',
  ),
  const ResOfferItem(
    res: 'energia',
    type: 'need',
    title: 'Batería externa para persona con oxígeno',
    user: 'Familia Soto',
    where: 'Mz. F lote 1',
  ),
  const ResOfferItem(
    res: 'refugio',
    type: 'offer',
    title: 'Local comunal abierto · 60 cupos',
    user: 'Junta vecinal',
    where: 'Parque Las Flores',
  ),
  const ResOfferItem(
    res: 'transporte',
    type: 'offer',
    title: 'Mototaxi para trasladar heridos',
    user: 'Jorge Paredes',
    where: 'Paradero Av. Principal',
  ),
];

final List<GroupItem> kGroups = [
  const GroupItem(
    name: 'Brigada de primeros auxilios Z3',
    icon: Icons.medical_services,
    tone: 'red',
    members: 12,
    desc: 'Atención básica de heridos y traslado',
    live: true,
  ),
  const GroupItem(
    name: 'Electricistas de guardia',
    icon: Icons.electrical_services,
    tone: 'amber',
    members: 4,
    desc: 'Cables caídos y cortes de luz',
    live: true,
  ),
  const GroupItem(
    name: 'Evaluación de viviendas',
    icon: Icons.construction,
    tone: 'blue',
    members: 5,
    desc: 'Albañiles e ingenieros revisan estructuras',
    live: true,
  ),
  const GroupItem(
    name: 'Olla común Las Flores',
    icon: Icons.soup_kitchen,
    tone: 'green',
    members: 20,
    desc: 'Comida caliente 12:00 y 18:00 · Local comunal',
    live: true,
  ),
  const GroupItem(
    name: 'Apoyo psicológico',
    icon: Icons.psychology,
    tone: 'violet',
    members: 6,
    desc: 'Escucha y contención por llamada',
    live: false,
  ),
];

final List<PublishType> kTypes = [
  const PublishType(
    id: 'need',
    label: 'Necesito ayuda',
    desc: 'Pide un favor o un préstamo a tus vecinos',
    icon: Icons.back_hand,
    tone: 'amber',
    q: '¿Qué necesitas?',
    ph: 'Ej. Necesito una escalera por 1 hora',
    cta: 'Publicar pedido',
  ),
  const PublishType(
    id: 'offer',
    label: 'Ofrezco ayuda',
    desc: 'Presta, dona, enseña o lleva a alguien',
    icon: Icons.volunteer_activism,
    tone: 'green',
    q: '¿Qué ofreces?',
    ph: 'Ej. Presto mi taladro este fin de semana',
    cta: 'Publicar oferta',
  ),
  const PublishType(
    id: 'service',
    label: 'Ofrezco mi oficio',
    desc: 'Súmate al directorio de servicios del barrio',
    icon: Icons.handyman,
    tone: 'blue',
    q: '¿Cuál es tu oficio?',
    ph: 'Ej. Gasfitero con 10 años de experiencia',
    cta: 'Publicar mi servicio',
  ),
];

final List<PublishType> kEmTypes = [
  const PublishType(
    id: 'vulnerable',
    label: 'Reportar vecino vulnerable',
    desc: 'Alguien que necesita ayuda y no puede pedirla',
    icon: Icons.elderly,
    tone: 'red',
    q: '¿Quién necesita ayuda?',
    ph: 'Ej. Señora de 80 años vive sola y no responde',
    cta: 'Enviar reporte',
  ),
  const PublishType(
    id: 'needres',
    label: 'Necesito un recurso',
    desc: 'Agua, víveres, medicinas, energía o refugio',
    icon: Icons.back_hand,
    tone: 'amber',
    q: '¿Qué recurso necesitas?',
    ph: 'Ej. Necesitamos agua para 4 personas',
    cta: 'Publicar necesidad',
  ),
  const PublishType(
    id: 'offerres',
    label: 'Ofrezco un recurso',
    desc: 'Comparte lo que tienes con tus vecinos',
    icon: Icons.volunteer_activism,
    tone: 'green',
    q: '¿Qué puedes compartir?',
    ph: 'Ej. Tengo 20 litros de agua',
    cta: 'Publicar oferta',
  ),
];

final List<ContactItem> kAllContacts = [
  const ContactItem(
    id: 'mama',
    name: 'Mamá',
    phone: '+51 987 *** 120',
    icon: Icons.family_restroom,
  ),
  const ContactItem(
    id: 'carlos',
    name: 'Carlos (hermano)',
    phone: '+51 956 *** 447',
    icon: Icons.person,
  ),
  const ContactItem(
    id: 'rosa',
    name: 'Sra. Rosa (vecina)',
    phone: '+51 944 *** 908',
    icon: Icons.house,
  ),
  const ContactItem(
    id: 'lucia',
    name: 'Lucía Mamani',
    phone: '+51 912 *** 336',
    icon: Icons.person,
  ),
  const ContactItem(
    id: 'jorge',
    name: 'Jorge Paredes',
    phone: '+51 965 *** 781',
    icon: Icons.person,
  ),
  const ContactItem(
    id: 'tia',
    name: 'Tía Gloria',
    phone: '+51 978 *** 502',
    icon: Icons.family_restroom,
  ),
  const ContactItem(
    id: 'oscar',
    name: 'Óscar Díaz',
    phone: '+51 933 *** 214',
    icon: Icons.person,
  ),
];

final List<MapPin> kNormalPins = [
  const MapPin(
    id: 'a',
    kind: 'svc',
    x: 28,
    y: 30,
    icon: Icons.plumbing,
    title: 'Julio Quispe · Gasfitería',
    sub: '48 vistos buenos · a 3 cuadras',
    svc: 'julio',
  ),
  const MapPin(
    id: 'b',
    kind: 'svc',
    x: 72,
    y: 24,
    icon: Icons.electrical_services,
    title: 'Luis Mendoza · Electricidad',
    sub: '41 vistos buenos · a 250 m',
    svc: 'luis',
  ),
  const MapPin(
    id: 'c',
    kind: 'svc',
    x: 64,
    y: 70,
    icon: Icons.school,
    title: 'Rosa Flores · Clases',
    sub: '37 vistos buenos · a 2 cuadras',
    svc: 'rosa',
  ),
  const MapPin(
    id: 'd',
    kind: 'svc',
    x: 16,
    y: 46,
    icon: Icons.key,
    title: 'Miguel Ccori · Cerrajería',
    sub: '29 vistos buenos · a 400 m',
    svc: 'miguel',
  ),
  const MapPin(
    id: 'e',
    kind: 'need',
    x: 40,
    y: 62,
    icon: Icons.build,
    title: 'Necesita un taladro',
    sub: 'Elena Vargas · hace 15 min',
    go: 'muro',
  ),
  const MapPin(
    id: 'f',
    kind: 'offer',
    x: 80,
    y: 46,
    icon: Icons.directions_car,
    title: 'Ofrece 2 asientos al mercado',
    sub: 'Jorge Paredes · 4:00 pm',
    go: 'muro',
  ),
  const MapPin(
    id: 'g',
    kind: 'offer',
    x: 24,
    y: 74,
    icon: Icons.inventory_2,
    title: 'Regala ladrillos y cemento',
    sub: 'Familia Ríos · hace 1 h',
    go: 'muro',
  ),
];

final List<MapPin> kEmergencyPins = [
  const MapPin(
    id: 'h',
    kind: 'vuln',
    x: 34,
    y: 34,
    icon: Icons.elderly,
    title: 'Adulta mayor sola',
    sub: 'Mz. C lote 12 · Pendiente',
    go: 'tablero',
  ),
  const MapPin(
    id: 'i',
    kind: 'vuln',
    x: 66,
    y: 62,
    icon: Icons.personal_injury,
    title: 'Persona herida',
    sub: 'Jr. Los Pinos 340 · Brigada en camino',
    go: 'tablero',
  ),
  const MapPin(
    id: 'j',
    kind: 'vuln',
    x: 56,
    y: 26,
    icon: Icons.accessible,
    title: 'Persona con discapacidad',
    sub: 'Mz. F lote 3 · Luis M. en camino',
    go: 'tablero',
  ),
  const MapPin(
    id: 'k',
    kind: 'safe',
    x: 24,
    y: 52,
    icon: Icons.flag,
    title: 'Punto de reunión · Parque Las Flores',
    sub: 'Zona segura · a 200 m',
  ),
  const MapPin(
    id: 'l',
    kind: 'safe',
    x: 80,
    y: 76,
    icon: Icons.night_shelter,
    title: 'Refugio · Local comunal',
    sub: '60 cupos · 22 ocupados',
  ),
  const MapPin(
    id: 'm',
    kind: 'res',
    x: 74,
    y: 38,
    icon: Icons.water_drop,
    title: 'Agua disponible · Familia Ríos',
    sub: '20 litros · Mz. B lote 4',
    go: 'recursos',
  ),
  const MapPin(
    id: 'n',
    kind: 'res',
    x: 42,
    y: 76,
    icon: Icons.soup_kitchen,
    title: 'Olla común Las Flores',
    sub: 'Comida a las 12:00 y 18:00',
    go: 'apoyo',
  ),
  const MapPin(
    id: 'o',
    kind: 'group',
    x: 16,
    y: 26,
    icon: Icons.medical_services,
    title: 'Brigada de primeros auxilios',
    sub: 'Base: Mz. A lote 1 · 12 miembros',
    go: 'apoyo',
  ),
];

final List<HistoryItem> kHistory = [
  HistoryItem(
    id: 'h1',
    who: 'Jorge Paredes',
    zona: 'Mz. B',
    src: 'Muro',
    when: 'hace 3 semanas',
    txt: 'Presto escalera grande de 6 metros y taladro',
    x: 37,
    y: 30,
  ),
  HistoryItem(
    id: 'h2',
    who: 'Pedro Ramos',
    zona: 'Mz. A',
    src: 'Oficios',
    when: 'en su perfil',
    txt: 'Carpintero con herramientas de palanca y gata hidráulica',
    x: 28,
    y: 42,
  ),
  HistoryItem(
    id: 'h3',
    who: 'Taller Mendoza',
    zona: 'Jr. Las Flores',
    src: 'Muro',
    when: 'hace 2 meses',
    txt: 'Presto mi generador eléctrico para la fiesta del barrio',
    x: 61,
    y: 16,
  ),
  HistoryItem(
    id: 'h4',
    who: 'Rosa Flores',
    zona: 'Jr. Los Pinos',
    src: 'Reseña',
    when: 'hace 1 mes',
    txt: 'Gracias Rosa por inyectarme cuando me enfermé (reseña de Teresa R.)',
    x: 60,
    y: 66,
  ),
  HistoryItem(
    id: 'h5',
    who: 'Luis Mendoza',
    zona: 'Jr. Las Flores',
    src: 'Oficios',
    when: 'en su perfil',
    txt: 'Electricista, atiende emergencias las 24 horas',
    x: 72,
    y: 24,
  ),
  HistoryItem(
    id: 'h6',
    who: 'Lucía Mamani',
    zona: 'Mz. D',
    src: 'Muro',
    when: 'hace 2 meses',
    txt: '¿Alguien puede acompañar a mi abuela 1 hora? No puede caminar sola',
    x: 44,
    y: 50,
  ),
  HistoryItem(
    id: 'h7',
    who: 'Familia Soto',
    zona: 'Mz. F',
    src: 'Muro',
    when: 'hace 5 semanas',
    txt: 'Busco quien me ayude a cargar el balón de oxígeno de mi papá',
    x: 57,
    y: 21,
  ),
  HistoryItem(
    id: 'h8',
    who: 'Jorge Paredes',
    zona: 'Mz. B',
    src: 'Muro',
    when: 'hace 30 min',
    txt: 'Voy al mercado en mi mototaxi a las 4 pm, tengo 2 asientos libres',
    x: 37,
    y: 30,
  ),
  HistoryItem(
    id: 'h9',
    who: 'Óscar Díaz',
    zona: 'Mz. A',
    src: 'Muro',
    when: 'hace 1 semana',
    txt: 'Regalo botiquín completo; soy técnico en enfermería jubilado',
    x: 20,
    y: 60,
  ),
  HistoryItem(
    id: 'h10',
    who: 'Familia Ríos',
    zona: 'Mz. B',
    src: 'Muro',
    when: 'hace 1 hora',
    txt: 'Tenemos tanque de agua de 1100 litros, pueden sacar si se corta',
    x: 76,
    y: 40,
  ),
  HistoryItem(
    id: 'h11',
    who: 'Carla Soto',
    zona: 'Mz. F',
    src: 'Muro',
    when: 'ayer',
    txt: 'Necesito que lleven a mi papá a su cita médica, usa silla de ruedas',
    x: 54,
    y: 27,
  ),
  HistoryItem(
    id: 'h12',
    who: '@me',
    zona: 'Jr. Las Flores',
    src: 'Muro',
    when: 'hace 2 meses',
    txt: 'Ofrezco ayuda con primeros auxilios, hice el curso de la brigada',
    x: 50,
    y: 50,
  ),
];

final Map<String, AiTag> kAiTags = {
  'altura': const AiTag(
    l: 'Rescate en altura',
    i: Icons.stairs,
    kind: 'res',
    tone: 'blue',
    kw: ['escalera'],
  ),
  'rescate': const AiTag(
    l: 'Herramientas de rescate',
    i: Icons.construction,
    kind: 'res',
    tone: 'amber',
    kw: ['palanca', 'gata', 'taladro', 'barreta'],
  ),
  'energia': const AiTag(
    l: 'Energía de respaldo',
    i: Icons.bolt,
    kind: 'res',
    tone: 'amber',
    kw: ['generador', 'panel solar'],
  ),
  'agua': const AiTag(
    l: 'Reserva de agua',
    i: Icons.water_drop,
    kind: 'res',
    tone: 'blue',
    kw: ['tanque de agua', 'cisterna'],
  ),
  'transporte': const AiTag(
    l: 'Transporte de evacuación',
    i: Icons.local_taxi,
    kind: 'res',
    tone: 'green',
    kw: ['mototaxi', 'camioneta', 'asientos libres'],
  ),
  'paramedico': const AiTag(
    l: 'Soporte paramédico',
    i: Icons.medical_services,
    kind: 'skill',
    tone: 'red',
    kw: ['inyect', 'enfermer', 'primeros auxilios'],
  ),
  'tecnico': const AiTag(
    l: 'Brigadista técnico',
    i: Icons.electrical_services,
    kind: 'skill',
    tone: 'amber',
    kw: ['electricista', 'gasfiter'],
  ),
  'mayor': const AiTag(
    l: 'Adulto mayor en casa',
    i: Icons.elderly,
    kind: 'vuln',
    tone: 'red',
    kw: ['abuela', 'abuelo', 'adulto mayor'],
  ),
  'movilidad': const AiTag(
    l: 'Movilidad reducida',
    i: Icons.accessible,
    kind: 'vuln',
    tone: 'red',
    kw: ['silla de ruedas', 'no puede caminar'],
  ),
  'oxigeno': const AiTag(
    l: 'Depende de oxígeno',
    i: Icons.air,
    kind: 'vuln',
    tone: 'red',
    kw: ['oxígeno', 'oxigeno'],
  ),
};

final Map<String, List<String>> kMissionNeeds = {
  'mayor': ['altura', 'rescate'],
  'atrapado': ['altura', 'rescate'],
  'herido': ['paramedico', 'transporte'],
  'disc': ['transporte', 'altura'],
  'ninos': ['paramedico'],
  'gestante': ['paramedico', 'transporte'],
  'oxigeno': ['energia', 'paramedico'],
};

final Map<String, String> kStreets = {
  'LP': 'Jr. Los Pinos',
  'LF': 'Jr. Las Flores',
  'LR': 'Pje. Las Rosas',
  'AP': 'Av. Principal',
};

final Map<String, String> kTypeCode = {
  'herido': 'H',
  'atrapado': 'A',
  'mayor': 'M',
  'disc': 'D',
  'ninos': 'N',
  'gestante': 'G',
  'oxigeno': 'O',
  'salud': 'S',
  'fuego': 'F',
  'robo': 'R',
  'sismo': 'Q',
  'violencia': 'V',
  'otro': 'X',
};

final Map<String, String> kTypeName = {
  'H': 'Persona herida',
  'A': 'Persona atrapada',
  'M': 'Adulto mayor',
  'D': 'Persona con discapacidad',
  'N': 'Niños sin adulto',
  'G': 'Gestante',
  'O': 'Depende de oxígeno',
  'S': 'Salud',
  'F': 'Incendio',
  'R': 'Robo',
  'Q': 'Sismo',
  'V': 'Violencia',
  'X': 'Emergencia',
};

int distM(double ax, double ay, double bx, double by) {
  final d = (sqrt(pow(ax - bx, 2) + pow(ay - by, 2)) * 12 / 5).round() * 5;
  return d == 0 ? 5 : d;
}

String locCode(String? loc) {
  if (loc == null || loc.isEmpty) return 'LF245';
  final mzMatch = RegExp(
    r'Mz\.\s*([A-Za-z])\s*lote\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(loc);
  if (mzMatch != null) {
    return 'M${mzMatch.group(1)!.toUpperCase()}${mzMatch.group(2)}';
  }
  String code = 'XX';
  for (final entry in kStreets.entries) {
    if (loc.startsWith(entry.value)) {
      code = entry.key;
      break;
    }
  }
  final numMatch = RegExp(r'\d+').firstMatch(loc);
  final num = numMatch != null ? numMatch.group(0) : '0';
  return '$code$num';
}

String compressSOS({
  required String cat,
  int injured = 1,
  required String loc,
  String prio = 'alta',
}) {
  final type = kTypeCode[cat] ?? 'X';
  final p = prio == 'alta' ? 'ALTA' : 'MEDIA';
  return 'NB#SOS!$type$injured@${locCode(loc)}\$P:$p';
}

Map<String, dynamic>? decompressSOS(String code) {
  final regex = RegExp(r'^NB#SOS!([A-Z])(\d)@([A-Z]+?)(\d+)\$P:(ALTA|MEDIA)$');
  final match = regex.firstMatch(code.trim().toUpperCase());
  if (match == null) return null;
  final t = match.group(1)!;
  final n = int.parse(match.group(2)!);
  final pre = match.group(3)!;
  final num = match.group(4)!;
  final p = match.group(5)!;

  String where;
  if (pre.length == 2 && pre[0] == 'M' && !kStreets.containsKey(pre)) {
    where = 'Mz. ${pre[1]} lote $num';
  } else {
    where = '${kStreets[pre] ?? pre} $num';
  }

  return {
    'type': kTypeName[t] ?? 'Emergencia',
    'injured': n,
    'where': where,
    'prio': p == 'ALTA' ? 'Alta' : 'Media',
  };
}
