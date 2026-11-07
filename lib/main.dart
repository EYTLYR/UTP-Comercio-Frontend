import 'package:flutter/material.dart';

void main() => runApp(const NearbyApp());

const navy = Color(0xFF15233A);
const green = Color(0xFF00A07F);
const background = Color(0xFFF4F7F8);
const muted = Color(0xFF5B687A);
const line = Color(0xFFDDE5EA);
const red = Color(0xFFE0344A);
const amber = Color(0xFFF0A93A);
const violet = Color(0xFF6A55C8);

class NearbyApp extends StatefulWidget {
  const NearbyApp({super.key});

  @override
  State<NearbyApp> createState() => _NearbyAppState();
}

class _NearbyAppState extends State<NearbyApp> {
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool dark = false;
  bool emergency = false;
  int tab = 0;
  String page = 'home';
  bool checkedIn = false;

  Color get ink => dark ? const Color(0xFFE8EEF6) : navy;
  Color get surface => dark ? const Color(0xFF142038) : Colors.white;
  Color get pageBackground =>
      dark ? const Color(0xFF0C1524) : background;

  void open(String destination) {
    setState(() {
      page = destination;
      tab = switch (destination) {
        'home' => 0,
        'services' => 1,
        'publish' => 2,
        'wall' => 3,
        'map' => 4,
        _ => tab,
      };
    });
  }

  void toggleEmergency() {
    setState(() {
      emergency = !emergency;
      page = 'home';
      tab = 0;
    });
    _toast(emergency ? 'Modo emergencia activado' : 'Volviste al modo normal');
  }

  void _toast(String message) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: pageBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emergency ? red : green,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      dividerColor: dark ? const Color(0xFF25355A) : line,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nearby',
      scaffoldMessengerKey: messengerKey,
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: pageBackground,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _buildPage(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    final content = switch (page) {
      'home' => _home(context),
      'services' => _services(context),
      'wall' => _wall(context),
      'map' => _map(context),
      'publish' => _publish(context),
      'profile' => _profile(context),
      'support' => _emergencyList(
          'Grupos de apoyo',
          'Servicios y grupos activos para situaciones críticas.',
          [
            'Brigada de primeros auxilios Z3 · 12 vecinos',
            'Electricistas de guardia · 4 vecinos',
            'Evaluación de viviendas · 5 vecinos',
            'Olla común Las Flores · 20 vecinos',
          ]),
      'resources' => _emergencyList(
          'Recursos críticos',
          'Coordina y comparte lo que hay y lo que falta.',
          [
            'Agua · Hay 14 · Faltan 9',
            'Víveres · Hay 8 · Faltan 12',
            'Botiquín y medicinas · Hay 5 · Faltan 7',
            'Carga de celular · Hay 6 · Faltan 15',
            'Refugio o techo · Hay 3 · Faltan 4',
          ]),
      'emergency' => _sos(context),
      _ => _home(context),
    };
    return Column(
      children: [
        if (page != 'emergency') _topBar(context),
        if (emergency && page != 'emergency') _emergencyBanner(context),
        Expanded(child: content),
        if (page != 'emergency') _bottomNavigation(),
      ],
    );
  }

