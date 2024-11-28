import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nametickles/blague_model.dart';

import '../gemmes.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({super.key});

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  List<Event> _events = [];
  bool _isLoading = true;
  int? _gemmes;
  final GemmesManager _gemmesManager = GemmesManager();

  @override
  void initState() {
    super.initState();
    loadData();
    _checkUserGems();
  }

  Future<void> _checkUserGems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).get();
      if (userDoc.exists) {
        setState(() {
          _gemmes = userDoc['gemmes'] ?? 0;
        });
      } else {
        await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).set({'gemmes': 10});
        setState(() {
          _gemmes = 10;
        });
      }
    }
  }

  Future<bool> _isPseudoAvailable(String pseudo) async {
    final query = await FirebaseFirestore.instance
        .collection('Utilisateurs')
        .where('pseudo', isEqualTo: pseudo)
        .get();
    return query.docs.isEmpty;
  }

  Future<void> _updatePseudo(String newPseudo) async {
    if (_gemmes != null && _gemmes! >= 10) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userRef = FirebaseFirestore.instance.collection('Utilisateurs').doc(uid);

        // Vérifier si le pseudo est disponible
        bool isAvailable = await _isPseudoAvailable(newPseudo);
        if (!isAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ce pseudo est déjà pris. Veuillez en choisir un autre.")),
          );
          return;
        }

        // Récupérer l'ancien pseudo
        final userDoc = await userRef.get();
        String oldPseudo = userDoc['pseudo'];

        // Mettre à jour les blagues avec le nouveau pseudo
        final eventsRef = FirebaseFirestore.instance.collection('Events');
        final querySnapshot = await eventsRef
            .where('createur', isEqualTo: oldPseudo)
            .get();

        for (var doc in querySnapshot.docs) {
          await eventsRef.doc(doc.id).update({'createur': newPseudo});
        }

        // Mettre à jour le pseudo de l'utilisateur et déduire les gemmes
        await userRef.update({
          'pseudo': newPseudo,
          'gemmes': _gemmes! - 10,
        });

        setState(() {
          _gemmes = _gemmes! - 10;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pseudo modifié avec succès !")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous n'avez pas assez de gemmes pour changer de pseudo.")),
      );
    }
  }

  Future<void> loadData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userDoc = await FirebaseFirestore.instance.collection('Utilisateurs').doc(uid).get();
    QuerySnapshot querySnapshot = await firestore
        .collection('Events')
        .where('createur', isEqualTo: userDoc['pseudo'])
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
                onPressed: () {
                  Navigator.of(context).pop();
                  showEditDialog(eventData);
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
      barrierDismissible: false,
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

                    Navigator.of(context).pop();
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
    final pseudoController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Gemmes: $_gemmes",
              style: const TextStyle(fontSize: 20),
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Nouveau pseudo",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Vous devez compléter ce champ";
                }
                return null;
              },
              controller: pseudoController,
              maxLength: 15,
            ),
            SizedBox(
              width: 100,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? true) {
                    String newPseudo = pseudoController.text.trim();
                    if (newPseudo.isNotEmpty) {
                      await _updatePseudo(newPseudo);
                      pseudoController.clear();
                    }
                  }
                },
                child: const Text("Changer", style: TextStyle(fontSize: 13)),
              ),
            ),
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
