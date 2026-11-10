import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';
import '../avis/avis.dart';

/// Profil, accès à « Modifier mon profil » (photo, prénom, nom, présentation) et déconnexion.
/// Préférences, contacts d'urgence, véhicules et documents se gèrent sur le site.
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  Future<void> _deconnecter(BuildContext context) async {
    final session = context.read<Session>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez saisir à nouveau votre identifiant et votre mot de passe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (ok == true) await session.deconnexion();
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<Session>().utilisateur;
    if (u == null) return const SizedBox.shrink();
    final role = switch (u.role) {
      'CONDUCTEUR' => (u.estFemme ? 'Conductrice' : 'Conducteur') + (u.conducteurValide ? (u.estFemme ? ' vérifiée' : ' vérifié') : ''),
      'ADMIN' => 'Administrateur',
      _ => u.estFemme ? 'Passagère' : 'Passager',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        Bloc(children: [
          Row(children: [
            Avatar(nom: u.nomComplet, photo: u.photoProfil, rayon: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.nomComplet, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(role, style: const TextStyle(color: Couleurs.texte2)),
                if (u.noteMoyenne != null)
                  Text('★ ${u.noteMoyenne!.toStringAsFixed(1).replaceAll('.', ',')} / 5',
                      style: const TextStyle(color: Couleurs.orange, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          if (u.bio != null) ...[
            const SizedBox(height: 12),
            Text('« ${u.bio} »', style: const TextStyle(color: Couleurs.texte2, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/profil/modifier'),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Modifier mon profil'),
            ),
          ),
          const Divider(height: 28),
          if (u.email != null) _ligne(Icons.mail_outline, u.email!),
          if (u.telephone != null) _ligne(Icons.phone_outlined, u.telephone!),
        ]),
        const SizedBox(height: 12),
        BlocReputation(idUtilisateur: u.id, titre: 'Avis reçus'),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: Couleurs.vert),
            title: const Text('Mes paiements', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Historique et reçus'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/paiements'),
          ),
        ),
        const SizedBox(height: 12),
        Bloc(children: [
          const Text('Préférences, contacts d\'urgence, véhicules et documents se gèrent sur le site web.',
              style: TextStyle(color: Couleurs.texte2)),
          TextButton.icon(
            onPressed: () => launchUrl(Uri.parse('${Config.siteUrl}/profil'), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir le site'),
          ),
        ]),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => _deconnecter(context),
          style: OutlinedButton.styleFrom(foregroundColor: Couleurs.erreur),
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
        ),
        const SizedBox(height: 16),
        const Center(child: Logo(taille: 18)),
        const LiensLegaux(),
      ]),
    );
  }

  Widget _ligne(IconData icone, String texte) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Icon(icone, size: 20, color: Couleurs.texte2), const SizedBox(width: 10), Text(texte)]),
      );
}
