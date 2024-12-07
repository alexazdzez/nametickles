import 'package:flutter/material.dart';

import 'blague_page.dart';

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Text('Activer les droits d\'admin',style: TextStyle(fontSize: 15),),
            Switch(
              value: _isAdmin,
              onChanged: (bool value) {
                setState(() {
                  _isAdmin = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                // Passer le booléen à la page Event
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventPage(isAdmin: _isAdmin),
                  ),
                );
              },
              child: const Text('Voir la page de l\'événement'),
            ),
          ],
        ),
      ),
    );
  }
}
