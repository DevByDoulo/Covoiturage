import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

/// Taille maximale acceptée par le serveur pour une photo (comme sur le site).
const tailleMaxPhoto = 5 * 1024 * 1024;

/// Ouvre la galerie ou l'appareil photo ; remplaçable dans les tests.
typedef ChoisirImage = Future<XFile?> Function(ImageSource source);

Future<XFile?> _choisirAvecImagePicker(ImageSource source) =>
    // Image réduite et réencodée en JPEG (aussi pour les photos HEIC de l'iPhone) : légère et acceptée par le serveur.
    ImagePicker().pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);

/// « Modifier mon profil », comme sur le site (en-tête et bloc « À propos ») : photo, prénom, nom et présentation.
/// L'email et le téléphone ne se modifient pas (le site ne le permet pas non plus) : ils servent à se connecter.
class ModifierProfilPage extends StatefulWidget {
  const ModifierProfilPage({super.key, this.choisirImage = _choisirAvecImagePicker});

  final ChoisirImage choisirImage;

  @override
  State<ModifierProfilPage> createState() => _ModifierProfilPageState();
}

class _ModifierProfilPageState extends State<ModifierProfilPage> {
  final _formulaire = GlobalKey<FormState>();
  late final TextEditingController _prenom;
  late final TextEditingController _nom;
  late final TextEditingController _bio;

  bool _envoi = false;
  bool _envoiPhoto = false;
  String? _erreur;
  String? _erreurPhoto;
  Map<String, String> _erreursChamps = const {};

  @override
  void initState() {
    super.initState();
    final u = context.read<Session>().utilisateur;
    _prenom = TextEditingController(text: u?.prenom ?? '');
    _nom = TextEditingController(text: u?.nom ?? '');
    _bio = TextEditingController(text: u?.bio ?? '');
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _changerPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
        ]),
      ),
    );
    if (source == null || !mounted) return;
    final session = context.read<Session>();
    setState(() => _erreurPhoto = null);
    try {
      final image = await widget.choisirImage(source);
      if (image == null) return;
      final octets = await image.readAsBytes();
      if (octets.length > tailleMaxPhoto) {
        if (mounted) setState(() => _erreurPhoto = 'La photo dépasse 5 Mo. Choisissez une image plus légère.');
        return;
      }
      if (mounted) setState(() => _envoiPhoto = true);
      await session.changerPhoto(octets, image.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo de profil mise à jour.')));
      }
    } on ErreurApi catch (e) {
      if (mounted) setState(() => _erreurPhoto = e.message);
    } on PlatformException {
      // Accès aux photos ou à la caméra refusé.
      if (mounted) setState(() => _erreurPhoto = "Autorisez l'accès aux photos ou à la caméra dans les réglages du téléphone.");
    } catch (e) {
      if (mounted) setState(() => _erreurPhoto = ErreurApi.messageDe(e));
    } finally {
      if (mounted) setState(() => _envoiPhoto = false);
    }
  }

  Future<void> _enregistrer() async {
    if (!_formulaire.currentState!.validate()) return;
    final session = context.read<Session>();
    setState(() {
      _envoi = true;
      _erreur = null;
      _erreursChamps = const {};
    });
    try {
      await session.modifierProfil(prenom: _prenom.text, nom: _nom.text, bio: _bio.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour.')));
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = ErreurApi.messageDe(e);
          if (e is ErreurApi) _erreursChamps = e.erreurs;
        });
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  static String? _requis(String? v, String libelle) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$libelle obligatoire.';
    if (t.length > 80) return '80 caractères au plus.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<Session>().utilisateur;
    if (u == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: Form(
        key: _formulaire,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Center(
            child: Stack(children: [
              Avatar(nom: u.nomComplet, photo: u.photoProfil, rayon: 52),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: Couleurs.vert,
                  shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 3)),
                  child: IconButton(
                    tooltip: 'Changer la photo de profil',
                    onPressed: _envoiPhoto ? null : _changerPhoto,
                    icon: _envoiPhoto
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.photo_camera, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('JPEG, PNG ou WebP, 5 Mo au plus', style: TextStyle(color: Couleurs.texte2, fontSize: 12.5)),
          ),
          if (_erreurPhoto != null) ...[const SizedBox(height: 12), Bandeau(_erreurPhoto!)],
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('prenom'),
            controller: _prenom,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.givenName],
            decoration: InputDecoration(
                labelText: 'Prénom', prefixIcon: const Icon(Icons.person_outline), errorText: _erreursChamps['prenom']),
            validator: (v) => _requis(v, 'Prénom'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('nom'),
            controller: _nom,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.familyName],
            decoration: InputDecoration(
                labelText: 'Nom', prefixIcon: const Icon(Icons.badge_outlined), errorText: _erreursChamps['nom']),
            validator: (v) => _requis(v, 'Nom'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('bio'),
            controller: _bio,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Présentation',
              hintText: 'Trajets fréquents Dakar – Thiès, conduite prudente…',
              alignLabelWithHint: true,
              errorText: _erreursChamps['bio'],
            ),
          ),
          const SizedBox(height: 4),
          Bloc(children: [
            if (u.email != null) _ligne(Icons.mail_outline, u.email!),
            if (u.telephone != null) _ligne(Icons.phone_outlined, u.telephone!),
            const SizedBox(height: 4),
            const Text("L'email et le numéro de téléphone servent à vous connecter : ils ne se modifient pas ici.",
                style: TextStyle(color: Couleurs.texte2, fontSize: 13)),
          ]),
          if (_erreur != null) ...[const SizedBox(height: 12), Bandeau(_erreur!)],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _envoi ? null : _enregistrer,
            child: _envoi
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ]),
      ),
    );
  }

  Widget _ligne(IconData icone, String texte) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icone, size: 20, color: Couleurs.texte2),
          const SizedBox(width: 10),
          Expanded(child: Text(texte)),
        ]),
      );
}
