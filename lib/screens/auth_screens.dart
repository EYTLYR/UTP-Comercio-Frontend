import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
            onPressed: _isValid && !state.busy
                ? () async {
                    if (!state.useApi) {
                      state.toast(
                        'Código enviado al +51 ${state.phoneDraft}',
                        icon: 'sms',
                      );
                      state.go('otp');
                      return;
                    }
                    if (await state.requestOtp()) state.go('otp');
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

  Future<void> _checkCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _err = '');
      return;
    }

    if (widget.state.useApi) {
      final error = await widget.state.verifyOtp(code);
      if (!mounted) return;
      if (error != null) {
        setState(() {
          _err = error;
          _isSuccess = false;
        });
        return;
      }
      setState(() {
        _isSuccess = true;
        _err = '';
      });
      Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        if (widget.state.regPending) {
          widget.state.regName = '';
          widget.state.regLoc = null;
          widget.state.go('registro');
        } else {
          widget.state.go('home', reset: true);
          widget.state.toast(
            'Hola de nuevo, ${widget.state.firstName}',
            icon: 'waving_hand',
          );
        }
      });
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

          TextButton.icon(
            onPressed: _secondsLeft == 0
                ? () async {
                    setState(() => _secondsLeft = 30);
                    _startTimer();
                    if (state.useApi) {
                      await state.requestOtp();
                    } else {
                      state.toast('Te enviamos un nuevo código', icon: 'sms');
                    }
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
    if (widget.state.regLoc == null) {
      widget.state.regLoc = 'ok';
      widget.state.regLat ??= -11.9790;
      widget.state.regLng ??= -77.0030;
      if (widget.state.regAddress.isEmpty) {
        widget.state.regAddress = 'Jr. Las Flores 245, SJL';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      widget.state.regName.trim().length > 1 && widget.state.regLoc == 'ok';

  Future<void> _launchGoogleMaps(double lat, double lng, {String? label}) async {
    final query = Uri.encodeComponent(
      label != null && label.isNotEmpty ? '$label, Lima' : '$lat,$lng',
    );
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _openLocationPickerModal(BuildContext context) {
    final state = widget.state;
    final theme = widget.theme;
    double tempLat = state.regLat ?? -11.9790;
    double tempLng = state.regLng ?? -77.0030;
    final addrController = TextEditingController(text: state.regAddress);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.map,
                          color: Color(0xFF1A73E8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selecciona tu ubicación',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: theme.ink,
                              ),
                            ),
                            Text(
                              'Conéctate a tu vecindario con Google Maps',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Campo de dirección
                  TextField(
                    controller: addrController,
                    decoration: InputDecoration(
                      labelText: 'Dirección o referencia',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Atajos de zonas
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(
                          Icons.place,
                          size: 16,
                          color: Color(0xFF1A73E8),
                        ),
                        label: const Text(
                          'Jr. Las Flores (SJL)',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempLat = -11.9790;
                            tempLng = -77.0030;
                            addrController.text = 'Jr. Las Flores 245, SJL';
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.school,
                          size: 16,
                          color: Color(0xFFE37400),
                        ),
                        label: const Text(
                          'UTP Sede SJL',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempLat = -11.9892;
                            tempLng = -77.0062;
                            addrController.text = 'UTP Sede San Juan de Lurigancho';
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.my_location,
                          size: 16,
                          color: Color(0xFF1E8E3E),
                        ),
                        label: const Text(
                          'Mi GPS actual',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final pos = await state.location.current();
                          setModalState(() {
                            tempLat = pos.lat;
                            tempLng = pos.lng;
                            addrController.text = pos.real
                                ? 'Ubicación actual (${pos.lat.toStringAsFixed(4)}, ${pos.lng.toStringAsFixed(4)})'
                                : 'Jr. Las Flores 245, SJL';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tarjeta Google Maps
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.explore,
                          color: Color(0xFF1A73E8),
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coordenadas del mapa',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: theme.ink,
                                ),
                              ),
                              Text(
                                'Lat: ${tempLat.toStringAsFixed(4)}, Lng: ${tempLng.toStringAsFixed(4)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _launchGoogleMaps(
                            tempLat,
                            tempLng,
                            label: addrController.text,
                          ),
                          icon: const Icon(Icons.open_in_new, size: 15),
                          label: const Text(
                            'Google Maps',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A73E8),
                            side: const BorderSide(color: Color(0xFF1A73E8)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: () {
                      state.regLat = tempLat;
                      state.regLng = tempLng;
                      state.regAddress = addrController.text.trim().isNotEmpty
                          ? addrController.text.trim()
                          : 'Jr. Las Flores 245, SJL';
                      state.regLoc = 'ok';
                      state.refresh();
                      Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirmar ubicación',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
              else if (state.regLoc == 'ok') ...[
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
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.where_to_vote,
                          color: Color(0xFF1A73E8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.regAddress,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: theme.ink,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Tu zona: ${state.zoneName}',
                              style: TextStyle(
                                color: theme.muted,
                                fontSize: 12,
                              ),
                            ),
                            if (state.regLat != null && state.regLng != null)
                              Text(
                                'GPS: ${state.regLat!.toStringAsFixed(4)}, ${state.regLng!.toStringAsFixed(4)}',
                                style: TextStyle(
                                  color: theme.muted.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openLocationPickerModal(context),
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
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      final lat = state.regLat ?? -11.9790;
                      final lng = state.regLng ?? -77.0030;
                      _launchGoogleMaps(lat, lng, label: state.regAddress);
                    },
                    icon: const Icon(Icons.open_in_new, size: 15, color: Color(0xFF1A73E8)),
                    label: const Text(
                      'Ver ubicación en Google Maps',
                      style: TextStyle(
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ] else
                Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openLocationPickerModal(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A73E8),
                        side: const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.map, size: 20),
                      label: const Text(
                        'Elegir en Google Maps o escribir dirección',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await state.locateForRegistration();
                        if (mounted) setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.ink,
                        side: BorderSide(color: theme.line, width: 1.5),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(Icons.my_location, color: theme.primary, size: 20),
                      label: const Text(
                        'Detectar con GPS actual',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
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
            onPressed: _canContinue && !state.busy
                ? () async {
                    state.userName = state.regName.trim();
                    if (!await state.completeRegistration()) return;
                    if (!state.useApi) state.contacts = [];
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

  Future<void> _addContactDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nuevo contacto de confianza'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 9,
                decoration: InputDecoration(
                  labelText: 'Celular (9 dígitos)',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final e = widget.state.addContact(
                  nameCtrl.text,
                  phoneCtrl.text,
                );
                if (e != null) {
                  setLocal(() => error = e);
                  return;
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final isSetup = state.contactsMode == 'setup';

    final filtered = state.contactBook
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
              const SizedBox(height: 12),
              if (state.connected)
                OutlinedButton.icon(
                  onPressed: () => _addContactDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.ink,
                    side: BorderSide(color: theme.line, width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(Icons.person_add, color: theme.primary, size: 20),
                  label: const Text(
                    'Agregar contacto con su celular',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              const SizedBox(height: 12),

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
                onPressed: () async {
                  await state.saveContacts();
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
                if (key == 'ai') widget.state.setAiConsent(true);
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
            'Tu cuenta está lista. Un delegado de tu zona confirmará que eres vecina o vecino para darte la insignia de verificado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.muted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),

          const Spacer(),

          ElevatedButton.icon(
            onPressed: () => state.go('home', reset: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.btnBg,
              foregroundColor: theme.btnInk,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(Icons.home, color: theme.primary, size: 22),
            label: const Text(
              'Ir al inicio',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
