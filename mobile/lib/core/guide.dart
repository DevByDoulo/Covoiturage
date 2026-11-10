import 'dart:math' as math;

import 'itineraire.dart';

class _Seuils {
  const _Seuils(this.loin, this.proche, this.passage, this.horsRoute);

  final double loin, proche, passage, horsRoute;
}

/// On prévient plus tôt en voiture.
const _seuils = {
  ModeDeplacement.pied: _Seuils(100, 25, 15, 40),
  ModeDeplacement.voiture: _Seuils(300, 60, 30, 60),
};

/// Positions consécutives loin du tracé avant de recalculer (évite les faux écarts du GPS).
const _ecartsAvantRecalcul = 3;

class EtatGuidage {
  EtatGuidage(this.annonces, this.prochaine, this.distanceProchaineM, this.distanceRestanteM, this.arrive, this.horsRoute);

  /// Phrases à lire maintenant, dans l'ordre.
  final List<String> annonces;
  final Etape? prochaine;
  final double distanceProchaineM;
  final double distanceRestanteM;
  final bool arrive;

  /// Écart au tracé : il faut recalculer l'itinéraire.
  final bool horsRoute;
}

/// 08 — Guidage pas à pas (même logique que `core/carte/guide.ts` du site) : « Dans 300 mètres, tournez à droite… »,
/// puis « Tournez à droite… » au moment de tourner, virages rapprochés enchaînés, arrivée dite une fois, recalcul
/// hors du tracé. Logique pure, testée dans test/guide_test.dart.
class Guide {
  Guide(this.itineraire, ModeDeplacement mode) : _s = _seuils[mode]! {
    if (itineraire.etapes.length < 2) _index = itineraire.etapes.length - 1;
  }

  final Itineraire itineraire;
  final _Seuils _s;
  int _index = 1;
  final _dites = <String>{};
  int _ecarts = 0;
  bool _termine = false;
  double _plusProche = double.infinity;

  String annonceDepart() {
    final minutes = math.max(1, (itineraire.dureeS / 60).round());
    final premiere = itineraire.etapes.isEmpty ? null : itineraire.etapes.first.instruction;
    return 'Itinéraire calculé : ${distanceParlee(itineraire.distanceM)}, environ $minutes minute${minutes > 1 ? 's' : ''}.'
        '${premiere == null ? '' : ' $premiere.'}';
  }

  EtatGuidage avancer(Coord p) {
    final etapes = itineraire.etapes;
    final annonces = <String>[];

    if (!_termine) {
      _ecarts = distanceAuTraceM(p, itineraire.trace) > _s.horsRoute ? _ecarts + 1 : 0;

      Etape? etape = _index < etapes.length ? etapes[_index] : null;
      var d = etape == null ? 0.0 : distanceM(p, etape.coord);
      _plusProche = math.min(_plusProche, d);

      // Manœuvre dépassée : consigne déjà dite et on s'en éloigne, ou déjà engagé sur le tronçon suivant
      // (le GPS ne passe pas toujours à quelques mètres du point exact).
      bool depassee() {
        final courante = etapes[_index];
        final suivante = _index + 1 < etapes.length ? etapes[_index + 1] : null;
        if (courante.arrivee || !_dites.contains('$_index:proche')) return false;
        return d > _plusProche + _s.passage ||
            (suivante != null && distanceM(p, suivante.coord) < distanceM(courante.coord, suivante.coord));
      }

      while (etape != null) {
        if (etape.arrivee) {
          if (d <= _s.proche) {
            annonces.add('${etape.instruction}.');
            _termine = true;
          }
          break;
        }
        if (d > _s.passage && !depassee()) break;
        if (!_dites.contains('$_index:proche')) annonces.add(_consigne(_index));
        _index++;
        etape = _index < etapes.length ? etapes[_index] : null;
        d = etape == null ? 0 : distanceM(p, etape.coord);
        _plusProche = d;
      }
      if (!_termine && etape != null) {
        if (!etape.arrivee && d <= _s.proche && !_dites.contains('$_index:proche')) {
          annonces.add(_consigne(_index));
        } else if (d <= _s.loin && d > _s.proche && !_dites.contains('$_index:loin')) {
          _dites.add('$_index:loin');
          annonces.add(etape.arrivee
              ? 'Le point de rendez-vous est à ${distanceParlee(d)}.'
              : 'Dans ${distanceParlee(d)}, ${_minuscule(etape.instruction)}.');
        }
      }
    }

    final prochaine = _termine || _index >= etapes.length ? null : etapes[_index];
    final distanceProchaine = prochaine == null ? 0.0 : distanceM(p, prochaine.coord);
    final resteApres = etapes.skip(_index).fold<double>(0, (s, e) => s + e.distanceM);
    return EtatGuidage(annonces, prochaine, distanceProchaine, _termine ? 0 : distanceProchaine + resteApres, _termine,
        !_termine && _ecarts >= _ecartsAvantRecalcul);
  }

  /// Consigne au moment de la manœuvre ; si la suivante arrive juste après, on l'enchaîne (« … puis … »).
  String _consigne(int i) {
    final etapes = itineraire.etapes;
    _dites.add('$i:proche');
    var phrase = etapes[i].instruction;
    final suivante = i + 1 < etapes.length ? etapes[i + 1] : null;
    if (suivante != null && !suivante.arrivee && etapes[i].distanceM < _s.loin / 2) {
      _dites
        ..add('${i + 1}:loin')
        ..add('${i + 1}:proche');
      phrase += ', puis ${_minuscule(suivante.instruction)}';
    }
    return '$phrase.';
  }
}

String _minuscule(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
