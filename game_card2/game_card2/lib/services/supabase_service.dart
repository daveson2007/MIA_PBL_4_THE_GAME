import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  SupabaseService._private();
  static final SupabaseService I = SupabaseService._private();

  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  String? _playerId;
  String get playerId => _playerId!;

  final Map<String, StreamController<Map<String, dynamic>>> _roomControllers = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _playerId = prefs.getString('playerId');
    if (_playerId == null) {
      _playerId = _uuid.v4();
      await prefs.setString('playerId', _playerId!);
    }
  }

  Future<String?> createRoom(String gameType, Map<String, dynamic> initialState) async {
    final res = await _client
        .from('rooms')
        .insert({
          'game_type': gameType,
          'players': [_playerId],
          'host_id': _playerId,
          'state': initialState,
          'version': 0,
        })
        .select()
        .single();
    if (res == null) return null;
    return res['id']?.toString();
  }

  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    final res = await _client.from('rooms').select().eq('id', roomId).single();
    return res as Map<String, dynamic>?;
  }

  Future<void> joinRoom(String roomId) async {
    final room = await getRoom(roomId);
    if (room == null) throw Exception('Room not found');
    final players = List<String>.from(room['players'] ?? []);
    if (!players.contains(_playerId)) {
      players.add(_playerId!);
      await _client.from('rooms').update({'players': players}).eq('id', roomId);
    }
  }

  Future<bool> updateRoomState(String roomId, Map<String, dynamic> newState, int expectedVersion) async {
    final res = await _client
        .from('rooms')
        .update({'state': newState, 'version': expectedVersion + 1, 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', roomId)
        .eq('version', expectedVersion)
        .select();
    return res != null && (res is List ? res.isNotEmpty : true);
  }

  // Simple polling subscription (compatible fallback to Realtime)
  final Map<String, Timer> _pollers = {};

  /// Subscribe to room changes using periodic polling (1s).
  /// Call [onChange] with the latest row when changed.
  void subscribeToRoom(String roomId, void Function(Map<String, dynamic>) onChange, {Duration interval = const Duration(seconds: 1)}) {
    // avoid duplicate pollers
    if (_pollers.containsKey(roomId)) return;

    Map<String, dynamic>? last;
    final timer = Timer.periodic(interval, (_) async {
      try {
        final row = await getRoom(roomId);
        if (row == null) return;
        final rowJson = Map<String, dynamic>.from(row);
        if (last == null || rowJson['updated_at'] != last?['updated_at'] || rowJson['version'] != last?['version']) {
          last = rowJson;
          onChange(rowJson);
          _roomControllers.putIfAbsent(roomId, () => StreamController<Map<String, dynamic>>.broadcast()).add(rowJson);
        }
      } catch (e) {
        // ignore polling errors silently
      }
    });

    _pollers[roomId] = timer;
  }

  /// Unsubscribe polling for a room
  void unsubscribeFromRoom(String roomId) {
    final t = _pollers.remove(roomId);
    t?.cancel();
    final ctrl = _roomControllers.remove(roomId);
    ctrl?.close();
  }

  Stream<Map<String, dynamic>> roomStream(String roomId) {
    return _roomControllers.putIfAbsent(roomId, () => StreamController<Map<String, dynamic>>.broadcast()).stream;
  }
}