  Widget _topBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          children: [
            _brandMark(),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => open('profile'),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border.all(color: line),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: green, size: 21),
                      const SizedBox(width: 5),
                      Text('Zona 3 · Las Flores',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (page != 'home')
              _pillButton('SOS', red, Icons.emergency, () => open('emergency')),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => open('profile'),
              child: CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFFECE8FA),
                child: Text('MQ',
                    style: TextStyle(color: violet, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      );

  Widget _emergencyBanner(BuildContext context) => InkWell(
        onTap: () => _showEmergencyOptions(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: navy,
          child: Row(
            children: [
              const Icon(Icons.crisis_alert, color: Colors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modo emergencia activo',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    Text('Activado por ti · toca para opciones',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => open('map'),
                child: const Text('Mapa', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );

  Widget _bottomNavigation() {
    final labels = emergency
        ? ['Inicio', 'Apoyo', 'Reportar', 'Recursos', 'Mapa']
        : ['Inicio', 'Servicios', 'Publicar', 'Muro', 'Mapa'];
    final icons = emergency
        ? [
            Icons.home,
            Icons.diversity_3,
            Icons.add,
            Icons.inventory_2,
            Icons.map
          ]
        : [Icons.home, Icons.handyman, Icons.add, Icons.volunteer_activism, Icons.map];
    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: line)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          final selected = tab == index;
          return Expanded(
            child: InkWell(
              onTap: () => open(
                  ['home', emergency ? 'support' : 'services', 'publish',
                   emergency ? 'resources' : 'wall', 'map'][index]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: index == 2 ? 56 : 52,
                    height: index == 2 ? 56 : 32,
                    decoration: BoxDecoration(
                      color: index == 2
                          ? (emergency ? red : green)
                          : selected
                              ? (emergency
                                  ? const Color(0xFFFCE5E8)
                                  : const Color(0xFFDDF3EC))
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(index == 2 ? 19 : 18),
                    ),
                    child: Icon(icons[index],
                        color: index == 2
                            ? Colors.white
                            : selected
                                ? (emergency ? red : green)
                                : muted),
                  ),
                  Text(labels[index],
                      style: TextStyle(
                          color: selected ? (emergency ? red : green) : muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _home(BuildContext context) => ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          _heading(emergency ? 'María, mantén la calma' : 'Hola, María Quispe',
              emergency ? 'Tu barrio se está organizando' : '¿Qué necesitas hoy?'),
          _sosCard(context),
          if (emergency) _checkInCard(),
          if (!emergency) ...[
            _sectionTitle('Día a día'),
            _quickGrid(context, [
              _Quick('Buscar un servicio', 'Oficios con Visto Bueno',
                  Icons.handyman, green, () => open('services')),
              _Quick('Pedir un favor', 'Sin dinero, entre vecinos',
                  Icons.back_hand, amber, () => open('publish')),
              _Quick('Ofrecer ayuda', 'Presta, dona o enseña',
                  Icons.volunteer_activism, const Color(0xFF2F6FE4), () => open('publish')),
              _Quick('Ver el mapa', 'Lo que hay cerca de ti',
                  Icons.map, violet, () => open('map')),
            ]),
            _sectionTitle('Recomendados por tus vecinos', action: 'Ver todos',
                onAction: () => open('services')),
            _horizontalServices(),
            _sectionTitle('En el muro ahora', action: 'Ver muro',
                onAction: () => open('wall')),
            _postCard('Necesito un taladro por 1 hora', 'Elena Vargas', Icons.build,
                'hace 15 min', amber),
            _postCard('Ofrezco 2 asientos al mercado', 'Jorge Paredes',
                Icons.directions_car, '4:00 pm', green),
          ] else ...[
            _sectionTitle('Coordinar ayuda'),
            _quickGrid(context, [
              _Quick('Reportar vecino vulnerable', 'Adultos mayores, heridos…',
                  Icons.elderly, red, () => open('publish')),
              _Quick('Recursos críticos', 'Agua, víveres, energía',
                  Icons.inventory_2, amber, () => _showResources(context)),
              _Quick('Grupos de apoyo', 'Brigadas y oficios',
                  Icons.diversity_3, violet, () => _showSupport(context)),
              _Quick('Puntos seguros', 'Reunión y refugios',
                  Icons.flag, const Color(0xFF2F6FE4), () => open('map')),
            ]),
            _sectionTitle('Tablero del barrio', action: 'Ver todo',
                onAction: () => _showBoard(context)),
            _stats(),
            _postCard('Adulta mayor sola', 'Mz. C lote 12', Icons.elderly,
                'Pendiente · 10:51', red),
            _postCard('Persona herida', 'Jr. Los Pinos 340',
                Icons.personal_injury, 'Brigada en camino · 10:49', red),
          ],
        ],
      );

  Widget _sosCard(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: emergency ? red : const Color(0xFFFCE5E8),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: emergency ? Colors.white : red),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Estás en peligro?',
                          style: TextStyle(
                              color: emergency ? Colors.white : navy,
                              fontWeight: FontWeight.w800)),
                      Text('Mantén presionado el botón 2 segundos',
                          style: TextStyle(
                              color: emergency ? Colors.white70 : muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onLongPress: () => open('emergency'),
              child: Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: red,
                  border: Border.all(
                      color: emergency ? Colors.white54 : Colors.white, width: 7),
                  boxShadow: const [
                    BoxShadow(color: Color(0x55E0344A), blurRadius: 16)
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('SOS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900)),
                    Text('Mantener',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Avisa a vecinos en 500 m, a tus contactos y a la brigada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: emergency ? Colors.white : muted, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _callChip('105', 'Policía', Icons.local_police)),
                Expanded(
                    child: _callChip('116', 'Bomberos', Icons.local_fire_department)),
                Expanded(child: _callChip('106', 'SAMU', Icons.medical_services)),
              ],
            ),
          ],
        ),
      );

  Widget _checkInCard() => _card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: checkedIn
            ? const ListTile(
                leading: Icon(Icons.check_circle, color: green),
                title: Text('Marcaste que estás bien',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('Avisamos a tus 3 contactos y a la brigada.'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¿Cómo estás?',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const Text('Tu respuesta llega a tus contactos y al tablero del barrio.',
                      style: TextStyle(color: muted, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _button('Estoy bien', green, Icons.check_circle,
                            () => setState(() => checkedIn = true))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _outlineButton('Necesito ayuda', red, Icons.sos,
                            () => open('emergency'))),
                  ]),
                ],
              ),
      );

  Widget _services(BuildContext context) => _scrollPage(
        title: 'Servicios de confianza',
        subtitle: 'Oficios con Visto Bueno de tus vecinos.',
        body: [
          _chips(['Todos', 'Gasfitería', 'Electricidad', 'Carpintería', 'Cerrajería',
            'Clases', 'Mascotas']),
          _serviceCard('Julio Quispe', 'Gasfitería', Icons.plumbing, '48',
              'a 3 cuadras', 'Desde S/ 35', green),
          _serviceCard('Luis Mendoza', 'Electricidad', Icons.electrical_services,
              '41', 'a 250 m', 'Desde S/ 40', amber),
          _serviceCard('Rosa Flores', 'Clases de matemática', Icons.school, '37',
              'a 2 cuadras', 'S/ 20 la hora', violet),
          _serviceCard('Pedro Salazar', 'Cerrajería', Icons.key, '29',
              'a 400 m', 'Desde S/ 30', const Color(0xFF2F6FE4)),
        ],
      );

  Widget _wall(BuildContext context) => _scrollPage(
        title: 'Muro del barrio',
        subtitle: 'Favores, préstamos y ayuda entre vecinos.',
        body: [
          _chips(['Todo', 'Necesitan', 'Ofrecen']),
          _postCard('Necesito un taladro por 1 hora', 'Elena Vargas', Icons.build,
              'hace 15 min', amber),
          _postCard('Ofrezco 2 asientos al mercado', 'Jorge Paredes',
              Icons.directions_car, '4:00 pm', green),
          _postCard('Regalo ladrillos y cemento', 'Familia Ríos', Icons.inventory_2,
              'hace 1 h', green),
          _postCard('Busco clases de matemática para mi hija', 'Carla Soto',
              Icons.school, 'hace 2 h', amber),
        ],
      );

  Widget _map(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child:             CustomPaint(painter: _MapPainter(dark: dark, emergency: emergency)),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _chips(emergency
                ? ['Todo', 'Vulnerables', 'Puntos seguros', 'Recursos', 'Apoyo']
                : ['Todo', 'Servicios', 'Favores']),
          ),
          const Positioned(
              left: 0.48,
              top: 0.48,
              child: SizedBox(width: 20, height: 20,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Color(0xFF2F6FE4), shape: BoxShape.circle)))),
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 12, runSpacing: 8, children: [
                    _legend(emergency ? red : navy, emergency ? 'Vulnerables' : 'Servicios'),
                    _legend(emergency ? const Color(0xFF2F6FE4) : amber,
                        emergency ? 'Seguros' : 'Necesitan'),
                    _legend(emergency ? amber : green,
                        emergency ? 'Recursos' : 'Ofrecen'),
                    _legend(const Color(0xFF2F6FE4), 'Tú'),
                  ]),
                  const SizedBox(height: 10),
                  const Row(children: [
                    Icon(Icons.download_done, color: green, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                        child: Text('Mapa de tu zona guardado para usar sin conexión · radio 500 m',
                            style: TextStyle(color: muted, fontSize: 12))),
                  ]),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _publish(BuildContext context) => _scrollPage(
        title: emergency ? 'Reportar en emergencia' : 'Publicar',
        subtitle: emergency
            ? 'La brigada y tus vecinos recibirán tu reporte.'
            : 'Comparte algo con tu comunidad.',
        body: [
          _steps(),
          _choiceCard('Necesito ayuda', 'Pide un favor o préstamo a tus vecinos',
              Icons.back_hand, amber),
          _choiceCard('Ofrezco ayuda', 'Presta, dona, enseña o lleva a alguien',
              Icons.volunteer_activism, green),
          _choiceCard('Ofrezco mi oficio', 'Súmate al directorio de servicios',
              Icons.handyman, const Color(0xFF2F6FE4)),
          if (emergency)
            _choiceCard('Reportar vecino vulnerable', 'Alguien que necesita ayuda',
                Icons.elderly, red),
          const SizedBox(height: 8),
          _card(
            child: const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Detalle (opcional)'),
            ),
          ),
          const SizedBox(height: 10),
          _button(emergency ? 'Enviar reporte' : 'Publicar pedido', emergency ? red : green,
              Icons.send, () => _toast('Tu publicación fue enviada')),
        ],
      );

