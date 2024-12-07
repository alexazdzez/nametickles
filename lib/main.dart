import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nametickles/auth.dart';
import 'package:nametickles/pages/add_blague_page.dart';
import 'package:nametickles/pages/admin_page.dart';
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
  int? _gemmes;
  bool? _admin; // Peut être null au départ pour attendre Firestore
  double currentVersion = 5.2;
  late final UpdateChecker updateChecker;
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _checkUserDoc();
    updateChecker = UpdateChecker(
      githubUsername: 'alexazdzez',
      repoName: 'nametickles',
      currentVersion: currentVersion,
    );
    updateChecker.checkForUpdates(navigatorKey);
  }

  Future<void> _checkUserDoc() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = FirebaseFirestore.instance.collection('Utilisateurs').doc(uid);

      // Vérification si le document existe et mise à jour des données
      final snapshot = await userDoc.get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _gemmes = data['gemmes'] ?? 10;
          _admin = data['admin'] ?? false;
        });
        await userDoc.update({'version': currentVersion});
      } else {
        // Création du document utilisateur par défaut
        await userDoc.set({
          'gemmes': 10,
          'admin': false,
          'version': currentVersion,
        });
        setState(() {
          _gemmes = 10;
          _admin = false;
        });
      }
    }
  }

  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_admin == null || _gemmes == null) {
      _checkUserDoc();
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: [
            const Text("Blagues"),
            const Text("Ajoutes-en une"),
            const Text("Mon compte"),
            if (_admin!) const Text("Administration"),
          ][_currentIndex],
          backgroundColor: Colors.lightBlue,
        ),
        body: [
          EventPage(isAdmin : _admin),
          const AddEventPage(),
          const MyAccountPage(),
          if (_admin!) const AdminPage(),
        ][_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setCurrentIndex(index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.black54,
          backgroundColor: Colors.lightBlueAccent,
          elevation: 10,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.mood),
              label: "Accueil",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: "Ajoutes-en une",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Mon compte",
            ),
            if (_admin!)
              const BottomNavigationBarItem(
                icon: Icon(Icons.lock_outline),
                label: "Admin",
              ),
          ],
        ),
      ),
      navigatorKey: navigatorKey,
    );
  }
}
