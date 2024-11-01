import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nametickles/auth.dart';
import 'package:nametickles/pages/add_blague_page.dart';
import 'package:nametickles/pages/blague_page.dart';
import 'package:nametickles/pages/account.dart';
import 'package:nametickles/update_checker.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
  connect();
}

void connect() async {
  AuthServices auth = AuthServices();
  await auth.signinAnonymous(); // Assure que l'utilisateur est connecté
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  int? _gemmes; // Ajout de la variable pour stocker les gemmes

  @override
  void initState() {
    super.initState();
    _checkUserGems(); // Vérification des gemmes lors de l'initialisation
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

  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
      _checkUserGems();
    });
  }

  final UpdateChecker updateChecker = UpdateChecker(
    githubUsername: 'alexazdzez',
    repoName: 'nametickles',
    currentVersion: '4.0.0',
  );

  @override
  Widget build(BuildContext context) {
    updateChecker.checkForUpdates(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: [
            const Text("Blagues"),
            const Text("Ajoutes-en une"),
            const Text("Mon compte"),
          ][_currentIndex],
          backgroundColor: Colors.lightBlue,
        ),
        body: [
          const EventPage(),
          const AddEventPage(),
          const MyAccount(),
        ][_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setCurrentIndex(index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.black54,
          backgroundColor: Colors.lightBlueAccent,
          elevation: 10,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.mood),
                label: "Accueil"
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.add),
                label: "Ajoutes-en une"
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Mon compte"
            ),
          ],
        ),
      ),
    );
  }
}
