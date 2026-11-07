import 'package:flutter/material.dart';

import '../services/startup_permissions.dart';

class PermissionIntro extends StatelessWidget {
  final StartupPermissions permissions;
  const PermissionIntro({super.key, required this.permissions});
  static const descriptions = {
    AppAccess.camera: (
      'Cámara',
      'Adjuntar fotos a pedidos y reportes.',
      Icons.camera_alt_outlined,
    ),
    AppAccess.location: (
      'Ubicación',
      'Encontrar ayuda y compartir tu posición en una alerta.',
      Icons.location_on_outlined,
    ),
    AppAccess.contacts: (
      'Contactos',
      'Elegir a tus contactos de confianza.',
      Icons.contacts_outlined,
    ),
    AppAccess.phone: (
      'Llamadas',
      'Contactar a vecinos y servicios de emergencia.',
      Icons.call_outlined,
    ),
    AppAccess.nearby: (
      'Dispositivos cercanos',
      'Encontrar equipos cercanos compatibles.',
      Icons.devices_other,
    ),
    AppAccess.bluetooth: (
      'Bluetooth',
      'Conectar con dispositivos compatibles.',
      Icons.bluetooth,
    ),
    AppAccess.photos: (
      'Galería',
      'Seleccionar imágenes para tus publicaciones.',
      Icons.photo_library_outlined,
    ),
  };
  static String status(AccessState state) => switch (state) {
    AccessState.pending => 'Sin solicitar',
    AccessState.granted => 'Permitido',
    AccessState.limited => 'Acceso limitado',
    AccessState.denied => 'No permitido',
    AccessState.blocked => 'Revisar en ajustes',
    AccessState.onUse => 'Al usar esta función',
    AccessState.unavailable => 'No disponible en esta plataforma',
    AccessState.notRequired => 'No requiere permiso del sistema',
  };
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black54,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Prepara Nearby',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Te pediremos los accesos disponibles en tu dispositivo. Puedes rechazarlos y seguir usando la app. Para completar el código SMS, Android solicitará tu consentimiento para leer únicamente ese mensaje durante el ingreso.',
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: descriptions.entries.map((entry) {
                          final info = entry.value;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(info.$3),
                            title: Text(
                              info.$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${info.$2}\n${status(permissions.states[entry.key]!)}',
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (permissions.error != null)
                    Text(
                      permissions.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: permissions.busy
                        ? null
                        : permissions.requested
                        ? permissions.dismiss
                        : permissions.request,
                    child: Text(
                      permissions.busy
                          ? 'Solicitando permisos…'
                          : permissions.requested
                          ? 'Continuar'
                          : 'Permitir y continuar',
                    ),
                  ),
                  if (!permissions.requested)
                    TextButton(
                      onPressed: permissions.busy ? null : permissions.dismiss,
                      child: const Text('Ahora no'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
