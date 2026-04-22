import 'package:flutter/material.dart';

class PlaceholderGameScreen extends StatelessWidget {
  const PlaceholderGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String title = ModalRoute.of(context)?.settings.arguments as String? ?? 'Jeu';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'Ce jeu est en cours d’intégration dans la version Flutter.\n'
                'La structure mobile est prête, et vous pouvez bientôt retrouver Belote, Speed et Poker dans l’application.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour au menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