  Widget _profile(BuildContext context) => _scrollPage(
        title: 'Mi perfil',
        subtitle: 'Tu información y preferencias de Nearby.',
        body: [
          _card(
            child: Row(children: [
              const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFECE8FA),
                  child: Text('MQ',
                      style: TextStyle(color: violet, fontWeight: FontWeight.w900))),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('María Quispe',
                    style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w800)),
                const Text('+51 987 654 321', style: TextStyle(color: muted)),
                const Text('Zona 3 · Las Flores', style: TextStyle(color: muted)),
              ]),
            ]),
          ),
          _setting(Icons.contacts, 'Contactos de confianza',
              '3 personas reciben tu ubicación'),
          _setting(Icons.medical_information, 'Ficha de emergencia',
              'Información para brigadistas'),
          _setting(Icons.dark_mode, 'Tema oscuro', 'Ahorra batería de noche',
              trailing: Switch(value: dark, onChanged: (value) => setState(() => dark = value))),
          _setting(Icons.emergency, 'Modo emergencia', 'Activa el tablero humanitario',
              trailing: Switch(value: emergency, onChanged: (_) => toggleEmergency())),
          _setting(Icons.school, 'Tutorial', 'Aprende tocando la app'),
        ],
      );

  Widget _emergencyList(String title, String subtitle, List<String> entries) =>
      _scrollPage(
        title: title,
        subtitle: subtitle,
        body: entries
            .map((entry) => _card(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(children: [
                    Icon(
                        title == 'Recursos críticos'
                            ? Icons.inventory_2
                            : Icons.diversity_3,
                        color: emergency ? red : green),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(entry,
                            style: TextStyle(
                                color: ink, fontWeight: FontWeight.w800))),
                    const Icon(Icons.chevron_right, color: muted),
                  ]),
                ))
            .toList(),
      );

  Widget _sos(BuildContext context) => Container(
        color: red,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              IconButton(
                  onPressed: () => open('home'),
                  color: Colors.white,
                  icon: const Icon(Icons.close)),
              const Spacer(),
              const Text('Ubicación lista',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
            const Text('Emergencia',
                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
            const Text('Mantén presionado el botón 2 segundos.',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const Spacer(),
            Center(
              child: GestureDetector(
                onLongPress: () {
                  setState(() => emergency = true);
                  open('home');
                  _toast('Alerta enviada a tus vecinos y contactos');
                },
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 3)),
                  child: const Center(
                      child: Text('SOS',
                          style: TextStyle(
                              color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900))),
                ),
              ),
            ),
            const Spacer(),
            const Text('O llama directo',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              _emergencyCall('105', 'Policía', Icons.local_police),
              _emergencyCall('116', 'Bomberos', Icons.local_fire_department),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _emergencyCall('106', 'SAMU', Icons.medical_services),
              _emergencyCall('115', 'Defensa Civil', Icons.shield),
            ]),
          ],
        ),
      );

  Widget _scrollPage({required String title, required String subtitle, required List<Widget> body}) =>
      ListView(
        padding: const EdgeInsets.only(bottom: 22),
        children: [
          _heading('', title, subtitle: subtitle),
          ...body,
        ],
      );

  Widget _heading(String eyebrow, String title, {String? subtitle}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (eyebrow.isNotEmpty)
            Text(eyebrow, style: const TextStyle(color: muted, fontSize: 15)),
          Text(title,
              style: TextStyle(color: ink, fontSize: 24, fontWeight: FontWeight.w900)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle, style: const TextStyle(color: muted)),
            ),
        ]),
      );

  Widget _sectionTitle(String title, {String? action, VoidCallback? onAction}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900))),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action, style: const TextStyle(color: green))),
        ]),
      );

  Widget _quickGrid(BuildContext context, List<_Quick> items) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.65,
          children: items.map((item) => InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(18),
            child: _card(
              child: Row(children: [
                Icon(item.icon, color: item.color, size: 27),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 2,
                        style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 12)),
                    Text(item.subtitle, maxLines: 2,
                        style: const TextStyle(color: muted, fontSize: 10)),
                  ],
                )),
              ]),
            ),
          )).toList(),
        ),
      );

  Widget _horizontalServices() => SizedBox(
        height: 142,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            _miniService('Julio Quispe', 'Gasfitería', Icons.plumbing, green),
            _miniService('Luis Mendoza', 'Electricidad', Icons.electrical_services, amber),
            _miniService('Rosa Flores', 'Clases', Icons.school, violet),
          ],
        ),
      );

  Widget _miniService(String name, String job, IconData icon, Color color) => Container(
        width: 130,
        margin: const EdgeInsets.only(right: 8),
        child: _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(backgroundColor: color.withOpacity(.14),
                child: Icon(icon, color: color)),
            const SizedBox(height: 6),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 12)),
            Text(job, style: const TextStyle(color: muted, fontSize: 11)),
            const Text('✓ 48', style: TextStyle(color: green, fontWeight: FontWeight.w800)),
          ]),
        ),
      );

  Widget _serviceCard(String name, String job, IconData icon, String votes,
          String distance, String price, Color color) =>
      _card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(children: [
          CircleAvatar(radius: 27, backgroundColor: color.withOpacity(.14),
              child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
            Text(job, style: const TextStyle(color: muted)),
            Text('$distance · $price', style: TextStyle(color: ink, fontSize: 12)),
          ])),
          Column(children: [
            Text(votes, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
            const Text('Visto Bueno', style: TextStyle(color: muted, fontSize: 10)),
          ]),
        ]),
      );

  Widget _postCard(String title, String user, IconData icon, String time, Color color) =>
      _card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(backgroundColor: color.withOpacity(.14), child: Icon(icon, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$user · $time', style: const TextStyle(color: muted, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right, color: muted),
        ]),
      );

  Widget _stats() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _stat('18', 'Reportes'), _stat('3', 'Por atender'), _stat('64', 'A salvo'),
        ]),
      );

  Widget _stat(String number, String label) => Expanded(
        child: _card(
          margin: const EdgeInsets.only(right: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(number, style: TextStyle(color: ink, fontSize: 23, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: muted, fontSize: 11)),
          ]),
        ),
      );

  Widget _chips(List<String> labels) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        scrollDirection: Axis.horizontal,
        child: Row(children: labels.map((label) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: FilterChip(
            label: Text(label),
            selected: label == labels.first,
            onSelected: (_) {},
            selectedColor: emergency ? const Color(0xFFFCE5E8) : const Color(0xFFDDF3EC),
          ),
        )).toList()),
      );

  Widget _steps() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(children: [
          _step('1', true), _step('2', false), _step('3', false),
        ]),
      );

  Widget _step(String label, bool active) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Paso $label', style: TextStyle(color: active ? ink : muted, fontSize: 11,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Container(height: 5, decoration: BoxDecoration(
                color: active ? green : line, borderRadius: BorderRadius.circular(4))),
          ]),
        ),
      );

  Widget _choiceCard(String title, String subtitle, IconData icon, Color color) =>
      _card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(children: [
          CircleAvatar(radius: 28, backgroundColor: color.withOpacity(.14),
              child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: ink, fontWeight: FontWeight.w900)),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right, color: muted),
        ]),
      );

  Widget _setting(IconData icon, String title, String subtitle, {Widget? trailing}) =>
      _card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(icon, color: muted),
          title: Text(title, style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: trailing ?? const Icon(Icons.chevron_right, color: muted),
        ),
      );

  Widget _callChip(String number, String label, IconData icon) => InkWell(
        onTap: () => _toast('Llamando a $label · $number'),
        child: Column(children: [
          Icon(icon, color: emergency ? Colors.white : navy, size: 22),
          Text(number, style: TextStyle(color: emergency ? Colors.white : navy,
              fontWeight: FontWeight.w900, fontSize: 12)),
          Text(label, style: TextStyle(color: emergency ? Colors.white70 : muted, fontSize: 10)),
        ]),
      );

  Widget _emergencyCall(String number, String label, IconData icon) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => _toast('Llamando a $label · $number'),
            icon: Icon(icon, size: 18),
            label: Text('$number\n$label', textAlign: TextAlign.left),
            style: ElevatedButton.styleFrom(
                foregroundColor: navy, backgroundColor: Colors.white, alignment: Alignment.centerLeft),
          ),
        ),
      );

  Widget _brandMark() => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            color: surface, border: Border.all(color: line),
            borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.handshake, color: green, size: 25),
      );

  Widget _pillButton(String label, Color color, IconData icon, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            Icon(icon, color: Colors.white, size: 18),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ]),
        ),
      );

  Widget _button(String label, Color color, IconData icon, VoidCallback onTap) =>
      SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 19),
          label: Text(label),
          style: ElevatedButton.styleFrom(
              backgroundColor: color, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
        ),
      );

  Widget _outlineButton(String label, Color color, IconData icon, VoidCallback onTap) =>
      SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 19),
          label: Text(label),
          style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
        ),
      );

  Widget _card({required Widget child, EdgeInsets? margin, EdgeInsets? padding}) => Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: surface,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(16)),
        child: child,
      );

  Widget _legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: muted, fontSize: 11)),
      ]);

  void _showEmergencyOptions(BuildContext context) => showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Modo emergencia activo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _button('Volver al modo normal', green, Icons.verified_user, () {
                Navigator.pop(context);
                toggleEmergency();
              }),
            ]),
          ),
        ),
      );

  void _showResources(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _modalList('Recursos críticos', [
          'Agua · Hay 14 · Faltan 9',
          'Víveres · Hay 8 · Faltan 12',
          'Botiquín y medicinas · Hay 5 · Faltan 7',
          'Carga de celular · Hay 6 · Faltan 15',
          'Refugio o techo · Hay 3 · Faltan 4',
        ]),
      );

  void _showSupport(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _modalList('Grupos de apoyo', [
          'Brigada de primeros auxilios Z3 · 12 vecinos',
          'Electricistas de guardia · 4 vecinos',
          'Evaluación de viviendas · 5 vecinos',
          'Olla común Las Flores · 20 vecinos',
          'Apoyo psicológico · 6 vecinos',
        ]),
      );

  void _showBoard(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _modalList('Tablero humanitario', [
          'Adulta mayor sola · Pendiente',
          'Persona herida · En camino',
          'Persona con discapacidad · En camino',
          'Niños sin un adulto · Atendido',
        ]),
      );

  Widget _modalList(String title, List<String> entries) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ...entries.map((entry) => ListTile(
                  leading: const Icon(Icons.circle, color: red, size: 12),
                  title: Text(entry),
                )),
          ]),
        ),
      );
}

