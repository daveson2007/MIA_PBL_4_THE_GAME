import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = <Map<String, String>>[
      {'route': '/blackjack', 'title': 'Blackjack', 'subtitle': 'Affrontez le croupier.'},
      {'route': '/memory', 'title': 'Memory', 'subtitle': 'Retrouvez toutes les paires.'},
      {'route': '/president', 'title': 'Président', 'subtitle': 'Jouez une partie stratégique.'},
      {'route': '/inter', 'title': 'L’Inter', 'subtitle': 'Un jeu de la terre simplifié.'},
      {'route': '/placeholder', 'title': 'Belote', 'subtitle': 'Bientôt disponible.'},
      {'route': '/speed', 'title': 'Speed', 'subtitle': 'Un jeu de rapidité.'},
      {'route': '/poker', 'title': 'Poker', 'subtitle': 'Vidéo Poker 5 cartes.'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jeux de Cartes Flutter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenue dans votre application de cartes.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Choisissez un jeu pour commencer :', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: games.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final game = games[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      title: Text(game['title']!),
                      subtitle: Text(game['subtitle']!),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.pushNamed(context, game['route']!, arguments: game['title']);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
