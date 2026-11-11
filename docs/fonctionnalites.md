# YOBALEMAsn — détail des fonctionnalités réalisées

Historique détaillé de chaque module (branches, tables, API, écrans, règles). Déplacé hors de `CLAUDE.md` le
10/11/2026 pour que ce fichier, lu à chaque session, reste court. **Le compléter à chaque fonctionnalité.**

## Modules

Le 27/10/2026, la répartition a changé et le dépôt **repart de l'authentification**. Tout le reste a été retiré
du code ; l'ancienne version complète (backend du lot 1, écrans Trajets et Recherche avec carte Leaflet,
alertes de recherche, prix par formule, réservations, notifications, back-office) reste consultable et
récupérable sous l'**étiquette Git `archive/lot1-complet`** (`git show archive/lot1-complet:<chemin>`, ou
`git checkout archive/lot1-complet -- <dossier>` pour reprendre un module).

**Fait :**
- Backend (`auth`, `utilisateur`, `common`, `admin`) : inscription avec code par email (ou SMS), connexion
  email/téléphone/Google, jetons JWT + refresh (rotation), blocage après 5 échecs, mot de passe oublié en
  3 étapes (code vérifié, puis jeton de 10 min ; comptes inconnus non révélés ; quotas de codes par compte et
  par IP ; alerte au titulaire après changement) ; profil, préférences, photo (`/api/moi`) ; compte admin
  créé au démarrage.
- **01 Gestion des utilisateurs** (branche `01-utilisateurs`) : écran *Mon profil* (`features/profil`) — photo,
  À propos, préférences de trajet (enregistrées à chaque bascule), contacts d'urgence (table `contact_urgence`,
  3 au plus), changer / définir le mot de passe (`/profil/mot-de-passe`), désactiver le compte
  (`/profil/desactivation`, réactivé à la connexion suivante). Les compteurs de la maquette (trajets, avis)
  viendront avec les modules 03 et 05.
