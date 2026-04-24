import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/supabase_service.dart';

class OnlineInterScreen extends StatefulWidget {
  final String roomId;
  const OnlineInterScreen({super.key, required this.roomId});

  @override
  State<OnlineInterScreen> createState() => _OnlineInterScreenState();
}

class _OnlineInterScreenState extends State<OnlineInterScreen> {
  Map<String, dynamic>? room;
  bool loading = true;
  List<CardModel> myHand = [];
  List<CardModel> opponentHand = [];
  List<CardModel> discardPile = [];
  List<CardModel> deck = [];
  String turn = '';
  String infoMessage = '';
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _initRoom();
    SupabaseService.I.subscribeToRoom(widget.roomId, _onRoomChange);
  }

  Future<void> _initRoom() async {
    final r = await SupabaseService.I.getRoom(widget.roomId);
    if (!mounted) return;
    room = r;
    _applyRoomToLocal(r);
    // if player has no hand, attempt to claim an initial hand
    await _ensurePlayerHandExists();
    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  void _onRoomChange(Map<String, dynamic> newRow) {
    if (!mounted) return;
    room = newRow;
    _applyRoomToLocal(newRow);
    setState(() {});
  }

  void _applyRoomToLocal(Map<String, dynamic>? r) {
    if (r == null) return;
    final state = (r['state'] ?? {}) as Map<String, dynamic>;
    final deckJson = List.from(state['deck'] ?? []);
    deck = deckJson.map((e) => CardModel.fromJson(Map<String, dynamic>.from(e))).toList();

    final hands = Map<String, dynamic>.from(state['hands'] ?? {});
    final playerId = SupabaseService.I.playerId;
    myHand = (hands[playerId] as List? ?? []).map((e) => CardModel.fromJson(Map<String, dynamic>.from(e))).toList();

    final players = List<String>.from(room?['players'] ?? []);
    final otherId = players.firstWhere((p) => p != playerId, orElse: () => '');
    opponentHand = (hands[otherId] as List? ?? []).map((e) => CardModel.fromJson(Map<String, dynamic>.from(e))).toList();

    discardPile = (state['discard'] as List? ?? []).map((e) => CardModel.fromJson(Map<String, dynamic>.from(e))).toList();
    turn = state['turn'] ?? '';
    infoMessage = state['info'] ?? '';
  }

  Future<void> _ensurePlayerHandExists() async {
    final playerId = SupabaseService.I.playerId;
    final r = room;
    if (r == null) return;
    final state = Map<String, dynamic>.from(r['state'] ?? {});
    final hands = Map<String, dynamic>.from(state['hands'] ?? {});
    if ((hands[playerId] as List?)?.isNotEmpty ?? false) return;

    // Prefer assigning reserved cards (dealt by host) if present, otherwise draw from deck
    final reservedList = List<Map<String, dynamic>>.from(state['reserved'] ?? []);
    final deckList = List<Map<String, dynamic>>.from(state['deck'] ?? []);
    final take = <Map<String, dynamic>>[];
    if (reservedList.isNotEmpty) {
      for (var i = 0; i < 4 && reservedList.isNotEmpty; i++) {
        take.add(reservedList.removeLast());
      }
      state['reserved'] = reservedList;
    } else {
      if (deckList.isEmpty) return;
      for (var i = 0; i < 4 && deckList.isNotEmpty; i++) {
        take.add(deckList.removeLast());
      }
    }
    hands[playerId] = take;
    state['deck'] = deckList;
    state['hands'] = hands;

    final expectedVersion = r['version'] ?? 0;
    final ok = await SupabaseService.I.updateRoomState(widget.roomId, state, expectedVersion);
    if (!ok) {
      final latest = await SupabaseService.I.getRoom(widget.roomId);
      if (!mounted) return;
      room = latest;
      _applyRoomToLocal(latest);
    }
  }

  Future<void> _playCard() async {
    if (selectedIndex == null) return;
    final playerId = SupabaseService.I.playerId;
    if (turn != playerId) {
      setState(() => infoMessage = 'Pas votre tour');
      return;
    }
    final selected = myHand[selectedIndex!];
    final topCard = discardPile.isEmpty ? null : discardPile.last;
    final activeSuit = discardPile.isEmpty ? '' : discardPile.last.suit;
    final valid = selected.rank == '8' || (topCard != null && (selected.rank == topCard.rank || selected.suit == activeSuit));
    if (!valid) {
      setState(() => infoMessage = 'Coup invalide !');
      return;
    }

    final r = room;
    if (r == null) return;
    final currentVersion = r['version'] ?? 0;
    final state = Map<String, dynamic>.from(r['state'] ?? {});
    final hands = Map<String, dynamic>.from(state['hands'] ?? {});
    final playerHandJson = List<Map<String, dynamic>>.from(hands[playerId] ?? []);
    playerHandJson.removeAt(selectedIndex!);
    hands[playerId] = playerHandJson;
    final discardJson = List<Map<String, dynamic>>.from(state['discard'] ?? []);
    discardJson.add(selected.toJson());
    state['discard'] = discardJson;

    final players = List<String>.from(r['players'] ?? []);
    final next = players.length > 1 ? players[(players.indexOf(playerId) + 1) % players.length] : playerId;
    state['turn'] = next;
    state['info'] = 'Joueur a joué ${selected.label}';

    final ok = await SupabaseService.I.updateRoomState(widget.roomId, state, currentVersion);
    if (!ok) {
      final latest = await SupabaseService.I.getRoom(widget.roomId);
      if (!mounted) return;
      room = latest;
      _applyRoomToLocal(latest);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conflit: état mis à jour')));
    } else {
      setState(() => selectedIndex = null);
    }
  }

  Future<void> _drawCard() async {
    final playerId = SupabaseService.I.playerId;
    final r = room;
    if (r == null) return;
    final currentVersion = r['version'] ?? 0;
    final state = Map<String, dynamic>.from(r['state'] ?? {});
    final deckList = List<Map<String, dynamic>>.from(state['deck'] ?? []);
    if (deckList.isEmpty) {
      setState(() => infoMessage = 'Pioche vide');
      return;
    }
    final cardJson = deckList.removeLast();
    final hands = Map<String, dynamic>.from(state['hands'] ?? {});
    final playerHandJson = List<Map<String, dynamic>>.from(hands[playerId] ?? []);
    playerHandJson.add(cardJson);
    hands[playerId] = playerHandJson;
    state['deck'] = deckList;
    final players = List<String>.from(r['players'] ?? []);
    final next = players.length > 1 ? players[(players.indexOf(playerId) + 1) % players.length] : playerId;
    state['turn'] = next;
    state['info'] = 'Joueur a pioché';

    final ok = await SupabaseService.I.updateRoomState(widget.roomId, state, currentVersion);
    if (!ok) {
      final latest = await SupabaseService.I.getRoom(widget.roomId);
      if (!mounted) return;
      room = latest;
      _applyRoomToLocal(latest);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conflit: état mis à jour')));
    }
  }

  @override
  void dispose() {
    SupabaseService.I.unsubscribeFromRoom(widget.roomId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inter — ${widget.roomId.substring(0, 8)}'),
        actions: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.exit_to_app))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Carte demandée : ${discardPile.isEmpty ? '-' : discardPile.last.suit}'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView(scrollDirection: Axis.horizontal, children: discardPile.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: Text(c.label))).toList()),
                  ),
                  const SizedBox(height: 12),
                  Text(infoMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Votre main', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      itemCount: myHand.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.75),
                      itemBuilder: (context, index) {
                        final card = myHand[index];
                        return GestureDetector(
                          onTap: () => setState(() => selectedIndex = index),
                          child: Container(
                            decoration: BoxDecoration(border: Border.all(color: selectedIndex == index ? Colors.blue : Colors.grey)),
                            child: Center(child: Text(card.label)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      ElevatedButton(onPressed: _playCard, child: const Text('Jouer')),
                      ElevatedButton(onPressed: _drawCard, child: const Text('Piocher')),
                      OutlinedButton(onPressed: () {}, child: const Text('✊ Toc Toc')),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
