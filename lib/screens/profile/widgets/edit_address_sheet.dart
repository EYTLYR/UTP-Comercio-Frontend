import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../state/app_state.dart';
import '../../../theme/nearby_theme.dart';
import '../../../widgets/common_widgets.dart';

/// Modal bottom sheet to edit home address, reference coordinates, and GPS detection.
void showEditAddressSheet(BuildContext context, AppState state) {
  double tempLat = state.regLat ?? -11.9790;
  double tempLng = state.regLng ?? -77.0030;
  final addrController = TextEditingController(text: state.userAddress);
  bool isDetecting = false;
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
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
                      color: NearbyColors.lineStrong,
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
                        color: NearbyColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_location_alt,
                        color: NearbyColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Editar dirección de tu hogar',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Actualiza tu dirección o muévete con GPS',
                            style: TextStyle(
                              fontSize: 12,
                              color: NearbyColors.muted,
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
                    labelText: 'Dirección o referencia exacta',
                    hintText: 'Ej. Jr. Las Flores 245, SJL',
                    prefixIcon: const Icon(Icons.home_outlined),
                    suffixIcon: addrController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setModalState(() => addrController.clear());
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setModalState(() {}),
                ),
                const SizedBox(height: 12),

                // Atajos y detección
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: isDetecting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.my_location,
                              size: 16,
                              color: Color(0xFF1E8E3E),
                            ),
                      label: Text(
                        isDetecting ? 'Detectando GPS…' : 'Usar ubicación GPS',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: isDetecting
                          ? null
                          : () async {
                              setModalState(() => isDetecting = true);
                              try {
                                final pos = await state.location.current();
                                tempLat = pos.lat;
                                tempLng = pos.lng;

                                try {
                                  final uri = Uri.parse(
                                    'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.lat}&lon=${pos.lng}&zoom=18&addressdetails=1',
                                  );
                                  final res = await http.get(
                                    uri,
                                    headers: {'User-Agent': 'UTP-Comercio/1.0'},
                                  ).timeout(const Duration(seconds: 4));
                                  if (res.statusCode == 200) {
                                    final data =
                                        jsonDecode(res.body) as Map<String, dynamic>;
                                    final addr =
                                        data['address'] as Map<String, dynamic>?;
                                    if (addr != null) {
                                      final road = addr['road'] as String?;
                                      final num = addr['house_number'] as String?;
                                      final suburb = addr['suburb'] as String? ??
                                          addr['neighbourhood'] as String?;
                                      final district = addr['city_district'] as String? ??
                                          addr['city'] as String?;
                                      if (road != null) {
                                        addrController.text = num != null
                                            ? '$road $num${district != null ? ', $district' : ''}'
                                            : '$road${suburb != null ? ', $suburb' : ''}';
                                      } else if (district != null) {
                                        addrController.text = district;
                                      }
                                    }
                                  }
                                } catch (_) {
                                  if (pos.city != null && pos.city!.isNotEmpty) {
                                    addrController.text = pos.region != null
                                        ? '${pos.city}, ${pos.region}'
                                        : pos.city!;
                                  }
                                }
                              } catch (_) {
                                state.toast('No se pudo obtener el GPS', icon: 'error');
                              } finally {
                                setModalState(() => isDetecting = false);
                              }
                            },
                    ),
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
                        Icons.place,
                        size: 16,
                        color: Color(0xFF1A73E8),
                      ),
                      label: const Text(
                        'J. L. Ortiz (Chiclayo)',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        setModalState(() {
                          tempLat = -6.7562;
                          tempLng = -79.8398;
                          addrController.text = 'Calle Los Zapallos, José Leonardo Ortiz';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(
                        Icons.place,
                        size: 16,
                        color: Color(0xFF1A73E8),
                      ),
                      label: const Text(
                        'Chiclayo (Lambayeque)',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        setModalState(() {
                          tempLat = -6.7701;
                          tempLng = -79.8550;
                          addrController.text = 'Chiclayo, Lambayeque';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tarjeta de coordenadas
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NearbyColors.muted.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: NearbyColors.muted.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.explore,
                        color: Color(0xFF1A73E8),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Coordenadas de referencia',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Lat: ${tempLat.toStringAsFixed(4)}, Lng: ${tempLng.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: NearbyColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final query = Uri.encodeComponent(
                            addrController.text.isNotEmpty
                                ? '${addrController.text}, Lima'
                                : '$tempLat,$tempLng',
                          );
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$query',
                          );
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text(
                          'Maps',
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

                PressableScale(
                  scale: 0.98,
                  onTap: isSaving
                      ? null
                      : () async {
                          final text = addrController.text.trim();
                          if (text.isEmpty) {
                            state.toast(
                              'Ingresa una dirección o referencia',
                              icon: 'warning',
                            );
                            return;
                          }
                          setModalState(() => isSaving = true);
                          final ok = await state.updateUserLocation(
                            address: text,
                            lat: tempLat,
                            lng: tempLng,
                          );
                          setModalState(() => isSaving = false);
                          if (ok) {
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            state.toast(
                              'Dirección guardada correctamente',
                              icon: 'check_circle',
                            );
                          }
                        },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: NearbyColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: NearbyColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar dirección',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
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

