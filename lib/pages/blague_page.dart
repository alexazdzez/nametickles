import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../blague_model.dart';

class EventPage extends StatefulWidget {
  final bool isAdmin; // Booléen passé depuis AdminPage

  const EventPage({super.key, required this.isAdmin});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
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
                Text("Créateur: ${eventData.createur}"),
                // Texte indiquant si l'utilisateur est admin ou pas
                Text(
                  widget.isAdmin ? "Vous êtes administrateur." : "Vous n'êtes pas administrateur.",
                  style: TextStyle(
                    color: widget.isAdmin ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // Affichage des boutons selon l'état de l'admin
            if (widget.isAdmin) ...[
              ElevatedButton.icon(
                onPressed: () {
                  // Suppression de la blague
                  print('Blague supprimée');
                  Navigator.pop(context);
                },
                label: const Text("Supprimer la blague"),
                icon: const Icon(Icons.delete),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Ajouter un like gratuitement
                  print('Like ajouté gratuitement');
                  Navigator.pop(context);
                },
                label: const Text("Like Gratuit"),
                icon: const Icon(Icons.thumb_up_rounded),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  // Demander suppression de la blague
                  print('Demande de suppression');
                  Navigator.pop(context);
                },
                label: const Text("Demander suppression"),
                icon: const Icon(Icons.cancel_outlined),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Payer des gemmes pour reliker
                  print('Payer des gemmes pour reliker');
                  Navigator.pop(context);
                },
                label: const Text("Reliker (12 gemmes)"),
                icon: const Icon(Icons.thumb_up_rounded),
              ),
            ],
            // Bouton fermer
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Fermer la boîte de dialogue
              },
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }
}
