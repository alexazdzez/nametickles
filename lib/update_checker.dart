import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  final String githubUsername;
  final String repoName;
  final double currentVersion;

  UpdateChecker({required this.githubUsername, required this.repoName, required this.currentVersion});

  Future<void> checkForUpdates(GlobalKey<NavigatorState> navigatorKey) async {
    final url = Uri.parse('https://raw.githubusercontent.com/$githubUsername/$repoName/master/version.json');
    try {
      final reponse = await http.get(url);
      if (reponse.statusCode == 200) {
        final remoteData = json.decode(reponse.body);
        final latestVersion = double.tryParse(remoteData['version']) ?? 0.0;
        final isSnapshot = remoteData['snapshot'] as bool;

        if (latestVersion != currentVersion) {
          if (isSnapshot) {
            _showSnapshotDialog(navigatorKey, latestVersion, currentVersion);
          }
          else{
            _showUpdateDialog(navigatorKey, latestVersion, currentVersion);
          }
        }
      } else {
        print("Erreur lors de la récupération de la version distante: url = $url, reponse = ${reponse.statusCode}");
      }
    } catch (e) {
      print("Erreur de mise à jour: $e");
    }
  }

  void _showUpdateDialog(GlobalKey<NavigatorState> navigatorKey, double latestVersion, double currentVersion) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print("Impossible d'afficher le dialogue de mise à jour : le contexte est null.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mise à jour disponible"),
        content: Text("Version $latestVersion disponible. Voulez-vous télécharger la mise à jour ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Plus tard"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstallUpdate(latestVersion.toString());
            },
            child: Text("Mettre à jour"),
          ),
        ],
      ),
    );
  }
  void _showSnapshotDialog(GlobalKey<NavigatorState> navigatorKey, double latestVersion, double currentVersion) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print("Impossible d'afficher le dialogue de mise à jour : le contexte est null.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mise à jour en snapshot"),
        content: Text(
            "Version $latestVersion disponible. Voulez-vous télécharger la mise à jour ?\n"
            "Attention cette version est une beta!"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Non, je veux pas de risque"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstallUpdate(latestVersion.toString());
            },
            child: Text("Mettre à jour sur une beta"),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstallUpdate(String latestVersion) async {
    final apkUrl = 'https://github.com/$githubUsername/$repoName/releases/download/V$latestVersion/app-release.apk';
    final Uri url = Uri.parse(apkUrl);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
