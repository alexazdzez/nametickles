import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();

  final nomblagueController = TextEditingController();
  final blagueController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    nomblagueController.dispose();
    blagueController.dispose();
  }

  Future<List<String>> get_all_blague() async {
    List<String> blagueList = [];
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Events').get();
    querySnapshot.docs.forEach((doc) {
      String blague = doc['blague'];
      blagueList.add(blague);
    });

    return blagueList;
  }

  Future<List<String>> get_all_nom_blague() async {
    List<String> nom_blagueList = [];
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Events').get();
    querySnapshot.docs.forEach((doc) {
      String nom_blague = doc['nom_blague'];
      nom_blagueList.add(nom_blague);
    });

    return nom_blagueList;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                  "Avant de créer votre blague:\n"
                      " - Regardez des blagues\n"
                      " - Ne mettez pas:\n"
                      "    - Une blague existante\n"
                      " - Un nom/prénom peut être réutilisé\n"
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Nom et prénom pour la blague",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Vous devez compléter ce champ";
                  }
                  return null;
                },
                controller: nomblagueController,
                maxLength: 15,
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 25),
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Blague sur nom ou prénom",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vous devez compléter ce champ";
                    }
                    return null;
                  },
                  controller: blagueController,
                  maxLength: 25,
                ),
              ),
              SizedBox(
                width: 100,
                height: 50,
                child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final nom_blague = nomblagueController.text;
                        final blague = blagueController.text;
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        final User? user = auth.currentUser;
                        final uid = user?.uid;
                        final Timestamp date = Timestamp.now();

                        List<String> allBlagues = await get_all_blague();

                        bool blagueExists = allBlagues.any((element) =>
                        element.toLowerCase().trim() ==
                            blague.toLowerCase().trim());

                        if (!blagueExists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Blague ajoutée avec succès"),
                            ),
                          );

                          CollectionReference eventsRef = FirebaseFirestore.instance.collection("Events");
                          eventsRef.add({
                            "nom_blague": nom_blague,
                            "blague": blague,
                            "createur": uid,
                            "like": [],
                            "date_creation": date,
                            "suppression": []
                          });

                          nomblagueController.clear();
                          blagueController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Une blague similaire existe déjà"),
                            ),
                          );
                        }
                        FocusScope.of(context).unfocus();
                      }
                    },
                    child: const Text("Envoyer")),
              )
            ],
          )),
    );
  }
}
