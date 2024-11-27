import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UpdateChecker {
  final String githubUsername;
  final String repoName;
  final String currentVersion;

  UpdateChecker({required this.githubUsername, required this.repoName, required this.currentVersion});

  Future<void> checkForUpdates(GlobalKey<NavigatorState> navigatorKey) async {
    final url = Uri.parse('https://raw.githubusercontent.com/$githubUsername/$repoName/master/version.json');
    try {
      final reponse = await http.get(url);
      if (reponse.statusCode == 200) {
        final remoteData = json.decode(reponse.body);
        final latestVersion = remoteData['version'];

        if (latestVersion != currentVersion) {
          // Nouvelle version disponible
          _showUpdateDialog(navigatorKey, latestVersion, currentVersion);
        }
      } else {
        print("Erreur lors de la récupération de la version distante: url = $url, reponse = ${reponse.statusCode}");
      }
    } catch (e) {
      print("Erreur de mise à jour: $e");
    }
  }

  void _showUpdateDialog(GlobalKey<NavigatorState> navigatorKey, String latestVersion, String currentVersion) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print("Impossible d'afficher le dialogue de mise à jour : le contexte est null.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mise à jour disponible $latestVersion"),
        content: Text("Version $currentVersion disponible. Voulez-vous télécharger la mise à jour ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Plus tard"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstallUpdate(latestVersion);
            },
            child: Text("Mettre à jour"),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstallUpdate(String latestVersion) async {
    final apkUrl = 'https://github.com/$githubUsername/$repoName/releases/download/V$latestVersion/app-release.apk';
    final response = await http.get(Uri.parse(apkUrl));

    if (response.statusCode == 200) {
      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/app-release.apk';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      print("APK téléchargé avec succès à $filePath");

      // Lancement de l'installation (uniquement possible sur Android)
      if (Platform.isAndroid) {
        print("oh");
        await Process.run('pm', ['install', '-r', filePath]);
        print("ha");
      }
      else{
        print("ah");
      }
    } else {
      print(apkUrl);
      print("Erreur lors du téléchargement de l'APK ${response.statusCode}");
    }
  }
}
