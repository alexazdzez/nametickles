import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isAdmin = false; // Booléen pour vérifier si l'utilisateur est admin

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des droits admin')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Text('Activer les droits d\'admin', style: TextStyle(fontSize: 15)),
            Switch(
              value: _isAdmin,
              onChanged: (bool value) {
                setState(() {
                  _isAdmin = value;
                });
                // Pas besoin de rediriger, la page d'accueil va automatiquement s'adapter.
              },
            ),
          ],
        ),
      ),
    );
  }
}
