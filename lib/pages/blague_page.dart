import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nametickles/blague_model.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  CollectionReference eventsRef = FirebaseFirestore.instance.collection("Events");

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
              },
              label: const Text("Like"),
              icon: const Icon(Icons.thumb_up_rounded),
            ),
            ElevatedButton.icon(
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
      Map<String, dynamic> dataWithId = doc.data() as Map<String, dynamic>;
      dataWithId['id'] = doc.id;
      events.add(Event.fromData(dataWithId));
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              setState(() {});
            },
            label: const Text("Actualiser"),
          )
        ],
      ),
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
