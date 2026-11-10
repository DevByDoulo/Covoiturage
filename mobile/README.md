# YOBALEMAsn — application mobile (Flutter)

Application Android / iOS du covoiturage, branchée sur la même API que le site web (`backend/Convoiturage`).

## Premier lot : parcours passager

- Connexion (email ou téléphone), inscription, vérification du code reçu par email ou SMS ; session gardée
  (refresh token dans le stockage sécurisé, renouvelé une fois sur 401).
- **Rechercher** : départ et arrivée (recherche Nominatim, « Ma position », ou toucher la carte), date,
  nombre de places ; résultats avec tracé et distances de prise en charge et de dépose.
- **Détail d'un trajet** : carte, itinéraire vers le point de départ (Google Maps), conducteur, réservation
  avec le moyen de paiement (espèces, Wave, Orange Money selon ce que le backend propose).
- **Mes réservations** : statut, code d'embarquement (PIN + QR), paiement en ligne via PayDunya puis
  « J'ai payé : vérifier », annulation.
- **Notifications** : liste, pastille du nombre de non lues (rafraîchie toutes les 30 s), ouverture du lien.
- **Profil** : lecture seule et déconnexion ; le reste se gère sur le site.
- **Mes paiements** (depuis le Profil) : historique des paiements et encaissements, reçu de chaque paiement
  réussi ou remboursé, avec « Copier le reçu ».

## Deuxième lot : parcours conducteur (onglet « Conduire »)

- **Mes trajets** : à venir / passés, statut et places réservées. Un compte qui n'est pas encore conducteur
  (ou dont les pièces sont en vérification) voit comment le devenir : véhicule et pièces se déposent sur le site.
- **Publier** : départ et arrivée (recherche, « Ma position » ou carte), date et heure, véhicule validé, places,
  route nationale ou autoroute (péages), réservation sur validation ou immédiate, bagages, souplesse, « réservé
  aux femmes » pour une conductrice. « Calculer le prix » appelle `/trajets/estimation` (IA + formule) : prix
  recommandé, curseur dans la fourchette, détail des coûts ; puis publication. Les escales se gèrent sur le site.
- **Mon trajet** : carte, passagers (accepter / refuser avec motif), **embarquement** par QR code
  (`mobile_scanner`, caméra) ou code à 6 chiffres, avec le montant à encaisser en espèces ; démarrer (une heure
  avant le départ au plus tôt), terminer, annuler avec motif. Depuis le détail public d'un de ses trajets, le
  bouton « Gérer ce trajet » y mène.

## Messagerie

- Icône **Messages** (avec le nombre de non lus, rafraîchi toutes les 30 s) dans la barre de titre des onglets :
  liste des conversations, la plus récente en haut.
- **Conversation** : bulles, rafraîchie toutes les 5 s, envoi ; lecture seule une fois la conversation fermée
  (le backend donne la raison).
- Boutons **« Écrire à … »** : détail d'un trajet (au conducteur), Mes réservations (au conducteur), Mon trajet
  (à chaque passager). La notification « Nouveau message » ouvre la conversation.

Un lien direct ou une notification ouverts pendant la restauration de la session mènent bien à l'écran demandé ;
s'il n'y a pas d'écran en dessous, le bouton retour ramène à l'accueil.

## Avis

- **« Donnez votre avis »** en haut de Mes réservations (le passager note son conducteur) et de Mes trajets (le
  conducteur note ses passagers), pour chaque voyage terminé pas encore noté : 1 à 5 étoiles et un commentaire
  facultatif, avant la date limite (14 jours après le départ).
- **Réputation** (moyenne, nombre d'avis, répartition, derniers avis) : « Avis sur … » dans le détail d'un trajet,
  « Avis reçus » dans le Profil.

## Guidage vocal et suivi du conducteur en direct

Mêmes règles que sur le site (`/trajets/:id/guidage` et `/trajets/:id/suivi`).

- **Guidage vocal** (`lib/features/guidage`) : passager vers son point de prise en charge (détail d'un trajet),
  conducteur vers le départ (Mon trajet) ; à pied ou en voiture. Position suivie (`PositionActuelle.suivre`),
  itinéraire OSRM (`lib/core/itineraire.dart`), annonces et recalcul (`lib/core/guide.dart`, testé), voix
  `flutter_tts` (`lib/core/voix.dart`, coupable), écran gardé allumé (`wakelock_plus`).
- **Partage de position du conducteur** (`lib/features/suivi/partage.dart`, service global) : bloc « Position en
  direct » dans Mon trajet, à partir d'une heure avant le départ. **Continue appli en arrière-plan** : service au
  premier plan avec notification sur Android (`FOREGROUND_SERVICE_LOCATION`), localisation en arrière-plan sur iOS
  (`UIBackgroundModes` `location`). Un envoi toutes les 5 s au plus ; la position reçue trop tôt part à la fin du délai.
- **Suivi par le passager** (`lib/features/suivi/suivi_conducteur.dart`) : « Suivre … en direct » dans Mes
  réservations ou depuis la notification ; voiture sur la carte (`lib/shared/carte_direct.dart`, qui suit un point
  sans se reconstruire), distance, heure estimée, annonces vocales à 2 km, 1 km, 500 m, 200 m puis à l'arrivée.

Pas encore fait : notifications push (Firebase), escales à la publication,
connexion Google, modification du profil.

## Lancer

Prérequis : Flutter 3.41+ (`flutter doctor`), backend lancé sur le port 8080.

```bash
flutter pub get
```

Dans le navigateur (le plus simple pour tester ; le port 5000 est autorisé par le CORS du backend) :

```bash
flutter run -d web-server --web-port 5000
```

Émulateur Android (l'adresse `10.0.2.2` désigne le PC, c'est la valeur par défaut) :

```bash
flutter run
```

Vrai téléphone sur le même Wi-Fi que le PC :

```bash
flutter run --dart-define=API_URL=http://<IP du PC>:8080/api
```

Adresse du site (liens « Véhicules et documents ») : `--dart-define=SITE_URL=http://<IP du PC>:4200`.

Pour Android, il faut d'abord installer les *Android SDK Command-line Tools* (Android Studio → SDK Manager)
puis accepter les licences avec `flutter doctor --android-licenses`.

## Organisation

| Dossier | Contenu |
|---|---|
| `lib/core` | configuration, client HTTP (`api.dart`), modèles, session, thème, formats, géolocalisation |
| `lib/shared` | widgets communs, carte (`flutter_map`, tuiles OpenStreetMap) |
| `lib/features` | un dossier par écran : `auth`, `recherche`, `trajet`, `reservations`, `conducteur`, `messages`, `avis`, `guidage`, `suivi`, `notifications`, `profil` |
| `lib/app.dart` | routes (`go_router`) et barre d'onglets |

Les erreurs de l'API (ProblemDetail) sont lues par `ErreurApi`. Sur le web, éviter l'opérateur `~` sur des
entiers (résultat non signé) : voir `decoderPolyline`.

## Vérifier

```bash
flutter analyze
flutter test
```
