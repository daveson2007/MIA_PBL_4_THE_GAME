import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class OnlineRoomScreen extends StatefulWidget {
  final String roomId;
  const OnlineRoomScreen({super.key, required this.roomId});

  @override
  State<OnlineRoomScreen> createState() => _OnlineRoomScreenState();
}

class _OnlineRoomScreenState extends State<OnlineRoomScreen> {
  Map<String, dynamic>? room;
  bool loading = true;
  String logs = '';

  @override
  void initState() {
    super.initState();
    _initRoom();
    SupabaseService.I.subscribeToRoom(widget.roomId, _onRoomChange);
  }

  Future<void> _initRoom() async {
    final r = await SupabaseService.I.getRoom(widget.roomId);
    if (!mounted) return;
    setState(() {
      room = r;
      loading = false;
    });
  }

  void _onRoomChange(Map<String, dynamic> newRow) {
    setState(() {
      room = newRow;
      logs = '${DateTime.now().toIso8601String()} - update v=${room?['version']}\n$logs';
    });
  }

  void _leave() {
    SupabaseService.I.unsubscribeFromRoom(widget.roomId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _fakeAction() async {
    if (room == null) return;
    final currentVersion = room!['version'] ?? 0;
    final currentState = Map<String, dynamic>.from(room!['state'] ?? {});
    // Simple fake action: append a timestamp to table
    final table = List.from(currentState['table'] ?? []);
    table.add('fake_${DateTime.now().millisecondsSinceEpoch}');
    currentState['table'] = table;

    final ok = await SupabaseService.I.updateRoomState(widget.roomId, currentState, currentVersion);
    if (!ok) {
      final latest = await SupabaseService.I.getRoom(widget.roomId);
      if (!mounted) return;
      setState(() {
        room = latest;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conflit: état mis à jour depuis un autre client')));
      }
    }
  }

  @override
  void dispose() {
    SupabaseService.I.unsubscribeFromRoom(widget.roomId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = (room?['players'] as List?)?.cast<String>() ?? [];
    final version = room?['version']?.toString() ?? '-';
    final updatedAt = room?['updated_at']?.toString() ?? '-';
    final state = room?['state'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Room ${widget.roomId.substring(0, 8)}'),
        actions: [IconButton(onPressed: _leave, icon: const Icon(Icons.exit_to_app))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Players: ${players.join(', ')}'),
                  const SizedBox(height: 8),
                  Text('Version: $version    updated_at: $updatedAt', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  const Text('State JSON:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(child: SingleChildScrollView(child: Text(const JsonEncoder.withIndent('  ').convert(state ?? {})))),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _fakeAction, child: const Text('Fake action (append table)')),
                  const SizedBox(height: 8),
                  const Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SizedBox(height: 120, child: SingleChildScrollView(child: Text(logs))),
                ],
              ),
      ),
    );
  }
}
