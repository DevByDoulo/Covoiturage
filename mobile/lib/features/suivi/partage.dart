import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api.dart';
import '../../core/itineraire.dart';
import '../../core/localisation.dart';

/// Rythme des envois (comme sur le site) : au plus toutes les 5 s, dès 15 m de déplacement, au moins toutes les
/// 20 s à l'arrêt.
const _intervalleMin = Duration(seconds: 5);
const _intervalleMax = Duration(seconds: 20);
const _deplacementMinM = 15.0;

/// 08 — Partage de la position du conducteur avec ses passagers (`POST /api/trajets/{id}/position`). Service global :
/// le partage continue quand le conducteur change d'écran et, sur téléphone, appli en arrière-plan (notification
/// permanente sur Android). Il s'arrête avec « Arrêter le partage », ou si le serveur le refuse.
class PartagePosition extends ChangeNotifier {
  PartagePosition(this._api, this._positions, {DateTime Function()? horloge}) : _maintenant = horloge ?? DateTime.now;

  final Api _api;
  final PositionActuelle _positions;
  final DateTime Function() _maintenant;

  /// Trajet dont la position est partagée (null : pas de partage).
  int? idTrajet;
  DateTime? dernierEnvoi;
  String? erreur;

  StreamSubscription<PositionSuivie>? _abonnement;
  ({PositionSuivie position, DateTime instant})? _envoye;
  PositionSuivie? _enAttente;
  Timer? _differe;
  bool _envoiEnCours = false;

  bool partage(int id) => idTrajet == id;

  void demarrer(int id) {
    if (idTrajet == id) return;
    arreter(effacer: false);
    idTrajet = id;
    erreur = null;
    notifyListeners();
    _abonnement = _positions.suivre(arrierePlan: true).listen(
          (p) => recevoir(id, p),
          onError: (Object e) {
            erreur = e is LocalisationImpossible ? e.message : 'Position introuvable.';
            arreter(effacer: false);
          },
        );
  }

  /// [effacer] : supprime aussi la position côté serveur (les passagers ne la voient plus).
  void arreter({bool effacer = true}) {
    final id = idTrajet;
    _abonnement?.cancel();
    _abonnement = null;
    _differe?.cancel();
    _differe = null;
    _enAttente = null;
    _envoye = null;
    idTrajet = null;
    dernierEnvoi = null;
    notifyListeners();
    if (effacer && id != null) _api.delete('/trajets/$id/position').catchError((_) {});
  }

  /// Nouvelle position du GPS (publique pour les tests).
  @visibleForTesting
  void recevoir(int id, PositionSuivie p) {
    final maintenant = _maintenant();
    final precedent = _envoye;
    final ecart = precedent == null ? null : maintenant.difference(precedent.instant);
    final deplace = precedent == null ||
        distanceM((latitude: precedent.position.latitude, longitude: precedent.position.longitude),
                (latitude: p.latitude, longitude: p.longitude)) >=
            _deplacementMinM;
    if (precedent != null && deplace && ecart! < _intervalleMin) {
      // Trop tôt : envoyée à la fin du délai (sinon, voiture à l'arrêt, le GPS ne redonne plus de position et la
      // dernière ne partirait jamais).
      _enAttente = p;
      _differe ??= Timer(_intervalleMin - ecart, () {
        _differe = null;
        final derniere = _enAttente;
        _enAttente = null;
        if (derniere != null && idTrajet == id) recevoir(id, derniere);
      });
      return;
    }
    final attendu = precedent == null || ecart! >= _intervalleMax || (ecart >= _intervalleMin && deplace);
    if (!attendu || _envoiEnCours) return;
    _enAttente = null;
    _envoye = (position: p, instant: maintenant);
    _envoyer(id, p);
  }

  Future<void> _envoyer(int id, PositionSuivie p) async {
    _envoiEnCours = true;
    try {
      await _api.post('/trajets/$id/position', {
        'latitude': p.latitude,
        'longitude': p.longitude,
        'precisionM': p.precisionM,
        if (p.cap != null) 'cap': p.cap,
        if (p.vitesse != null) 'vitesse': p.vitesse,
      });
      erreur = null;
      dernierEnvoi = _maintenant();
    } on ErreurApi catch (e) {
      erreur = e.message;
      // Refus définitif (trop tôt, trajet terminé ou annulé) : on arrête le partage.
      if (e.status == 409 || e.status == 403 || e.status == 404) {
        _envoiEnCours = false;
        arreter(effacer: false);
        erreur = e.message;
      }
    } catch (_) {
      erreur = 'Réseau indisponible : nouvel essai à la prochaine position.';
    } finally {
      _envoiEnCours = false;
      notifyListeners();
    }
  }
}
