import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yobalema/core/modeles.dart';
import 'package:yobalema/features/messages/vocal.dart';

/// Faux enregistreur : compte les appels, renvoie un chemin à l'arrêt, niveau constant.
class FauxEnregistreur implements Enregistreur {
  bool autorise = true;
  int demarrages = 0, arrets = 0, annulations = 0, pauses = 0, reprises = 0;

  @override
  Future<bool> autorisation() async => autorise;

  @override
  Future<void> demarrer() async => demarrages++;

  @override
  Future<String?> arreter() async {
    arrets++;
    return '/tmp/vocal.m4a';
  }

  @override
  Future<void> pause() async => pauses++;

  @override
  Future<void> reprendre() async => reprises++;

  @override
  Future<void> annuler() async => annulations++;

  @override
  Future<int> niveau() async => 60;
}

/// Contrôleur sur l'horloge de fake_async.
(ControleurVocal, FauxEnregistreur, List<VocalEnregistre>) _controleur(FakeAsync async) {
  final faux = FauxEnregistreur();
  final envoyes = <VocalEnregistre>[];
  final c = ControleurVocal(faux, surEnvoi: (v) async => envoyes.add(v), maintenantMs: () => async.elapsed.inMilliseconds);
  return (c, faux, envoyes);
}

void main() {
  group('minuteur et utilitaires', () {
    test('formate la durée comme le lecteur', () {
      expect(formaterDuree(Duration.zero), '0:00');
      expect(formaterDuree(const Duration(milliseconds: 23400)), '0:23');
      expect(formaterDuree(const Duration(seconds: 83)), '1:23');
      expect(formaterDuree(dureeMax), '5:00');
      expect(formaterDureeTotale(const Duration(milliseconds: 2721)), '0:03');
      expect(formaterDureeTotale(const Duration(milliseconds: 299600)), '5:00');
    });

    test('convertit les décibels du micro en niveau de 0 à 100', () {
      expect(niveauDepuisDb(-160), 0);
      expect(niveauDepuisDb(-50), 0);
      expect(niveauDepuisDb(-25), 50);
      expect(niveauDepuisDb(0), 100);
      expect(niveauDepuisDb(double.negativeInfinity), 0);
    });

    test('réduit les niveaux à un nombre fixe de barres', () {
      expect(reduireNiveaux([]), isEmpty);
      expect(reduireNiveaux([5, 120]), [5, 100]);
      final barres = reduireNiveaux(List.generate(600, (i) => i % 100));
      expect(barres, hasLength(barresOnde));
      expect(barres.every((n) => n >= 0 && n <= 100), isTrue);
    });

    test('reconnaît le format audio à ses premiers octets', () {
      expect(extensionAudio([0x1A, 0x45, 0xDF, 0xA3, 0]), 'webm');
      expect(extensionAudio('OggS....'.codeUnits), 'ogg');
      expect(extensionAudio([0, 0, 0, 24, ...'ftypM4A '.codeUnits]), 'm4a');
      expect(extensionAudio([0xFF, 0xF1, 0x50]), 'aac');
      expect(typeMimeAudio('m4a'), 'audio/mp4');
    });

    test('lit un message vocal renvoyé par l’API', () {
      final m = MessageApp.depuisJson({
        'id': 9,
        'type': 'VOCAL',
        'contenu': null,
        'dureeMs': 23000,
        'formeOnde': [10, 50, 90],
        'audioDisponible': true,
        'dateEnvoi': '2026-11-18T10:00:00',
        'deMoi': false,
        'lu': true,
        'ecoute': true,
      });
      expect(m.vocal, isTrue);
      expect(m.contenu, isNull);
      expect(m.dureeMs, 23000);
      expect(m.formeOnde, [10, 50, 90]);
      expect(m.audioDisponible && m.ecoute, isTrue);
      final texte = MessageApp.depuisJson(
          {'id': 1, 'type': 'TEXTE', 'contenu': 'Bonjour', 'dateEnvoi': '2026-11-18T10:00:00', 'deMoi': true, 'lu': false});
      expect(texte.vocal, isFalse);
      expect(texte.formeOnde, isEmpty);
    });
  });

  group('états de l’enregistrement', () {
    test('maintenir enregistre, le minuteur avance, relâcher envoie', () {
      fakeAsync((async) {
        final (c, faux, envoyes) = _controleur(async);
        c.appuyer();
        async.flushMicrotasks();
        expect(c.etat, EtatVocal.enregistrement);
        expect(faux.demarrages, 1);
        async.elapse(const Duration(seconds: 3));
        expect(c.ecoule, const Duration(seconds: 3));
        expect(c.niveau, 60);
        c.relacher();
        async.flushMicrotasks();
        expect(c.etat, EtatVocal.inactif);
        expect(envoyes, hasLength(1));
        expect(envoyes.single.duree, const Duration(seconds: 3));
        expect(envoyes.single.chemin, '/tmp/vocal.m4a');
        expect(envoyes.single.niveaux.every((n) => n == 60), isTrue);
      });
    });

    test('un enregistrement de moins d’une seconde est ignoré', () {
      fakeAsync((async) {
        final (c, _, envoyes) = _controleur(async);
        c.appuyer();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 600));
        c.relacher();
        async.flushMicrotasks();
        expect(envoyes, isEmpty);
        expect(c.etat, EtatVocal.inactif);
        expect(c.info, contains('Maintenez'));
      });
    });

    test('glisser vers la gauche annule sans envoyer', () {
      fakeAsync((async) {
        final (c, faux, envoyes) = _controleur(async);
        c.appuyer();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        c.glisser(const Offset(-40, 0));
        expect(c.etat, EtatVocal.enregistrement);
        expect(c.glissement.dx, -40);
        c.glisser(const Offset(-seuilAnnulation - 1, 5));
        async.flushMicrotasks();
        expect(c.etat, EtatVocal.inactif);
        expect(faux.annulations, 1);
        c.relacher();
        async.flushMicrotasks();
        expect(envoyes, isEmpty);
      });
    });

    test('glisser vers le haut verrouille ; pause fige le minuteur ; Envoyer envoie', () {
      fakeAsync((async) {
        final (c, faux, envoyes) = _controleur(async);
        c.appuyer();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        c.glisser(const Offset(0, -seuilVerrouillage - 1));
        expect(c.etat, EtatVocal.verrouille);
        c.relacher(); // mains libres : relâcher n'envoie pas
        async.flushMicrotasks();
        expect(envoyes, isEmpty);
        async.elapse(const Duration(seconds: 3));
        c.mettreEnPause();
        async.flushMicrotasks();
        expect(c.etat, EtatVocal.pause);
        expect(faux.pauses, 1);
        async.elapse(const Duration(seconds: 10));
        expect(c.ecoule, const Duration(seconds: 5));
        c.reprendre();
        async.flushMicrotasks();
        expect(c.etat, EtatVocal.verrouille);
        async.elapse(const Duration(seconds: 1));
        c.envoyer();
        async.flushMicrotasks();
        expect(envoyes.single.duree, const Duration(seconds: 6));
        expect(c.etat, EtatVocal.inactif);
      });
    });

    test('Supprimer abandonne un enregistrement verrouillé', () {
      fakeAsync((async) {
        final (c, faux, envoyes) = _controleur(async);
        c.appuyer();
        async.flushMicrotasks();
        c.glisser(const Offset(0, -100));
        async.elapse(const Duration(seconds: 4));
        c.annuler();
        async.flushMicrotasks();
        expect(c.etat, EtatVocal.inactif);
        expect(faux.annulations, 1);
        expect(envoyes, isEmpty);
      });
    });

    test('à 5 minutes, l’enregistrement est envoyé automatiquement', () {
      fakeAsync((async) {
        final (c, _, envoyes) = _controleur(async);
        c.appuyer();
        async.flushMicrotasks();
        c.glisser(const Offset(0, -100));
        async.elapse(dureeMax - const Duration(seconds: 1));
        expect(envoyes, isEmpty);
        async.elapse(const Duration(seconds: 2));
        expect(envoyes, hasLength(1));
        expect(envoyes.single.duree, dureeMax);
        expect(c.etat, EtatVocal.inactif);
      });
    });

    test('micro refusé : message clair, rien ne démarre', () {
      fakeAsync((async) {
        final (c, faux, _) = _controleur(async);
        faux.autorise = false;
        c.appuyer();
        async.flushMicrotasks();
        expect(c.etat, EtatVocal.inactif);
        expect(faux.demarrages, 0);
        expect(c.info, contains('Autorisez le micro'));
      });
    });

    test('doigt relâché pendant la demande d’autorisation : rien n’est enregistré', () {
      fakeAsync((async) {
        final (c, faux, envoyes) = _controleur(async);
        c.appuyer();
        expect(c.etat, EtatVocal.autorisation);
        c.relacher();
        async.flushMicrotasks();
        expect(c.etat, EtatVocal.inactif);
        expect(faux.demarrages, 0);
        expect(envoyes, isEmpty);
      });
    });
  });
}