- **02 Gestion des véhicules** (branche `02-vehicules`, partie de `01-utilisateurs`) : module backend `vehicule`
  (repris de l'archive et adapté) — véhicules avec photo, documents permis / **pièce d'identité** / carte grise
  (migration V2026_10_27_1100) ; écran *Véhicules et documents* (`features/vehicules`) : liste, ajout et
  modification, envoi et renvoi des pièces, motif de refus. La validation des pièces par l'admin relève du
  module 07 : appeler `VehiculeService.recalculerStatutConducteur` après chaque décision.
- Frontend : connexion (case **« Rester connecté »**, décochée par défaut : jeton de rafraîchissement en
  `sessionStorage`, session terminée à la fermeture de l'onglet ; cochée : `localStorage`, 30 jours — branche
  `web-rester-connecte`), inscription, vérification du code, mot de passe oublié (3 écrans successifs),
  téléphone après Google ; espace connecté (`features/espace`, barre de navigation + déconnexion) et page
  d'accueil simple (`/accueil`) ; l'administrateur arrive sur le back-office (`/admin`).
- **Textes légaux** (branche `pages-legales`) : pages publiques `/conditions` et `/confidentialite`
  (`features/legal`, cadre commun `page-legale.ts` : contact `CONTACT_LEGAL`, date `VERSION_LEGALE`), liens depuis
  l'inscription, le pied des écrans de connexion, le profil, et dans l'appli mobile (`LiensLegaux`, qui ouvre le
  site). Éditeur présenté comme projet de fin d'études (ISEP Diamniadio), loi sénégalaise n° 2008-12, CDP.
  Mise à jour du 10/11/2026 (branche `legal-position-mobile`) : partage de position **en arrière-plan** depuis l'appli
  mobile (suivi du conducteur pendant le trajet, arrêt à la fin du trajet, position supprimée ensuite) ajouté aux
  conditions (§10) et à la confidentialité (§3 et §6) ; `VERSION_LEGALE` = « 10 novembre 2026 ».
  **À mettre à jour** (texte et date de version) à chaque fonctionnalité qui collecte ou transmet des données, ou
  qui change les règles (commission, annulation). Pas encore de suppression automatique des comptes : elle se fait
  sur demande, comme l'indique la politique.
- La base garde **toutes les tables** du diagramme de classes (migration V1, à ne jamais modifier) : chaque
  module les reprend ou les fait évoluer par de nouvelles migrations datées.
- **12 Calcul automatique du prix** (branche `12-prix`) : module backend `tarification` (repris de l'archive :
  `MoteurFormule`, coefficients `parametre_tarification` ; sans l'entité `Tarification`, liée à `Trajet`, qui
  reviendra avec le module 03) + `MoteurIA` : appelle `ia-tarification` (`POST /v1/estimations`) puis la
  formule ; repli sur la formule seule si erreur, réponse incohérente ou plus de 2 s (`app.ia.delai`), et pause
  de 30 s après un échec. Consommation : déclarée > prédite par l'IA > estimée ; la météo s'applique toujours.
  Service `ia-tarification` : XGBoost sur ADEME Car Labelling (MAE 0,35 L/100 km), Open-Meteo attendu 1,5 s au
  plus. En dev, `IA_TARIFICATION_URL` vaut `http://localhost:8000` ; en test, formule seule. À brancher dans
  `TrajetService` (module 03) : `moteur.estimer(new DemandeEstimation(...))`.
- **03 Gestion des trajets** (branche `03-trajets`, partie de `12-prix`) : module backend `trajet` repris de
  l'archive (publication avec escales, estimation du prix via `MoteurTarification`, modification, annulation,
  démarrer/terminer, « mes trajets », recherche PostGIS publique, détail public ; itinéraire Google Routes si
  `GOOGLE_MAPS_API_KEY`, sinon vol d'oiseau ×1,25). `pom.xml` : `hibernate-spatial` remis. Écrans Angular
  `features/trajets` (publier avec carte Leaflet et détail du prix IA, détail, mes trajets) et
  `features/recherche` ; Leaflet ajouté (`package.json`, `angular.json`). Les **alertes de recherche** sont décrites
  plus bas (branche `alertes-recherche`).
- **06 Notifications** (branche `06-notifications`, partie de `07-administration`) : module backend `notification`
  (repris de l'archive) — `NotificationService.notifier(destinataire, type, priorite, titre, contenu, lien)` :
  enregistrée dans `notification` (lien vers l'écran, migration V2026_10_28_0900), push FCM si l'appareil a
  envoyé son jeton (`FIREBASE_CREDENTIALS_PATH`, sinon journalisé), et **email (sinon SMS) si `Priorite.IMPORTANTE`**.
  `NotificationsActivite` écoute `ReservationEvenements`, `TrajetModifie` et `AvisPublie` (« Nouvel avis : 4/5 », lien
  vers `/profil`, qui affiche les avis reçus) avant validation de la transaction ;
  `RappelsTrajet` prévient conducteur et passagers 1 h avant le départ (toutes les 5 min, sans doublon) ; les
  décisions de l'admin passent aussi par là. Écrans : cloche avec compteur dans l'en-tête (rafraîchi toutes les
  30 s) et `/notifications`. Reste : push dans le navigateur (projet Firebase à créer).
- **Alertes de recherche** (branche `alertes-recherche`, complète le module 03) : package backend `recherche` repris
  de l'archive (table `alerte_recherche`, migration V2026_10_25_1600) — `/api/moi/alertes` (créer, lister, supprimer ;
  10 alertes à venir au plus). À la publication d'un trajet (`TrajetPublie`, après validation de la transaction,
  sans jamais faire échouer la publication), chaque alerte du même jour dont le départ et l'arrivée sont proches
  du tracé, dans le bon sens, reçoit une notification `ALERTE_TRAJET` (lien vers le trajet ; prix max et
  « femmes uniquement » respectés). Écran : bouton « Créer une alerte » sous les résultats de Rechercher et bloc
  « Mes alertes » (`features/alertes`).
  **Appli mobile** (branche `mobile-alertes`) : mêmes écrans dans `mobile/lib/features/alertes` (`AlertesService`,
  `BoutonCreerAlerte` sous les résultats de Rechercher, `BlocMesAlertes`) ; pas de rayon ni de prix max côté mobile
  (valeurs par défaut du serveur).
- **07 Administration** (branche `07-administration`) : back-office `/admin` avec son propre cadre (menu latéral,
  `features/admin`) — tableau de bord (statistiques), **validation des documents** (file filtrable, aperçu du
  fichier, informations à vérifier, valider / refuser avec motif obligatoire ; `recalculerStatutConducteur`
  appelé à chaque décision), liste et **fiche utilisateur** (véhicules, documents, historique), **bloquer /
  bannir** avec motif obligatoire et **débloquer** (sessions fermées). Chaque décision est enregistrée dans
  `action_admin` et envoyée à l'utilisateur par email (ou SMS) via `AvisUtilisateurs` ; `utilisateur.derniere_connexion`
  est mis à jour à chaque émission de jetons (migration V2026_10_27_1500). Le raccourci de développement
  `POST /api/dev/moi/valider-conducteur` (module 03) a été retiré : l'admin valide désormais les documents.
- **04 Facturation** (branche `04-facturation`) : comprend aussi les **réservations** (non attribuées dans la
  répartition ; reprises de l'archive). Package `reservation` (demande avec moyen de paiement, acceptation/refus,
  annulation, embarquement PIN/QR, événements `ReservationEvenements` à écouter par le module 06) et package
  `facturation` (`FournisseurPaiement` : **Wave réel** via l'API Checkout + webhook signé
  `/api/paiements/webhooks/wave` ; `OrangeMoneyFournisseur` **non branché** : l'API Sonatel n'est documentée qu'aux
  comptes du portail developer.orange-sonatel.com ; historique `/api/moi/paiements`, reçus). Règles **provisoires,
  à confirmer avec l'encadrant** : aucune commission, remboursement intégral de toute annulation avant le départ.
  Wave exige HTTPS (clés `WAVE_API_KEY`, `WAVE_SECRET_WEBHOOK`, `PAIEMENT_URL_RETOUR`) : en local, tunnel ngrok.
  Écrans : réserver (détail d'un trajet), demandes et embarquement (conducteur), `/reservations`, `/paiements`, reçu.
  **QR code d'embarquement sur le site** (branche `web-qr-embarquement`) : le passager voit le QR sous son code
  (`shared/ui/qr-code.ts`, bibliothèque `qrcode` chargée à la demande) ; le conducteur peut le scanner
  (`shared/ui/scanner-qr.ts` : caméra arrière, `BarcodeDetector` du navigateur sinon `jsqr` chargé à la demande ;
  bouton affiché seulement si une caméra est accessible, c'est-à-dire en HTTPS ou sur localhost).
  **PayDunya** (branche `04-paydunya`) : agrégateur qui relaie **Wave et Orange Money Sénégal** (`PayDunyaClient`,
  `PayDunyaFournisseur`, un bean par moyen dans `PayDunyaConfig`). Clés `PAYDUNYA_MASTER_KEY`, `PAYDUNYA_PRIVATE_KEY`,
  `PAYDUNYA_TOKEN`, `PAYDUNYA_MODE` (`test` = sandbox, sans argent réel). Facture « paiement avec redirection »
  limitée au canal choisi ; IPN `/api/paiements/webhooks/paydunya` (formulaire, `data[hash]` = SHA-512 de la clé
  principale), envoyé seulement si `PAIEMENT_URL_API` (adresse publique de l'API) est renseignée ; dans tous les cas,
  l'état est redemandé à PayDunya (`checkout-invoice/confirm`) et vérifié au retour du passager
  (`POST /api/paiements/{ref}/verifier`). Remboursement par déboursement vers le portefeuille du passager : production
  seulement (en test, le paiement reste « remboursement demandé »). Si Wave direct est aussi configuré, il passe avant
  PayDunya pour Wave (pas de frais d'intermédiaire). `paiement.fournisseur` vaut `PAYDUNYA`, `WAVE`… 
- **05 Évaluations et avis** (branche `05-avis`) : package `avis`, table `evaluation` (migration
  V2026_10_28_1400, classe EVALUATION). Après un voyage effectué (réservation `TERMINEE`), le passager note son
  conducteur et le conducteur note ce passager : 1 à 5 étoiles + commentaire, une fois par sens, dans les 14 jours
  suivant le départ ; chaque avis recalcule `utilisateur.note_moyenne` (filtre « note minimale » de la recherche).
  API `POST /api/reservations/{id}/evaluation`, `GET /api/moi/avis-a-donner`, `GET /api/utilisateurs/{id}/avis`
  (public). Événement `AvisEvenements.AvisPublie`, notifié à la personne notée (module 06). Écrans `features/avis` : bloc
  « Donnez votre avis » (Mes réservations, Mes trajets), réputation du conducteur (détail d'un trajet).
  Les **signalements** (classe SIGNALEMENT) sont décrits plus bas (module 10). Le profil (module 01) peut afficher
  `GET /api/utilisateurs/{id}/avis` pour son compteur d'avis.
- **10 Signalements** (branche `signalements`) : package backend `signalement`, table `signalement` (migration
  V2026_11_10_1400, classe SIGNALEMENT : motif, description, statut, décision de l'administrateur, dates, signaleur,
  personne visée, administrateur, trajet facultatif). La même migration ajoute `AVERTISSEMENT` et `SIGNALEMENT_CLASSE`
  au journal `action_admin`. **Règles** : on ne signale que quelqu'un avec qui on a partagé un trajet (réservation
  acceptée ou terminée, passager ↔ conducteur ; `ReservationRepository.ontPartageUnTrajet`), jamais soi-même ni un
  administrateur ; un seul signalement ouvert (`EN_ATTENTE` / `EN_COURS`) par couple signaleur → signalé (index unique
  partiel) ; 5 signalements par jour et par signaleur au plus (constante `SignalementService.MAX_PAR_JOUR`, 429) ;
  motifs `COMPORTEMENT`, `CONDUITE_DANGEREUSE`, `NON_PRESENTATION`, `ANNULATION_TARDIVE`, `FRAUDE_DOCUMENTS`,
  `HARCELEMENT`, `AUTRE` (description de 500 caractères, obligatoire pour `AUTRE`) ; pas de pièce jointe ni de
  suspension automatique (la décision reste humaine). **Modération** : `PRENDRE_EN_CHARGE` (→ `EN_COURS`) puis une
  décision motivée : `CLASSER_SANS_SUITE` (→ `REJETE`), `AVERTIR` (notification importante au signalé), `BLOQUER` ou
  `BANNIR` (réutilisent `AdminService`, qui trace, ferme les sessions et prévient) — ces trois dernières donnent
  `TRAITE`. Chaque décision est inscrite dans l'historique du compte signalé (`AdminService.tracerDecision`) et le
  signaleur reçoit une notification `SIGNALEMENT_TRAITE` ; il ne voit jamais le détail de la décision, et le signalé ne
  voit jamais l'identité du signaleur. API : `POST /api/signalements`, `GET /api/signalements/mes`, et pour les
  administrateurs `GET /api/admin/signalements` (filtres `statut`, `utilisateur`, pagination),
  `GET /api/admin/signalements/{id}`, `PATCH /api/admin/signalements/{id}` (`{decision, message}`).
  **Site** (`features/signalements`) : lien « Signaler … » (`BoutonSignaler`) dans Mes réservations (conducteur) et
  dans les demandes reçues par le conducteur (passagers) → `/signaler/:idUtilisateur?trajet=&nom=` (motif +
  description) ; `/signalements` (Mes signalements). **Back-office** : `/admin/signalements` (menu « Signalements »,
  filtre par statut, prise en charge, décision motivée) et lien « Voir les signalements visant cet utilisateur » sur la
  fiche utilisateur (`?utilisateur=`). **Mobile** (`lib/features/signalements/signalements.dart`) : bouton « Signaler … »
  sur Mes réservations et sur les passagers d'un trajet du conducteur, formulaire, « Mes signalements » depuis le
  Profil ; la modération reste sur le site. Tests : `SignalementsParcoursTest`, `signalements.models.spec.ts`,
  `test/signalements_test.dart`.
- **09 Messagerie** (fonctionnalité facultative, branche `09-messagerie`) : package `messagerie`, tables `conversation`
  (une par trajet et par passager ; le conducteur est celui du trajet) et `message` (migration V2026_10_29_1000).
  Un passager écrit au conducteur d'un trajet à venir (même sans réserver) ou d'un trajet réservé ; le conducteur
  écrit aux passagers qui ont réservé ; on peut écrire jusqu'à 7 jours après le départ (ensuite lecture seule) ;
  30 messages au plus par 10 minutes. API `POST /api/trajets/{id}/conversation`, `/api/moi/conversations` (liste,
  `/non-lus`, `/{id}` qui marque lus, `/{id}/messages`). Événement `MessageEnvoye` → notification `MESSAGE_RECU`
  (une seule non lue par conversation). Écrans `features/messages` : icône Messages avec compteur dans l'en-tête,
  `/messages`, `/messages/:id` (rafraîchi toutes les 5 s), bouton « Écrire à … » (détail d'un trajet, Mes
  réservations, demandes reçues par le conducteur).
- **08 Géolocalisation** (fonctionnalité facultative, branche `08-geolocalisation`) : la carte, la recherche de lieu,
  le départ et l'arrivée posés sur la carte, le tracé et la distance existaient déjà (modules 03 et 12). Ajouts :
  service `core/carte/position-actuelle.ts` (API de géolocalisation du navigateur : HTTPS ou localhost, autorisation de
  l'utilisateur, messages en cas de refus / délai / indisponibilité) ; bouton « Ma position » sur le champ Départ
  (`ChampLieu` avec `[maPosition]="true"`, Publier et Rechercher) qui retrouve l'adresse (Nominatim) et prévient si la
  position est approximative (> 500 m) ; lien « Itinéraire vers le point de départ (Google Maps) » sur le détail d'un
  trajet, pour le passager. **Guidage vocal** (branche `web-guidage-vocal`) : écran `/trajets/:id/guidage`
  (`features/trajets/guidage`) — passager vers son point de prise en charge, conducteur vers le départ ; à pied ou
  en voiture ; position suivie (`PositionActuelle.suivre`, `watchPosition`), itinéraire et manœuvres OSRM des
  serveurs FOSSGIS `routing.openstreetmap.de` (sans clé, CORS ; à remplacer en production), consignes en français
  (`core/carte/itineraire.ts`), logique d'annonce et de recalcul hors tracé dans `core/carte/guide.ts` (testée),
  synthèse vocale du navigateur (`core/voix.ts`, coupable, choix mémorisé), écran gardé allumé (Wake Lock).
  La carte (`shared/carte/carte.ts`) a des marqueurs `moi` / `voiture` et un mode `[suivre]`.
  **Suivi du conducteur en temps réel** (branche `suivi-temps-reel`) : package backend `suivi`, table
  `position_conducteur` (migration V2026_11_06_2130, une ligne par trajet : la dernière position). Le conducteur
  partage à partir d'une heure avant le départ jusqu'à la fin (`POST /api/trajets/{id}/position`, `DELETE` pour
  arrêter) ; seuls lui et les passagers `ACCEPTEE` lisent (`GET`, 204 si rien depuis 30 min). Position effacée à
  l'arrêt, à `TrajetTermine` / `TrajetAnnule`, et purgée après 30 min ; au premier envoi, notification
  `POSITION_PARTAGEE` aux passagers (lien `/trajets/{id}/suivi`). Écrans `features/suivi` : bloc « Position en
  direct » du conducteur (détail de son trajet ; service global `PartagePosition`, au plus un envoi toutes les
  5 s, position différée envoyée à la fin du délai) et page passager `/trajets/:id/suivi` (interrogée toutes les
  5 s, voiture sur la carte, distance à vol d'oiseau et heure estimée, annonces vocales à 2 km, 1 km, 500 m,
  200 m puis « … est au point de rendez-vous ») ; lien « Suivre … en direct » dans Mes réservations.
- **Application mobile** (branche `mobile-passager`, dossier `mobile/`, voir [`mobile/README.md`](mobile/README.md)) :
  Flutter, même API que le site. Premier lot = parcours passager : connexion / inscription / code, recherche sur
  carte (`flutter_map` + OpenStreetMap, Nominatim, « Ma position »), détail et réservation, mes réservations (code
  d'embarquement PIN + QR, paiement PayDunya, annulation), notifications, profil en lecture. Lancer :
  `flutter run -d web-server --web-port 5000` (navigateur), `flutter run` (émulateur Android, API sur `10.0.2.2`),
  ou `--dart-define=API_URL=http://<IP du PC>:8080/api` pour un vrai téléphone. **Parcours conducteur** (branche
  `mobile-conducteur`, onglet « Conduire », `lib/features/conducteur`) : mes trajets, publier (estimation IA, curseur
  dans la fourchette ; sans escales), mon trajet (accepter / refuser, embarquement par QR code `mobile_scanner` ou
  PIN, démarrer / terminer / annuler). **Messagerie** (branche `mobile-messagerie`, `lib/features/messages`) : icône
  Messages avec compteur, conversations rafraîchies toutes les 5 s, boutons « Écrire à … ». **Avis** (branche
  `mobile-avis`, `lib/features/avis`) : « Donnez votre avis » (Mes réservations, Mes trajets), réputation (détail
  d'un trajet, Profil). **Guidage vocal et suivi en direct** (branche `mobile-guidage-suivi`) : mêmes écrans que le
  site (`lib/features/guidage`, `lib/features/suivi`, logique `lib/core/guide.dart` et `itineraire.dart` portée du
  site et testée), voix `flutter_tts`, écran allumé `wakelock_plus` ; le partage du conducteur continue appli en
  arrière-plan (Android : service au premier plan avec notification ; iOS : `UIBackgroundModes` `location`).
  **Mot de passe oublié** (branche `mobile-mot-de-passe-oublie`, `lib/features/auth/mot_de_passe_oublie.dart`) : lien « Mot de passe oublié ? » sous la connexion, puis les 3 étapes du site (email ou téléphone → code à 6 chiffres, 5 essais, renvoi après le délai → nouveau mot de passe, même règle que l’inscription) via `Session` (`/api/auth/mot-de-passe/oublie`, `/verifier-code`, `/reinitialiser`) ; retour à la connexion avec un message de confirmation.
  **Paiements et reçus** (branche `mobile-paiements`, `lib/features/paiements/paiements.dart`) : entrée « Mes paiements » dans le Profil → `/paiements` (historique `/api/moi/paiements` : paiements comme passager en −, encaissements comme conducteur en + avec total encaissé, moyen, statut, référence ; tirer pour rafraîchir) et `/paiements/:reference/recu` (reçu `/api/paiements/{ref}/recu`, mêmes rubriques que le site, bandeau « Remboursé intégralement le … »), seulement pour les paiements réussis ou remboursés. À la place de « Imprimer / PDF » du site : bouton « Copier le reçu » (texte à coller dans un message ; pas de dépendance PDF).
  **Modification du profil** (branche `mobile-profil`, `lib/features/profil/modifier_profil.dart`) : bouton « Modifier mon profil » dans le Profil → `/profil/modifier`, comme l'en-tête et le bloc « À propos » du site : photo (galerie ou appareil photo via `image_picker`, réduite à 1024 px et réencodée en JPEG, 5 Mo au plus, envoyée tout de suite en multipart à `POST /api/moi/photo` via `Api.envoyerFichier`), prénom, nom et présentation (500 caractères) enregistrés par `PUT /api/moi` (`Session.modifierProfil`, sexe renvoyé inchangé, présentation vide → `null`) ; erreurs du serveur affichées sous le bon champ. Email et téléphone affichés sans pouvoir les modifier : ni le site ni l'API ne le permettent (ce sont les identifiants de connexion ; un changement demanderait une nouvelle vérification par code). La présentation s'affiche dans le Profil. iOS : `NSPhotoLibraryUsageDescription` ajouté.
  **Test sur téléphone Android** (branche `mobile-test-telephone`) : icône d'application (repère vert du logo, icône adaptative Android 8+ et monochrome, générée par `mobile/tool/generer_icone.py`), nom « YOBALEMAsn » (déjà dans le manifeste), script `mobile/tool/lancer-telephone.ps1` qui détecte l'IP Wi-Fi du PC et lance `flutter run --dart-define=API_URL=… --dart-define=SITE_URL=…` (aucune adresse dans le dépôt), liste de contrôle [`docs/test-telephone-android.md`](test-telephone-android.md) (connexion, réservation, QR d'embarquement, guidage vocal, partage de position écran éteint). Le pare-feu Windows doit autoriser le port 8080.
  **Signalements** (branche `signalements`) : voir le module 10.
  Reste : push, Google.
- Tests : `./mvnw test` → 44 tests (dont `SignalementsParcoursTest`, `ParcoursCompletTest`, `SuiviPositionParcoursTest`, `TrajetsParcoursTest`, `AlertesRechercheParcoursTest`,
  `ReservationsPaiementsParcoursTest`, `AvisParcoursTest`, `MessagerieParcoursTest`, `PayDunyaParcoursTest`,
  `WaveFournisseurTest`, `PayDunyaFournisseurTest`) ; `npm test` → 50 tests ; `flutter test` dans `mobile` → 36 tests ;
  `python -m pytest` dans `ia-tarification` → 20 tests. Dans les tests d'intégration, utiliser des numéros de
  téléphone uniques : ils partagent la base, et l'immatriculation de test reprend les 4 derniers chiffres.

