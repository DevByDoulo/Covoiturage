# Test de l'appli mobile sur un téléphone Android

Liste de contrôle courte pour essayer YOBALEMAsn sur un vrai téléphone (testé sur un Galaxy A17, Android 17).
Cocher : ✅ conforme · ❌ anomalie (noter ce qui s'est passé + capture) · ⏭ non testé.

## 0. Préparation

1. PostgreSQL lancé, puis le backend : `mvn spring-boot:run -Dspring-boot.run.profiles=dev` dans `backend/Convoiturage`
   (il écoute sur toutes les interfaces, port 8080).
2. Téléphone et PC **sur le même Wi-Fi**. Le téléphone est branché en USB, débogage USB activé (`flutter devices`
   doit le lister).
3. Pare-feu Windows : autoriser les connexions entrantes sur le port **8080** (le profil du Wi-Fi est souvent
   « Public », qui bloque tout). Test : ouvrir `http://<IP du PC>:8080/api/trajets` dans le navigateur du téléphone ;
   une réponse (même 401) prouve que le PC est joignable.
4. Lancer l'appli, depuis `mobile/` (l'adresse IP du PC est détectée automatiquement, rien n'est écrit dans le dépôt) :

   ```powershell
   .\tool\lancer-telephone.ps1
   ```

   ou à la main : `flutter run --dart-define=API_URL=http://<IP du PC>:8080/api --dart-define=SITE_URL=http://<IP du PC>:4200`.
5. Comptes : un compte passager et un compte conducteur (documents validés par l'admin) de la base locale, créés
   au besoin sur le site. Pour un test à deux rôles, un seul téléphone suffit : se déconnecter / reconnecter, ou
   utiliser le site sur le PC pour l'autre rôle.
6. Au premier lancement, **accepter** la localisation (« Pendant l'utilisation ») et les notifications ; pour la
   caméra, au premier scan.

| Vérification de départ | ✓ |
|---|---|
| L'icône verte (repère + route) et le nom « YOBALEMAsn » apparaissent dans la liste des applications | |
| L'écran de connexion s'affiche sans message d'erreur réseau | |

## 1. Connexion

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| C1 | Se connecter avec le compte passager (email + mot de passe) | Arrivée sur l'onglet Rechercher, pas d'erreur réseau | |
| C2 | Mauvais mot de passe | Message d'erreur clair sous le champ | |
| C3 | Fermer l'appli (balayer) puis la rouvrir | Session conservée, pas de nouvelle connexion | |
| C4 | Profil → Se déconnecter | Retour à l'écran de connexion | |

## 2. Réservation

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| R1 | (Conducteur) publier un trajet de demain, ou en choisir un existant | Trajet visible dans la recherche | |
| R2 | (Passager) Rechercher : départ via « Ma position », arrivée, date, places | Résultats avec tracé sur la carte | |
| R3 | Ouvrir un trajet → Réserver (espèces) | Réservation créée, visible dans « Mes réservations » | |
| R4 | (Conducteur) Mon trajet → accepter la demande si besoin | Le passager reçoit une notification | |
| R5 | Annuler une réservation | Statut « annulée », place rendue | |

## 3. QR d'embarquement

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| Q1 | (Passager) Mes réservations → réservation acceptée | PIN à 6 chiffres + QR code lisible (luminosité suffisante) | |
| Q2 | (Conducteur) Mon trajet → Embarquement → Scanner, puis accepter la caméra | Caméra ouverte ; le QR du passager (affiché sur un autre écran ou téléphone) est reconnu | |
| Q3 | Saisie manuelle du code à 6 chiffres | Embarquement validé, montant à encaisser affiché | |
| Q4 | Scanner un QR étranger (autre application) | Message d'erreur, pas de plantage | |

## 4. Guidage vocal

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| G1 | (Passager) Détail d'un trajet → guidage vers le point de prise en charge | Itinéraire tracé, position bleue qui bouge avec vous | |
| G2 | Marcher quelques dizaines de mètres, volume du média activé | Annonces vocales en français | |
| G3 | S'écarter volontairement de l'itinéraire | Recalcul de l'itinéraire annoncé | |
| G4 | Refuser la localisation puis rouvrir l'écran | Message explicatif, pas de plantage | |
| G5 | L'écran reste allumé pendant le guidage | Pas de mise en veille | |

## 5. Partage de position écran éteint (conducteur)

Dans Mon trajet, le bloc « Position en direct » apparaît à partir d'**une heure avant le départ** : publier un
trajet qui part dans moins d'une heure.

| ID | Étapes | Résultat attendu | ✓ |
|---|---|---|---|
| P1 | (Conducteur) Mon trajet → activer « Position en direct » | Notification permanente « partage de position » dans la barre d'état | |
| P2 | Sur le PC (ou un 2ᵉ appareil), compte passager → Mes réservations → « Suivre … en direct » | La voiture apparaît sur la carte | |
| P3 | Éteindre l'écran du téléphone conducteur et se déplacer 3–5 min (marche ou voiture) | Le point continue de bouger côté passager, sans saccade de plus de ~10 s | |
| P4 | Passer sur une autre appli (WhatsApp…) | Le partage continue, notification toujours présente | |
| P5 | Samsung : Paramètres → Batterie → l'appli n'est pas « en veille profonde » (sinon la retirer de la liste) | Pas de coupure après 10 min d'écran éteint | |
| P6 | Arrêter le partage (ou terminer le trajet) | Notification disparue, le passager voit le suivi s'arrêter | |

Si le partage s'arrête écran éteint : vérifier l'autorisation de localisation (« Toujours » ou « Pendant l'utilisation »)
et l'optimisation de batterie de Samsung (P5) avant de conclure à un bogue.

## Dépannage

`flutter run` se lance en version de développement, qui autorise HTTP vers le PC
(`android/app/src/debug/AndroidManifest.xml`) ; la version de production reste en HTTPS.

| Symptôme | Cause probable |
|---|---|
| « Connexion impossible » / délai dépassé dès l'écran de connexion | Pare-feu (port 8080), Wi-Fi différent, ou backend arrêté |
| Les cartes restent grises | Pas d'accès Internet sur le téléphone (tuiles OpenStreetMap) |
| Photos de profil absentes | L'URL des fichiers dérive de `API_URL` : vérifier que l'adresse est bien celle du PC |
| `flutter devices` ne liste pas le téléphone | Câble de données, débogage USB, autorisation RSA à accepter sur le téléphone |