class _Quick {
  const _Quick(this.title, this.subtitle, this.icon, this.color, this.onTap);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.dark, required this.emergency});
  final bool dark;
  final bool emergency;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = dark ? const Color(0xFF111D31) : const Color(0xFFE6EDEF);
    final street = Paint()
      ..color = dark ? const Color(0xFF22324F) : Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final park = Paint()..color = dark ? const Color(0xFF143A31) : const Color(0xFFCBEBDD);
    canvas.drawRect(Offset.zero & size, bg);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * .12, size.height * .42, size.width * .3, size.height * .2),
            const Radius.circular(14)),
        park);
    for (final y in [0.18, 0.36, 0.64, 0.84]) {
      canvas.drawLine(Offset(0, size.height * y),
          Offset(size.width, size.height * y), street);
    }
    for (final x in [.12, .4, .68, .92]) {
      canvas.drawLine(Offset(size.width * x, 0),
          Offset(size.width * x, size.height), street);
    }
    _pin(canvas, size, .28, .3, navy, Icons.plumbing);
    _pin(canvas, size, .72, .24, amber, Icons.electrical_services);
    _pin(canvas, size, .64, .7, green, Icons.school);
    _pin(canvas, size, .4, .62, emergency ? red : amber, Icons.build);
    _pin(canvas, size, .8, .46, emergency ? violet : green, Icons.directions_car);
  }

  void _pin(Canvas canvas, Size size, double x, double y, Color color, IconData icon) {
    final center = Offset(size.width * x, size.height * y);
    canvas.drawCircle(center, 20, Paint()..color = color);
    final painter = TextPainter(
      text: TextSpan(text: String.fromCharCode(icon.codePoint),
          style: TextStyle(fontFamily: icon.fontFamily, color: Colors.white, fontSize: 20)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.dark != dark || oldDelegate.emergency != emergency;
}
