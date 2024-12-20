import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nametickles/blague_model.dart';

import '../gemmes.dart';

class EventPage extends StatefulWidget {
  final bool? isAdmin; // Paramètre du constructeur

  const EventPage({super.key, this.isAdmin}); // Passer la valeur dans le constructeur

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  CollectionReference eventsRef = FirebaseFirestore.instance.collection("Events");
  final GemmesManager _gemmesManager = GemmesManager();
  bool _isUpdating = false; // Verrouillage pour éviter plusieurs clics simultanés
  bool get _isAdmin => widget.isAdmin ?? false;

  Future<void> _retirerGemmes(int montant) async {
    if (_isUpdating) return; // Si déjà en cours, on ignore les clics supplémentaires
    _isUpdating = true;

    bool success = await _gemmesManager.depenserGemmes(montant);
    if (success) {
      // Recharge la valeur depuis Firestore pour s'assurer que la valeur est à jour
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).get();
        if (userDoc.exists) {
          setState(() {
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

  Future<void> showDescription(Event eventData) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(eventData.blague),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("likes: ${eventData.like.length}"),
                Text("Créateur: ${eventData.createur}")
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton.icon(
              onPressed: () async {
                final FirebaseAuth auth = FirebaseAuth.instance;
                final User? user = auth.currentUser;
                final uid = user?.uid;
                final FirebaseFirestore _firestore = FirebaseFirestore.instance;
                if (uid != null && !eventData.like.contains(uid)) {
                  eventData.like.add(uid);
                  await _firestore.collection('Events').doc(eventData.id).update({
                    'like': eventData.like,
                  });
                }
                else{
                  showLiked(eventData);
                }
              },
              label: const Text("Like"),
              icon: const Icon(Icons.thumb_up_rounded),
            ),
            if(!_isAdmin)ElevatedButton.icon(
              onPressed: () async {
                final FirebaseAuth auth = FirebaseAuth.instance;
                final User? user = auth.currentUser;
                final uid = user?.uid;
                final FirebaseFirestore _firestore = FirebaseFirestore.instance;
                if (uid != null && !eventData.suppression.contains(uid)) {
                  eventData.suppression.add(uid);
                  await _firestore.collection('Events').doc(eventData.id).update({
                    'suppression': eventData.suppression,
                  });
                  if (eventData.suppression.length >= 3) {
                    await eventsRef.doc(eventData.id).delete();
                    return;
                  }
                }
              },
              label: const Text("Demander suppression"),
              icon: const Icon(Icons.cancel_outlined),
            ),
            if(_isAdmin)ElevatedButton.icon(
              onPressed: () async {
                await eventsRef.doc(eventData.id).delete();
              },
              label: const Text("Supprimer(admin)"),
              icon: const Icon(Icons.cancel_outlined),
            ),
            const SizedBox(width: 20),
            TextButton(
              child: const Text("Fermer"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> showLiked(Event eventData) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Vous avez déjà mis un like"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                if(_isAdmin)const Text("Relike : gratuit"),
                if(!_isAdmin)const Text("Relike: 12 gemmes")
              ],
            ),
          ),
          actions: <Widget>[
            if(!_isAdmin)ElevatedButton.icon(
              onPressed: () async {
                final FirebaseAuth auth = FirebaseAuth.instance;
                final User? user = auth.currentUser;
                String? uid = user?.uid;

                if (uid != null && !eventData.like.contains("${uid}2")){
                  _retirerGemmes(12);
                  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
                  eventData.like.add("${uid}2");
                  await _firestore.collection('Events').doc(eventData.id).update({
                    'like': eventData.like,
                  });
                }
                Navigator.of(context).pop();
              },
              label: const Text("Relike"),
              icon: const Icon(Icons.thumb_up_rounded),
            ),
            if(_isAdmin)ElevatedButton.icon(
              onPressed: () async {
                final FirebaseAuth auth = FirebaseAuth.instance;
                final User? user = auth.currentUser;
                String? uid = user?.uid;

                if (uid != null && !eventData.like.contains("${uid}2")){
                  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
                  eventData.like.add("${uid}2");
                  await _firestore.collection('Events').doc(eventData.id).update({
                    'like': eventData.like,
                  });
                }
                Navigator.of(context).pop();
              },
              label: const Text("ReLike(admin => gratuit)"),
              icon: const Icon(Icons.thumb_up_rounded),
            ),
            const SizedBox(width: 20),
            TextButton(
              child: const Text("Fermer"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<Event>> loadData() async {
    List<Event> events = [];
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore.collection('Events').orderBy('like', descending: true).get();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final snapshot = await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).get();
      final data = snapshot.data(); // Récupère toutes les données sous forme de Map<String, dynamic>
      final createur = data?['pseudo'];
      Map<String, dynamic> dataWithId = doc.data() as Map<String, dynamic>;
      dataWithId['id'] = doc.id;
      dataWithId['createur'] = createur;
      events.add(Event.fromData(dataWithId));
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<List<Event>>(
          future: loadData(),
          builder: (BuildContext context, AsyncSnapshot<List<Event>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Erreur : ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text("Aucune blague");
            } else {
              List<Event> events = snapshot.data!;
              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final nomblague = event.nomblague;
                  final blague = event.blague;

                  return Card(
                    child: ListTile(
                      title: Text(nomblague),
                      subtitle: Text(blague),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          showDescription(event);
                        },
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}