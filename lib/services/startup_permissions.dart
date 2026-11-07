import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum AppAccess { camera, location, contacts, phone, nearby, bluetooth, photos }

enum AccessState {
  pending,
  granted,
  limited,
  denied,
  blocked,
  onUse,
  unavailable,
  notRequired,
}

abstract class AccessBackend {
  Future<Map<AppAccess, AccessState>> requestAll();
}

abstract class PermissionMemory {
  Future<bool> hasSeenIntro();
  Future<void> markSeen();
}

class DevicePermissionMemory implements PermissionMemory {
  SharedPreferencesAsync get _preferences => SharedPreferencesAsync();
  @override
  Future<bool> hasSeenIntro() async =>
      await _preferences.getBool('permission_intro_seen_v1') ?? false;
  @override
  Future<void> markSeen() =>
      _preferences.setBool('permission_intro_seen_v1', true);
}

class DeviceAccessBackend implements AccessBackend {
  static AccessState _convert(PermissionStatus status) {
    if (status.isGranted) return AccessState.granted;
    if (status.isLimited || status.isProvisional) return AccessState.limited;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return AccessState.blocked;
    }
    return AccessState.denied;
  }

  Future<AccessState> _request(Permission permission) async {
    try {
      return _convert(await permission.request());
    } on PlatformException {
      return AccessState.unavailable;
    } on UnsupportedError {
      return AccessState.unavailable;
    } on MissingPluginException {
      return AccessState.unavailable;
    }
  }

  @override
  Future<Map<AppAccess, AccessState>> requestAll() async {
    final result = {
      for (final access in AppAccess.values) access: AccessState.unavailable,
    };
    if (kIsWeb) {
      result[AppAccess.camera] = await _request(Permission.camera);
      result[AppAccess.location] = await _request(Permission.location);
      for (final access in [
        AppAccess.contacts,
        AppAccess.nearby,
        AppAccess.bluetooth,
        AppAccess.photos,
      ]) {
        result[access] = AccessState.onUse;
      }
      result[AppAccess.phone] = AccessState.notRequired;
      return result;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      result[AppAccess.camera] = await _request(Permission.camera);
      result[AppAccess.location] = await _request(Permission.locationWhenInUse);
      result[AppAccess.contacts] = await _request(Permission.contacts);
      result[AppAccess.phone] = await _request(Permission.phone);
      result[AppAccess.nearby] = sdk >= 33
          ? await _request(Permission.nearbyWifiDevices)
          : result[AppAccess.location]!;
      if (sdk >= 31) {
        final scan = await _request(Permission.bluetoothScan);
        final connect = await _request(Permission.bluetoothConnect);
        result[AppAccess.bluetooth] = scan == AccessState.granted
            ? connect
            : scan;
      } else {
        result[AppAccess.bluetooth] = AccessState.notRequired;
      }
      result[AppAccess.photos] = await _request(
        sdk >= 33 ? Permission.photos : Permission.storage,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      result[AppAccess.camera] = await _request(Permission.camera);
      result[AppAccess.location] = await _request(Permission.locationWhenInUse);
      result[AppAccess.contacts] = await _request(Permission.contacts);
      result[AppAccess.bluetooth] = await _request(Permission.bluetooth);
      result[AppAccess.nearby] = result[AppAccess.bluetooth]!;
      result[AppAccess.photos] = await _request(Permission.photos);
      result[AppAccess.phone] = AccessState.notRequired;
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      result[AppAccess.camera] = await _request(Permission.camera);
      result[AppAccess.photos] = AccessState.onUse;
      result[AppAccess.phone] = AccessState.notRequired;
    }
    return result;
  }
}

class StartupPermissions extends ChangeNotifier {
  final AccessBackend backend;
  final PermissionMemory memory;
  final states = {
    for (final access in AppAccess.values) access: AccessState.pending,
  };
  bool visible = false;
  bool busy = false;
  bool requested = false;
  String? error;
  bool _disposed = false;
  StartupPermissions({AccessBackend? backend, PermissionMemory? memory})
    : backend = backend ?? DeviceAccessBackend(),
      memory = memory ?? DevicePermissionMemory();
  void _update() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    try {
      visible = !await memory.hasSeenIntro();
    } catch (_) {
      visible = true;
    }
    _update();
  }

  void open() {
    visible = true;
    requested = false;
    error = null;
    _update();
  }

  Future<void> request() async {
    if (busy) return;
    busy = true;
    error = null;
    _update();
    try {
      states.addAll(await backend.requestAll());
      requested = true;
      await memory.markSeen();
    } catch (_) {
      error = 'No se pudieron completar todos los permisos. Puedes continuar y revisarlos en los ajustes del dispositivo.';
    } finally {
      busy = false;
      _update();
    }
  }

  Future<void> dismiss() async {
    if (busy) return;
    try {
      await memory.markSeen();
    } catch (_) {
      /* Retry storage on the next start. */
    }
    visible = false;
    _update();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
