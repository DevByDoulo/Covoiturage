import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CONTACT_LEGAL, PageLegale } from './page-legale';

/**
 * Politique de confidentialité (route publique /confidentialite). Elle décrit ce que fait réellement la plateforme :
 * à mettre à jour avec chaque fonctionnalité qui collecte ou transmet des données.
 */
@Component({
  selector: 'app-confidentialite',
  imports: [PageLegale, RouterLink],
  template: `
    <app-page-legale titre="Politique de confidentialité">
      <p>Cette page explique quelles données personnelles YOBALEMAsn utilise, pourquoi, avec qui elles sont partagées,
        combien de temps elles sont gardées et comment exercer vos droits. Elle s'applique au site et à l'application
        mobile, et complète les <a routerLink="/conditions">conditions d'utilisation</a>.</p>

      <nav class="legal__sommaire" aria-label="Sommaire">
        <strong>Sommaire</strong>
        <ol>
          <li><a [routerLink]="[]" fragment="responsable">Qui est responsable de vos données</a></li>
          <li><a [routerLink]="[]" fragment="donnees">Les données utilisées et pourquoi</a></li>
          <li><a [routerLink]="[]" fragment="position">Votre position</a></li>
          <li><a [routerLink]="[]" fragment="visibilite">Ce que voient les autres utilisateurs</a></li>
          <li><a [routerLink]="[]" fragment="tiers">Services extérieurs</a></li>
          <li><a [routerLink]="[]" fragment="conservation">Durées de conservation</a></li>
          <li><a [routerLink]="[]" fragment="securite">Sécurité</a></li>
          <li><a [routerLink]="[]" fragment="navigateur">Stockage dans votre navigateur</a></li>
          <li><a [routerLink]="[]" fragment="droits">Vos droits</a></li>
          <li><a [routerLink]="[]" fragment="modifications">Modifications</a></li>
        </ol>
      </nav>

      <h2 id="responsable">1. Qui est responsable de vos données</h2>
      <p>Les données sont traitées par l'équipe du projet <strong>YOBALEMAsn</strong>, projet de fin d'études réalisé à
        l'ISEP de Diamniadio. Contact pour toute question ou demande sur vos données :
        <a [href]="'mailto:' + contact">{{ contact }}</a>.</p>
      <p>Ce traitement respecte la <strong>loi sénégalaise n° 2008-12 du 25 janvier 2008</strong> sur la protection des
        données à caractère personnel. Nous ne vendons pas vos données et ne les utilisons pas pour de la publicité.</p>

      <h2 id="donnees">2. Les données utilisées et pourquoi</h2>
      <div class="legal__tableau">
        <table>
          <thead>
            <tr><th>Données</th><th>Pourquoi</th></tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Compte</strong> : prénom, nom, email, téléphone, mot de passe (enregistré chiffré, jamais en
                clair), identifiant Google si vous vous connectez avec Google</td>
              <td>Créer et sécuriser votre compte, vous connecter, vérifier votre email ou téléphone par un code, vous
                prévenir des événements importants.</td>
            </tr>
            <tr>
              <td><strong>Profil</strong> (facultatif) : photo, présentation, sexe, préférences de trajet (musique, tabac,
                animaux, discussion), contacts d'urgence</td>
              <td>Présenter votre profil aux autres membres ; le sexe sert uniquement aux trajets « réservés aux
                femmes » ; les contacts d'urgence ne sont visibles que par vous.</td>
            </tr>
            <tr>
              <td><strong>Conducteur</strong> : véhicules (marque, modèle, immatriculation, photo, consommation), permis
                de conduire, pièce d'identité, carte grise</td>
              <td>Vérifier que vous pouvez conduire et que le véhicule est en règle (vérification par un
                administrateur) ; estimer le prix du trajet.</td>
            </tr>
            <tr>
              <td><strong>Trajets et réservations</strong> : lieux de départ, d'arrivée et d'étape, dates, places, prix,
                statut, code d'embarquement</td>
              <td>Publier, rechercher et réserver des trajets ; confirmer l'embarquement ; envoyer les rappels.</td>
            </tr>
            <tr>
              <td><strong>Paiements</strong> : moyen choisi, montant, référence et statut de la transaction</td>
              <td>Suivre le paiement, rembourser en cas d'annulation, fournir des reçus. Aucun code secret ni numéro de
                carte n'est enregistré par YOBALEMAsn.</td>
            </tr>
            <tr>
              <td><strong>Messages et avis</strong></td>
              <td>Permettre aux membres d'un trajet de s'organiser, et de se noter après le voyage.</td>
            </tr>
            <tr>
              <td><strong>Notifications</strong> : historique des notifications, jeton de notification de votre appareil
                (si vous les activez)</td>
              <td>Vous prévenir (réservation, message, rappel avant le départ…).</td>
            </tr>
            <tr>
              <td><strong>Sécurité</strong> : date de dernière connexion, adresse IP au moment des tentatives de
                connexion</td>
              <td>Limiter les tentatives répétées (blocage après 5 échecs) et protéger les comptes. Les adresses IP ne
                sont gardées qu'en mémoire, le temps de ce contrôle.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h2 id="position">3. Votre position</h2>
      <p>La position de votre appareil n'est utilisée <strong>que si vous l'autorisez</strong> dans votre navigateur ou
        votre téléphone, et seulement pour ces usages :</p>
      <ul>
        <li><strong>« Ma position »</strong> : remplir le lieu de départ d'une recherche ou d'un trajet. Les coordonnées
          servent à retrouver l'adresse ; elles ne sont enregistrées que si vous publiez ou réservez avec ce lieu.</li>
        <li><strong>Guidage vocal</strong> jusqu'au point de rendez-vous : votre position est suivie sur votre appareil
          tant que la page est ouverte, et envoyée au service d'itinéraire (voir plus bas) pour calculer le chemin.
          YOBALEMAsn ne l'enregistre pas.</li>
        <li><strong>Partage en direct par le conducteur</strong> : seulement quand le conducteur l'active, à partir d'une
          heure avant le départ. Seule sa <strong>dernière position</strong> est gardée (pas d'historique), visible
          uniquement par ses passagers confirmés, et <strong>effacée</strong> dès qu'il arrête le partage, à la fin ou à
          l'annulation du trajet, et au plus tard 30 minutes après le dernier envoi.</li>
      </ul>

      <h2 id="visibilite">4. Ce que voient les autres utilisateurs</h2>
      <ul>
        <li>Votre <strong>prénom</strong>, l'<strong>initiale de votre nom</strong>, votre photo, votre note moyenne et
          les avis reçus.</li>
        <li>Pour un conducteur : le véhicule (marque, modèle, année, photo), <strong>sans</strong> l'immatriculation ni
          les documents.</li>
        <li>Votre email, votre téléphone, vos documents et vos contacts d'urgence <strong>ne sont pas montrés</strong> aux
          autres membres. Les échanges passent par la messagerie de la plateforme.</li>
        <li>Les <strong>administrateurs</strong> voient les informations nécessaires à la vérification des documents et à
          la modération (fiche utilisateur, documents, historique des décisions).</li>
      </ul>

      <h2 id="tiers">5. Services extérieurs</h2>
      <p>Certaines fonctions s'appuient sur des services extérieurs, qui reçoivent uniquement ce qui leur est utile :</p>
      <div class="legal__tableau">
        <table>
          <thead>
            <tr><th>Service</th><th>Usage</th><th>Données transmises</th></tr>
          </thead>
          <tbody>
            <tr><td>PayDunya, Wave, Orange Money</td><td>Paiement en ligne et remboursement</td>
              <td>Montant et référence de la réservation ; numéro de téléphone du passager en cas de remboursement
                (le paiement lui-même se fait chez l'opérateur)</td></tr>
            <tr><td>Google</td><td>Connexion avec un compte Google (si vous la choisissez)</td>
              <td>Échange d'identification géré par Google</td></tr>
            <tr><td>Service d'envoi d'emails et de SMS</td><td>Codes de vérification, notifications importantes</td>
              <td>Email ou téléphone, contenu du message</td></tr>
            <tr><td>OpenStreetMap (tuiles de carte, recherche d'adresses Nominatim)</td><td>Afficher la carte, trouver une
              adresse</td><td>Adresse tapée ou coordonnées du point cherché, adresse IP de l'appareil</td></tr>
            <tr><td>Serveurs d'itinéraires OSRM de l'association FOSSGIS</td><td>Guidage vocal</td>
              <td>Position de départ et point de rendez-vous, sans votre nom</td></tr>
            <tr><td>Open-Meteo</td><td>Météo prise en compte dans le prix</td>
              <td>Coordonnées du départ du trajet, sans donnée sur vous</td></tr>
            <tr><td>Firebase (Google)</td><td>Notifications sur l'appareil, si activées</td>
              <td>Jeton de l'appareil, titre et texte de la notification</td></tr>
          </tbody>
        </table>
      </div>

      <h2 id="conservation">6. Durées de conservation</h2>
      <ul>
        <li><strong>Compte, profil, trajets, réservations, messages, avis</strong> : tant que votre compte existe. Un compte
          désactivé reste conservé (vous pouvez le réactiver en vous reconnectant). Pour une
          <strong>suppression définitive</strong>, écrivez-nous : nous la faisons dans un délai d'un mois, sauf les
          éléments que nous devons garder pour un litige en cours ou une obligation légale (par exemple les justificatifs
          de paiement).</li>
        <li><strong>Documents du conducteur</strong> : tant que vous proposez des trajets ; supprimés sur demande.</li>
        <li><strong>Codes de vérification</strong> : quelques minutes (durée de validité du code).</li>
        <li><strong>Session</strong> : jusqu'à la fermeture de l'onglet, ou 30 jours au plus si vous cochez « Rester
          connecté ».</li>
        <li><strong>Position partagée en direct</strong> : jusqu'à l'arrêt du partage ou la fin du trajet, 30 minutes au
          plus après le dernier envoi.</li>
      </ul>

      <h2 id="securite">7. Sécurité</h2>
      <ul>
        <li>Mots de passe chiffrés de façon irréversible ; connexions protégées par des jetons de courte durée.</li>
        <li>Blocage temporaire après 5 tentatives de connexion échouées.</li>
        <li>Documents et fonctions d'administration accessibles seulement aux administrateurs.</li>
        <li>Échanges chiffrés (HTTPS) une fois le service mis en ligne.</li>
      </ul>
      <p>Aucun système n'est parfaitement sûr : si une fuite de données vous concernant devait arriver, nous vous en
        informerions.</p>

      <h2 id="navigateur">8. Stockage dans votre navigateur</h2>
      <p>YOBALEMAsn n'utilise <strong>ni cookie publicitaire ni outil de mesure d'audience</strong>. Le site garde
        seulement dans votre navigateur : votre session (pour rester connecté), le choix « voix activée ou coupée » du
        guidage et, pendant une vérification par code, l'étape en cours.</p>

      <h2 id="droits">9. Vos droits</h2>
      <p>Vous pouvez à tout moment :</p>
      <ul>
        <li><strong>accéder</strong> à vos données et en obtenir une copie ;</li>
        <li>les <strong>corriger</strong> (la plupart se modifient directement dans « Mon profil ») ;</li>
        <li>vous <strong>opposer</strong> à un usage ou demander leur <strong>suppression</strong> ;</li>
        <li>retirer votre autorisation de géolocalisation dans les réglages de votre navigateur ou de votre téléphone.</li>
      </ul>
      <p>Écrivez à <a [href]="'mailto:' + contact">{{ contact }}</a> depuis l'adresse de votre compte ; nous répondons
        sous un mois. Si vous n'êtes pas satisfait de notre réponse, vous pouvez saisir la
        <strong>Commission de protection des données personnelles</strong> (CDP) du Sénégal.</p>
      <p>La plateforme est réservée aux personnes majeures : nous ne collectons pas sciemment de données sur des
        mineurs.</p>

      <h2 id="modifications">10. Modifications</h2>
      <p>Cette politique est mise à jour quand la plateforme évolue. La date de version figure en haut de la page ; un
        changement important (nouvel usage de vos données) sera annoncé avant de s'appliquer.</p>
    </app-page-legale>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Confidentialite {
  protected readonly contact = CONTACT_LEGAL;
}
