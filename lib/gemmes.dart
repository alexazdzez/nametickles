import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GemmesManager {
  Future<bool> depenserGemmes(int montant) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).get();

      if (userDoc.exists) {
        int currentGems = userDoc['gemmes'] ?? 0;

        if (currentGems >= montant) {
          // Déduire les gemmes
          await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).update({
            'gemmes': currentGems - montant,
          });
          return true; // Dépense réussie
        } else {
          return false; // Pas assez de gemmes
        }
      }
    }
    return false; // Utilisateur non connecté ou document inexistant
  }
  Future<bool> gagnerGemmes(int montant) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).get();

      if (userDoc.exists) {
        int currentGems = userDoc['gemmes'] ?? 0;
          // Déduire les gemmes
          await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).update({
            'gemmes': currentGems + montant,
          });
          return true; // Dépense réussie
        } else {
        }
      }

    return false; // Utilisateur non connecté ou document inexistant
  }
}
