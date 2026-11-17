import 'modeles.dart';

/// Nombre maximal d'escales par trajet (même limite que le site et l'API : `@Size(max = 5)`).
const maxEscales = 5;

/// Une escale en cours de saisie : [id] stable (pour garder le bon champ de texte quand on réordonne) ;
/// [lieu] est null tant que l'adresse n'est pas choisie.
class EscaleSaisie {
  EscaleSaisie(this.id, [this.lieu]);

  final int id;
  Lieu? lieu;
}

/// Liste ordonnée des escales d'un trajet à publier : ajout, suppression, déplacement, et conversion vers le
/// format de l'API (`escales: [{lieu, latitude, longitude}]`, dans l'ordre du trajet).
class EscalesSaisies {
  final List<EscaleSaisie> _liste = [];
  int _suivant = 0;

  List<EscaleSaisie> get liste => List.unmodifiable(_liste);
  int get nombre => _liste.length;
  bool get plein => _liste.length >= maxEscales;

  /// Une escale sans adresse bloque l'estimation et la publication.
  bool get complete => _liste.every((e) => e.lieu != null);

  /// Ajoute une escale vide et la renvoie ; null si la limite est atteinte.
  EscaleSaisie? ajouter() {
    if (plein) return null;
    final e = EscaleSaisie(_suivant++);
    _liste.add(e);
    return e;
  }

  void retirer(int index) {
    if (index >= 0 && index < _liste.length) _liste.removeAt(index);
  }

  void definir(int index, Lieu lieu) {
    if (index >= 0 && index < _liste.length) _liste[index].lieu = lieu;
  }

  /// Échange l'escale [index] avec sa voisine ([delta] = -1 : plus tôt, +1 : plus tard). Renvoie le nouvel index.
  int deplacer(int index, int delta) {
    final cible = index + delta;
    if (index < 0 || index >= _liste.length || cible < 0 || cible >= _liste.length) return index;
    final e = _liste.removeAt(index);
    _liste.insert(cible, e);
    return cible;
  }

  /// Points pour l'API ; ignore les escales sans adresse.
  List<Map<String, dynamic>> pourApi() => [
        for (final e in _liste)
          if (e.lieu != null) {'lieu': e.lieu!.libelle, 'latitude': e.lieu!.latitude, 'longitude': e.lieu!.longitude},
      ];

  /// Repères de la carte, numérotés dans l'ordre (1, 2…).
  List<(Lieu, String)> reperes() => [
        for (var i = 0; i < _liste.length; i++)
          if (_liste[i].lieu != null) (_liste[i].lieu!, '${i + 1}'),
      ];
}
