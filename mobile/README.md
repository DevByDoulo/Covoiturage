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

Pas encore fait : messagerie, avis, notifications push (Firebase), escales à la publication.

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
| `lib/features` | un dossier par écran : `auth`, `recherche`, `trajet`, `reservations`, `conducteur`, `notifications`, `profil` |
| `lib/app.dart` | routes (`go_router`) et barre d'onglets |

Les erreurs de l'API (ProblemDetail) sont lues par `ErreurApi`. Sur le web, éviter l'opérateur `~` sur des
entiers (résultat non signé) : voir `decoderPolyline`.

## Vérifier

```bash
flutter analyze
flutter test
```
