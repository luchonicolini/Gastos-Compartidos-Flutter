import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/group.dart';

class SelfMemberStore {
  SelfMemberStore({this.preferences});

  final SharedPreferencesAsync? preferences;

  static final Map<String, String> _cache = {};

  /// Notifica a la UI cuando cambia quién figura como "Vos" en algún grupo.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  SharedPreferencesAsync _resolve() => preferences ?? SharedPreferencesAsync();

  static String storageKey(String groupId) => 'group_self_member_$groupId';

  static String? getSelfMemberIdSync(String groupId) => _cache[groupId];

  /// Devuelve el id guardado solo si sigue siendo un miembro activo.
  ///
  /// Si el miembro fue archivado o eliminado, devuelve null para que cada
  /// pantalla aplique su propio criterio de respaldo.
  static String? activeSelfMemberId(Group group) {
    final stored = _cache[group.id];
    if (stored == null) return null;
    for (final member in group.members) {
      if (member.id == stored && !member.isArchived) return stored;
    }
    return null;
  }

  static void setCache(String groupId, String memberId) {
    if (_cache[groupId] == memberId) return;
    _cache[groupId] = memberId;
    revision.value++;
  }

  /// Solo para tests: limpia la caché en memoria.
  @visibleForTesting
  static void clearCache() {
    _cache.clear();
    revision.value++;
  }

  Future<String?> getSelfMemberId(String groupId) async {
    if (_cache.containsKey(groupId)) {
      return _cache[groupId];
    }
    try {
      final id = await _resolve().getString(storageKey(groupId));
      if (id != null) {
        _cache[groupId] = id;
      }
      return id;
    } catch (_) {
      return null;
    }
  }

  /// Igual que [getSelfMemberId], pero ignora ids de miembros archivados.
  Future<String?> getActiveSelfMemberId(Group group) async {
    final id = await getSelfMemberId(group.id);
    if (id == null) return null;
    for (final member in group.members) {
      if (member.id == id && !member.isArchived) return id;
    }
    return null;
  }

  Future<void> setSelfMemberId(String groupId, String memberId) async {
    setCache(groupId, memberId);
    try {
      await _resolve().setString(storageKey(groupId), memberId);
    } catch (_) {}
  }

  Future<void> clearSelfMemberId(String groupId) async {
    if (_cache.remove(groupId) != null) {
      revision.value++;
    }
    try {
      await _resolve().remove(storageKey(groupId));
    } catch (_) {}
  }
}
