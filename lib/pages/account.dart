import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nametickles/blague_model.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({super.key});

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    QuerySnapshot querySnapshot = await firestore
        .collection('Events')
        .where('createur', isEqualTo: uid)
        .get();

    List<Event> events = [];
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      Map<String, dynamic> dataWithId = doc.data() as Map<String, dynamic>;
      dataWithId['id'] = doc.id;
      events.add(Event.fromData(dataWithId));
    }

    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  Future<void> showDescription(Event eventData) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
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
                onPressed: () {
                  Navigator.of(context).pop(); // Close the current dialog
                  showEditDialog(eventData); // Show the edit dialog
                },
                label: const Text("Modifier"),
                icon: const Icon(Icons.edit_note)),
            ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection("Events").doc(eventData.id).delete();
                  setState(() {
                    _events.remove(eventData);
                  });
                  Navigator.of(context).pop();
                },
                label: const Text("Supprimer"),
                icon: const Icon(Icons.cancel_outlined)),
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

  Future<void> showEditDialog(Event eventData) async {
    TextEditingController blagueController = TextEditingController(text: eventData.blague);
    GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier la blague'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: blagueController,
                    decoration: const InputDecoration(labelText: 'Blague'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une blague';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Enregistrer'),
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  String newBlague = blagueController.text;
                  if (newBlague.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('Events')
                        .doc(eventData.id)
                        .update({'blague': newBlague});

                    setState(() {
                      eventData.blague = newBlague;
                    });

                    Navigator.of(context).pop(); // Close the edit dialog
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Mes blagues:"),
            _isLoading
                ? const CircularProgressIndicator()
                : _events.isEmpty
                ? const Text("Aucune blague trouvée.")
                : Expanded(
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Text(_events[index].nomblague),
                      subtitle: Text(_events[index].blague),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          showDescription(_events[index]);
                        },
                      ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}