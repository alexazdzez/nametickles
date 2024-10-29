import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nametickles/gemmes.dart';

class GemmePage extends StatefulWidget {
  const GemmePage({super.key});

  @override
  State<GemmePage> createState() => _GemmePageState();
}

class _GemmePageState extends State<GemmePage> {
  int? _gemmes;
  final GemmesManager _gemmesManager = GemmesManager();
  bool _isUpdating = false; // Verrouillage pour éviter plusieurs clics simultanés

  @override
  void initState() {
    super.initState();
    _checkUserGems(); // Vérification des gemmes lors de l'initialisation
  }

  Future<void> _ajouterGemmes(int montant) async {
    if (_isUpdating) return; // Si déjà en cours, on ignore les clics supplémentaires
    _isUpdating = true;

    bool success = await _gemmesManager.gagnerGemmes(montant);
    if (success) {
      // Recharge la valeur depuis Firestore pour s'assurer que la valeur est à jour
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).get();
        if (userDoc.exists) {
          setState(() {
            _gemmes = userDoc['gemmes'] ?? 0; // Actualisation après chargement
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'ajout de gemmes")),
      );
    }

    _isUpdating = false; // Libère le verrou pour permettre d'autres clics
  }

  Future<void> _checkUserGems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          _gemmes = userDoc['gemmes'] ?? 0; // Chargement des gemmes de l'utilisateur
        });
      } else {
        await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).set({'gemmes': 10}); // Création du document
        setState(() {
          _gemmes = 10; // Attribuer 10 gemmes par défaut
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Gemmes: $_gemmes",
            style: TextStyle(fontSize: 20),
            ),
            ElevatedButton(
            onPressed: () {
              _ajouterGemmes(10);
              _checkUserGems();
            },
            child: const Text("Dix gemmes => Pub")
            ),
          ],
        ),
      ),
    );
  }
}
