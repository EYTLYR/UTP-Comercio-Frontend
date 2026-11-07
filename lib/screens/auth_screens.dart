import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

Widget _buildPdots(int currentStep, NearbyThemeData theme) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
    child: Row(
      children: [1, 2, 3].map((step) {
        final isOn = step <= currentStep;
        return Expanded(
          child: Container(
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isOn ? theme.primary : theme.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

// --- 1. Login Screen ---
class LoginScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const LoginScreen({super.key, required this.state, required this.theme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _phoneController;
  String _err = '';

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.state.phoneDraft);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    widget.state.phoneDraft = digits;
    setState(() {
      if (digits.isNotEmpty && !digits.startsWith('9')) {
        _err = 'Los celulares en Perú empiezan con 9';
      } else {
        _err = '';
      }
    });
  }

  bool get _isValid => RegExp(r'^9\d{8}$').hasMatch(widget.state.phoneDraft);

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: theme.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.smartphone, color: theme.primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Ingresa con tu celular',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: theme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Te enviaremos un código por SMS. No necesitas correo ni contraseña.',
            style: TextStyle(color: theme.muted, fontSize: 14),
          ),
          const SizedBox(height: 24),

          Text(
            'Número de celular',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: theme.ink,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border.all(
                color: _err.isNotEmpty ? NearbyColors.sos : theme.line,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    const Text('🇵🇪', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '+51',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: theme.muted,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1.5,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: theme.line,
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    onChanged: _onChanged,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: theme.ink,
                      letterSpacing: 1.2,
                    ),
                    decoration: const InputDecoration(
                      hintText: '987 654 321',
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_err.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error, color: NearbyColors.sos, size: 16),
                const SizedBox(width: 6),
                Text(
                  _err,
                  style: const TextStyle(
                    color: NearbyColors.sos,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isValid
                ? () {
                    state.toast(
                      'Código enviado al +51 ${state.phoneDraft}',
                      icon: 'sms',
                    );
                    state.go('otp');
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.btnBg,
              foregroundColor: theme.btnInk,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(Icons.sms, color: theme.primary, size: 20),
            label: const Text(
              'Enviar código',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Al continuar aceptas los términos y la política de privacidad de Nearby.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.muted, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. OTP Screen ---
class OtpScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const OtpScreen({super.key, required this.state, required this.theme});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsLeft = 30;
  Timer? _timer;
  String _err = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _checkCode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _err = '');
      return;
    }

    if (code == '123456') {
      setState(() {
        _isSuccess = true;
        _err = '';
      });
      Timer(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        widget.state.userPhone = widget.state.phoneDraft.isNotEmpty
            ? widget.state.phoneDraft
            : '987654321';
        widget.state.regName = '';
        widget.state.regLoc = null;
        widget.state.go('registro');
      });
    } else {
      setState(() {
        _err = 'Código incorrecto. Revisa el SMS e inténtalo otra vez.';
        _isSuccess = false;
      });
    }
  }

  void _fillDemo() {
    const demo = '123456';
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = demo[i];
    }
    _checkCode();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: theme.infoSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.sms, color: theme.info, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Escribe el código',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: theme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            children: [
              Text(
                'Lo enviamos por SMS al +51 ${state.phoneDraft.isNotEmpty ? state.phoneDraft : state.userPhone}. ',
                style: TextStyle(color: theme.muted, fontSize: 13.5),
              ),
              InkWell(
                onTap: () => state.back(),
                child: Text(
                  'Cambiar',
                  style: TextStyle(
                    color: theme.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 6 OTP boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              return SizedBox(
                width: 48,
                height: 58,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _isSuccess ? theme.primary : theme.ink,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _isSuccess ? theme.primarySoft : theme.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _err.isNotEmpty ? NearbyColors.sos : theme.line,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.primary, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && i < 5) {
                      _focusNodes[i + 1].requestFocus();
                    } else if (val.isEmpty && i > 0) {
                      _focusNodes[i - 1].requestFocus();
                    }
                    _checkCode();
                  },
                ),
              );
            }),
          ),
          if (_err.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error, color: NearbyColors.sos, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _err,
                    style: const TextStyle(
                      color: NearbyColors.sos,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Demo hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.infoSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: theme.info, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Prototipo: el código es 123456',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: NearbyColors.info,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _fillDemo,
                  child: const Text(
                    'Usarlo',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      color: NearbyColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: _secondsLeft == 0
                ? () {
                    setState(() => _secondsLeft = 30);
                    _startTimer();
                    state.toast('Te enviamos un nuevo código', icon: 'sms');
                  }
                : null,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              _secondsLeft > 0
                  ? 'Reenviar código en 0:${_secondsLeft.toString().padLeft(2, "0")}'
                  : 'Reenviar SMS',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),

          const Spacer(),
          Center(
            child: Text(
              'Si el SMS llega a este mismo teléfono, el código se completa solo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. Registro Screen ---
class RegistroScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const RegistroScreen({super.key, required this.state, required this.theme});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.regName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      widget.state.regName.trim().length > 1 && widget.state.regLoc == 'ok';

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;

    return Column(
      children: [
        _buildPdots(1, theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            children: [
              Text(
                'Cuéntanos de ti',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Así tus vecinos sabrán quién eres.',
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
              const SizedBox(height: 20),

              Text(
                'Tu nombre',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.ink,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(color: theme.line, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: theme.muted, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        onChanged: (val) {
                          state.regName = val;
                          setState(() {});
                        },
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.ink,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Ej. María Quispe',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                '¿Dónde vives?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.ink,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 8),

              if (state.regLoc == 'loading')
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border.all(color: theme.line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buscando tu ubicación…',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: theme.ink,
                              ),
                            ),
                            Text(
                              'Usamos el GPS solo para ubicar tu zona',
                              style: TextStyle(
                                color: theme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (state.regLoc == 'ok')
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border.all(color: theme.line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.where_to_vote,
                          color: theme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jr. Las Flores 245, SJL',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: theme.ink,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Tu zona: Zona 3 · Las Flores',
                              style: TextStyle(
                                color: theme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          state.regLoc = 'loading';
                          setState(() {});
                          Timer(const Duration(milliseconds: 1200), () {
                            if (!mounted) return;
                            state.regLoc = 'ok';
                            setState(() {});
                          });
                        },
                        child: Text(
                          'Cambiar',
                          style: TextStyle(
                            color: theme.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    state.regLoc = 'loading';
                    setState(() {});
                    Timer(const Duration(milliseconds: 1300), () {
                      if (!mounted) return;
                      state.regLoc = 'ok';
                      setState(() {});
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.ink,
                    side: BorderSide(color: theme.line, width: 1.5),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(Icons.my_location, color: theme.primary, size: 20),
                  label: const Text(
                    'Usar mi ubicación actual',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(
                    color: theme.line,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock, color: theme.info, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tus vecinos solo ven tu nombre y tu zona, nunca tu dirección exacta.',
                        style: TextStyle(color: theme.muted, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Footer button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border(top: BorderSide(color: theme.line)),
          ),
          child: ElevatedButton.icon(
            onPressed: _canContinue
                ? () {
                    state.userName = state.regName.trim();
                    state.contacts = [];
                    state.contactsMode = 'setup';
                    state.perms = {
                      'loc': false,
                      'notif': false,
                      'sms': false,
                      'ai': false,
                    };
                    state.go('contactos');
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.btnBg,
              foregroundColor: theme.btnInk,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const SizedBox.shrink(),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Continuar',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: theme.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- 4. Contactos Screen ---
class ContactosScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const ContactosScreen({super.key, required this.state, required this.theme});

  @override
  State<ContactosScreen> createState() => _ContactosScreenState();
}

class _ContactosScreenState extends State<ContactosScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final isSetup = state.contactsMode == 'setup';

    final filtered = kAllContacts
        .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Column(
      children: [
        if (isSetup) _buildPdots(2, theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
            children: [
              Text(
                '¿A quién avisamos si usas el SOS?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige hasta 3 personas. Recibirán tu ubicación por SMS, incluso sin internet.',
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Search bar
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(color: theme.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: theme.muted, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _search = val),
                        decoration: const InputDecoration(
                          hintText: 'Buscar en tus contactos',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contacts Card List
              Container(
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(color: theme.line),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: filtered.map((c) {
                    final isSelected = state.contacts.contains(c.id);
                    return InkWell(
                      onTap: () {
                        if (isSelected) {
                          state.contacts.remove(c.id);
                        } else if (state.contacts.length >= 3) {
                          state.toast(
                            'Máximo 3 contactos. Quita uno para elegir otro.',
                            icon: 'info',
                          );
                          return;
                        } else {
                          state.contacts.add(c.id);
                        }
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.violetSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                c.icon,
                                color: theme.violet,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: theme.ink,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    c.phone,
                                    style: TextStyle(
                                      color: theme.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? theme.primary
                                      : theme.line,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Footer buttons
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border(top: BorderSide(color: theme.line)),
          ),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (isSetup) {
                    state.go('permisos');
                  } else {
                    state.back();
                    state.toast(
                      'Contactos de confianza guardados',
                      icon: 'check_circle',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.btnBg,
                  foregroundColor: theme.btnInk,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(Icons.check, color: theme.primary, size: 20),
                label: Text(
                  '${isSetup ? "Continuar" : "Guardar"} · ${state.contacts.length} de 3',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isSetup) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => state.go('permisos'),
                  child: Text(
                    'Lo hago después',
                    style: TextStyle(
                      color: theme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// --- 5. Permisos Screen ---
class PermisosScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const PermisosScreen({super.key, required this.state, required this.theme});

  @override
  State<PermisosScreen> createState() => _PermisosScreenState();
}

class _PermisosScreenState extends State<PermisosScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;

    return Column(
      children: [
        _buildPdots(3, theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
            children: [
              Text(
                'Para cuidarte mejor',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nearby necesita estos permisos. Puedes cambiarlos cuando quieras.',
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
              const SizedBox(height: 20),

              _permRow(
                'loc',
                Icons.my_location,
                theme.infoSoft,
                theme.info,
                'Ubicación',
                'Para enviar tu ubicación en un SOS y mostrarte lo que hay cerca',
              ),
              _permRow(
                'notif',
                Icons.notifications_active,
                theme.sosSoft,
                theme.sos,
                'Notificaciones',
                'Para avisarte si un vecino cercano pide ayuda',
              ),
              _permRow(
                'sms',
                Icons.sms,
                theme.primarySoft,
                theme.primary,
                'Enviar SMS',
                'Para que el SOS llegue a tus contactos aunque no tengas internet',
              ),
              _permRow(
                'ai',
                Icons.auto_awesome,
                theme.violetSoft,
                theme.violet,
                'Red de rescate con IA (opcional)',
                'Usa lo que ofreces en el muro para sugerirte si un vecino necesita ayuda. Puedes verlo y borrarlo en tu perfil',
              ),
            ],
          ),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border(top: BorderSide(color: theme.line)),
          ),
          child: ElevatedButton(
            onPressed: () => state.go('listo', reset: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.btnBg,
              foregroundColor: theme.btnInk,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Continuar',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: theme.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _permRow(
    String key,
    IconData icon,
    Color softColor,
    Color mainColor,
    String title,
    String desc,
  ) {
    final isAllowed = widget.state.perms[key] ?? false;
    final theme = widget.theme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: theme.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: mainColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.ink,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(color: theme.muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isAllowed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.primaryDark, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Listo',
                    style: TextStyle(
                      color: theme.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                widget.state.perms[key] = true;
                if (key == 'ai') widget.state.aiConsent = true;
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.btnBg,
                foregroundColor: theme.btnInk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Permitir',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

// --- 6. Listo Screen ---
class ListoScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const ListoScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: theme.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_user, color: theme.primary, size: 54),
          ),
          const SizedBox(height: 20),
          Text(
            '¡Te damos la bienvenida, ${state.firstName}!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: theme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tu cuenta está lista. Un delegado de la Zona 3 confirmará que eres vecina o vecino para darte la insignia de verificado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.muted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Tutorial highlight card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border.all(color: theme.line),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.touch_app, color: theme.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aprende tocando la app',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.ink,
                        ),
                      ),
                      Text(
                        'Te guiamos sobre las pantallas reales. Dura 1 minuto.',
                        style: TextStyle(color: theme.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          ElevatedButton.icon(
            onPressed: () {
              state.go('home', reset: true);
              state.startTour('main');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.btnBg,
              foregroundColor: theme.btnInk,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(Icons.play_arrow, color: theme.primary, size: 22),
            label: const Text(
              'Empezar el tutorial interactivo',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => state.go('home', reset: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.ink,
              side: BorderSide(color: theme.line),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Ya sé usarla, ir al inicio',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
