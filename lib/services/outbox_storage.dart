import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Un envío pendiente de la cola offline (SOS, reporte, favor, mensaje o check-in).
class OutboxEntry {
  final String id;

  /// Tipo para POST /sync/outbox: SOS, POST, VULNERABLE_REPORT, MESSAGE, CHECK_IN...
  final String type;
  final String endpoint;
  final String method;
  final Map<String, Object?> payload;

  /// Milisegundos desde 1970: define el orden FIFO.
  final int createdAt;

  /// Milisegundos desde 1970 en que este elemento caduca (TTL).
  final int? expiresAt;

  int retryCount;

  OutboxEntry({
    required this.id,
    required this.type,
    required this.payload,
    this.endpoint = 'sync/outbox',
    this.method = 'POST',
    int? createdAt,
    this.expiresAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  /// Elemento tal como lo recibe POST /sync/outbox.
  Map<String, Object?> toItem() => {'kind': type, 'payload': payload};

  Map<String, Object?> toRow() => {
    'id': id,
    'type': type,
    'endpoint': endpoint,
    'method': method,
    'payload_json': jsonEncode(payload),
    'created_at': createdAt,
    'expires_at': expiresAt ?? (payload['expiresAt'] as num?)?.toInt(),
    'retry_count': retryCount,
  };

  static OutboxEntry fromRow(Map<String, Object?> r) {
    final payload = Map<String, Object?>.from(
      jsonDecode(r['payload_json'] as String) as Map,
    );
    final rowExpiresAt = (r['expires_at'] as num?)?.toInt();
    final payloadExpiresAt = (payload['expiresAt'] as num?)?.toInt();
    return OutboxEntry(
      id: r['id'] as String,
      type: r['type'] as String,
      endpoint: r['endpoint'] as String,
      method: r['method'] as String,
      payload: payload,
      createdAt: r['created_at'] as int,
      expiresAt: rowExpiresAt ?? payloadExpiresAt,
      retryCount: r['retry_count'] as int,
    );
  }
}

/// Cola offline persistida en SQLite (tabla outbox_queue), para que un SOS o un reporte hecho
/// sin internet sobreviva aunque el sistema cierre la app.
///
/// En web (sqflite no funciona) o si la base no se puede abrir, no guarda nada y la cola vive
/// solo en memoria, como antes: la app nunca falla por esto.
class OutboxStorage {
  static const table = 'outbox_queue';

  final String fileName;
  Database? _db;
  bool _unavailable = false;

  OutboxStorage({this.fileName = 'nearby_outbox.db'});

  Future<Database?> _open() async {
    if (_db != null) return _db;
    if (kIsWeb || _unavailable) return null;
    try {
      _db = await openDatabase(
        p.join(await getDatabasesPath(), fileName),
        version: 2,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE $table (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            method TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            expires_at INTEGER,
            retry_count INTEGER NOT NULL DEFAULT 0
          )'''),
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            try {
              await db.execute(
                'ALTER TABLE $table ADD COLUMN expires_at INTEGER',
              );
            } catch (_) {}
          }
        },
      );
      return _db;
    } catch (e) {
      debugPrint('Cola offline solo en memoria: $e');
      _unavailable = true;
      return null;
    }
  }

  /// Todos los pendientes, del más antiguo al más nuevo (FIFO estricto).
  Future<List<OutboxEntry>> loadAll() async {
    final db = await _open();
    if (db == null) return [];
    try {
      final rows = await db.query(table, orderBy: 'created_at ASC, rowid ASC');
      return rows.map(OutboxEntry.fromRow).toList();
    } catch (_) {
      return [];
    }
  }

  /// Guarda el pendiente dentro de una transacción. Devuelve false si quedó solo en memoria.
  Future<bool> insert(OutboxEntry e) async {
    final db = await _open();
    if (db == null) return false;
    try {
      await db.transaction(
        (txn) => txn.insert(
          table,
          e.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Borra los enviados (solo después de que el backend respondió 2xx).
  Future<void> delete(Iterable<String> ids) async {
    final db = await _open();
    if (db == null || ids.isEmpty) return;
    try {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final id in ids) {
          batch.delete(table, where: 'id = ?', whereArgs: [id]);
        }
        await batch.commit(noResult: true);
      });
    } catch (_) {}
  }

  /// Suma un intento a los que el backend no pudo procesar.
  Future<void> markRetry(Iterable<OutboxEntry> entries) async {
    final db = await _open();
    if (db == null || entries.isEmpty) return;
    try {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final e in entries) {
          batch.update(
            table,
            {'retry_count': e.retryCount},
            where: 'id = ?',
            whereArgs: [e.id],
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (_) {}
  }

  /// Vacía la cola (al cerrar sesión: los pendientes no deben salir con otra cuenta).
  Future<void> clear() async {
    final db = await _open();
    if (db == null) return;
    try {
      await db.delete(table);
    } catch (_) {}
  }
}
