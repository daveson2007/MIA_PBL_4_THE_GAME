import 'package:flutter/material.dart';
import '../services/multiplayer_service.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  final MultiplayerService _service = MultiplayerService();
  bool isHosting = false;
  bool isConnecting = false;
  String? localIp;
  final TextEditingController _ipController = TextEditingController();
  String status = 'Choisissez une option';

  @override
  void initState() {
    super.initState();
    _getLocalIp();
    _service.onConnected = _onConnected;
    _service.onDisconnected = _onDisconnected;
    _service.onMessageReceived = _onMessageReceived;
  }

  Future<void> _getLocalIp() async {
    localIp = await _service.getLocalIp();
    setState(() {});
  }

  void _onConnected() {
    setState(() {
      status = 'Connecté !';
      isConnecting = false;
    });
    // Navigate to game
    Navigator.pushNamed(context, '/multiplayer_blackjack', arguments: _service);
  }

  void _onDisconnected() {
    setState(() {
      status = 'Déconnecté';
      isHosting = false;
      isConnecting = false;
    });
  }

  void _onMessageReceived(Map<String, dynamic> message) {
    // Handle messages
  }

  Future<void> _startHosting() async {
    setState(() {
      isHosting = true;
      status = 'Démarrage du serveur...';
    });
    await _service.startHosting();
    setState(() {
      status = 'Serveur démarré. IP: ${localIp ?? 'Inconnue'}:${MultiplayerService.port}';
    });
  }

  Future<void> _joinGame() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() {
      isConnecting = true;
      status = 'Connexion...';
    });
    await _service.joinGame(ip);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multijoueur LAN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Jeu Multijoueur Local',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Votre IP locale: ${localIp ?? 'Chargement...'}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(status, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isHosting ? null : _startHosting,
              child: Text(isHosting ? 'Serveur en cours...' : 'Créer une partie (Hôte)'),
            ),
            const SizedBox(height: 16),
            if (isHosting)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Partagez cette adresse avec vos amis:\n${localIp ?? 'Inconnue'}:${MultiplayerService.port}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 24),
            const Text('Ou rejoignez une partie:'),
            const SizedBox(height: 8),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Adresse IP de l\'hôte',
                hintText: '192.168.1.100:8080',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isConnecting ? null : _joinGame,
              child: Text(isConnecting ? 'Connexion...' : 'Rejoindre la partie'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Note: Assurez-vous que les appareils sont sur le même réseau Wi-Fi.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _service.disconnect();
    _ipController.dispose();
    super.dispose();
  }
}