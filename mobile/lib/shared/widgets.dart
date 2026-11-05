import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';

/// Encadré d'erreur (rouge) ou d'information (vert).
class Bandeau extends StatelessWidget {
  const Bandeau(this.message, {super.key, this.succes = false});

  final String message;
  final bool succes;

  @override
  Widget build(BuildContext context) {
    final couleur = succes ? Couleurs.vert : Couleurs.erreur;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(succes ? Icons.check_circle_outline : Icons.error_outline, color: couleur, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(color: couleur, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

/// Bloc blanc arrondi avec un titre facultatif.
class Bloc extends StatelessWidget {
  const Bloc({super.key, this.titre, this.icone, required this.children});

  final String? titre;
  final IconData? icone;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (titre != null) ...[
              Row(children: [
                if (icone != null) ...[Icon(icone, color: Couleurs.vert, size: 20), const SizedBox(width: 8)],
                Text(titre!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
            ],
            ...children,
          ]),
        ),
      );
}

/// Photo de profil ou initiales.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.nom, this.photo, this.rayon = 22});

  final String nom;
  final String? photo;
  final double rayon;

  @override
  Widget build(BuildContext context) {
    final url = Config.urlFichier(photo);
    final initiales = nom.split(RegExp(r'\s+')).where((m) => m.isNotEmpty).take(2).map((m) => m[0].toUpperCase()).join();
    return CircleAvatar(
      radius: rayon,
      backgroundColor: Couleurs.vertClair,
      foregroundImage: url == null ? null : NetworkImage(url),
      child: Text(initiales, style: TextStyle(color: Couleurs.vert, fontWeight: FontWeight.w800, fontSize: rayon * 0.7)),
    );
  }
}

/// Pastille de statut colorée.
class Pastille extends StatelessWidget {
  const Pastille(this.texte, {super.key, this.couleur = Couleurs.vert});

  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
        child: Text(texte, style: TextStyle(color: couleur, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

void afficherMessage(BuildContext context, String message, {bool erreur = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: erreur ? Couleurs.erreur : Couleurs.texte,
      behavior: SnackBarBehavior.floating,
    ));
}
