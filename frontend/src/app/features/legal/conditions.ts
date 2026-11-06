import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CONTACT_LEGAL, PageLegale } from './page-legale';

/** Conditions générales d'utilisation (route publique /conditions). */
@Component({
  selector: 'app-conditions',
  imports: [PageLegale, RouterLink],
  template: `
    <app-page-legale titre="Conditions générales d'utilisation">
      <p class="legal__note">
        YOBALEMAsn est un <strong>projet de fin d'études</strong> réalisé à l'ISEP de Diamniadio. Le service est proposé
        à titre de démonstration : il n'est pas exploité par une société commerciale. Les paiements en ligne fonctionnent
        en mode test (aucun argent réel n'est débité) tant que l'équipe ne l'a pas annoncé autrement.
      </p>

      <nav class="legal__sommaire" aria-label="Sommaire">
        <strong>Sommaire</strong>
        <ol>
          <li><a [routerLink]="[]" fragment="objet">Objet et acceptation</a></li>
          <li><a [routerLink]="[]" fragment="service">Ce que fait YOBALEMAsn</a></li>
          <li><a [routerLink]="[]" fragment="compte">Compte utilisateur</a></li>
          <li><a [routerLink]="[]" fragment="conducteur">Devenir conducteur</a></li>
          <li><a [routerLink]="[]" fragment="trajets">Publier un trajet et prix</a></li>
          <li><a [routerLink]="[]" fragment="reservations">Réserver, payer, embarquer</a></li>
          <li><a [routerLink]="[]" fragment="annulation">Annulations et remboursements</a></li>
          <li><a [routerLink]="[]" fragment="comportement">Règles de conduite</a></li>
          <li><a [routerLink]="[]" fragment="avis">Messagerie, avis</a></li>
          <li><a [routerLink]="[]" fragment="position">Position et suivi en direct</a></li>
          <li><a [routerLink]="[]" fragment="sanctions">Suspension et fermeture du compte</a></li>
          <li><a [routerLink]="[]" fragment="responsabilite">Responsabilités</a></li>
          <li><a [routerLink]="[]" fragment="modification">Modification des conditions</a></li>
          <li><a [routerLink]="[]" fragment="droit">Droit applicable et contact</a></li>
        </ol>
      </nav>

      <h2 id="objet">1. Objet et acceptation</h2>
      <p>Les présentes conditions encadrent l'utilisation du site et de l'application mobile YOBALEMAsn (« la
        plateforme »). En créant un compte, vous déclarez les avoir lues et les accepter, ainsi que la
        <a routerLink="/confidentialite">politique de confidentialité</a>. Si vous ne les acceptez pas, n'utilisez pas
        la plateforme.</p>

      <h2 id="service">2. Ce que fait YOBALEMAsn</h2>
      <p>YOBALEMAsn met en relation des <strong>conducteurs</strong> qui ont des places libres dans leur véhicule et des
        <strong>passagers</strong> qui font le même trajet, au Sénégal, pour <strong>partager les frais</strong> du voyage
        (carburant, usure, péages).</p>
      <ul>
        <li>La plateforme n'est <strong>pas un transporteur</strong> ni une compagnie de taxi : elle ne fournit ni véhicule
          ni chauffeur. Le trajet est réalisé sous la responsabilité du conducteur.</li>
        <li>Le covoiturage ne doit pas être une activité lucrative : le prix par place sert à partager les frais du
          trajet, pas à rémunérer le conducteur.</li>
        <li>La plateforme ne prélève aujourd'hui <strong>aucune commission</strong>.</li>
      </ul>

      <h2 id="compte">3. Compte utilisateur</h2>
      <ul>
        <li>La plateforme est réservée aux personnes <strong>majeures (18 ans et plus)</strong>.</li>
        <li>Vous devez donner des informations exactes (nom, prénom, téléphone, email) et les tenir à jour. Votre numéro
          ou votre adresse email est vérifié par un code à usage unique.</li>
        <li>Votre compte est personnel. Gardez votre mot de passe secret ; toute action faite avec votre compte est
          réputée faite par vous. Prévenez-nous sans attendre si vous pensez qu'il a été utilisé par quelqu'un d'autre.</li>
        <li>Sur un appareil partagé, ne cochez pas « Rester connecté » et déconnectez-vous après usage.</li>
        <li>Vous pouvez désactiver votre compte depuis votre profil (il est réactivé à la connexion suivante) ou demander
          sa suppression à l'adresse de contact.</li>
      </ul>

      <h2 id="conducteur">4. Devenir conducteur</h2>
      <p>Pour proposer des trajets, vous devez :</p>
      <ul>
        <li>détenir un <strong>permis de conduire valide</strong> pour le véhicule utilisé ;</li>
        <li>envoyer votre permis, votre pièce d'identité et la carte grise du véhicule : un administrateur les vérifie
          avant que vous puissiez publier ;</li>
        <li>utiliser un véhicule en bon état, <strong>assuré</strong> et autorisé à circuler, et respecter le nombre de
          places prévu par la carte grise ;</li>
        <li>signaler toute modification (nouveau véhicule, permis suspendu ou retiré). Un document faux ou périmé
          entraîne le refus ou la suspension du compte.</li>
      </ul>

      <h2 id="trajets">5. Publier un trajet et prix</h2>
      <ul>
        <li>Le conducteur indique le départ, l'arrivée, d'éventuelles étapes, la date, l'heure, le nombre de places et ses
          conditions (bagages, réservation immédiate ou sur validation, trajet réservé aux femmes pour une conductrice).</li>
        <li>La plateforme <strong>propose un prix par place</strong> calculé à partir de la distance, du véhicule (consommation
          déclarée ou estimée par un modèle d'intelligence artificielle), du prix du carburant, des péages, de l'heure et
          de la météo. Le conducteur peut l'ajuster dans la fourchette proposée.</li>
        <li>Le conducteur s'engage à faire le trajet publié, à l'heure annoncée (dans la marge indiquée), ou à l'annuler
          le plus tôt possible.</li>
      </ul>

      <h2 id="reservations">6. Réserver, payer, embarquer</h2>
      <ul>
        <li>Le passager choisit un trajet, le nombre de places et son moyen de paiement. Selon le choix du conducteur, la
          réservation est confirmée tout de suite ou après son accord.</li>
        <li>Paiement : <strong>en espèces</strong> au conducteur au moment de monter, ou <strong>en ligne</strong> par Wave
          ou Orange Money (par l'intermédiaire de PayDunya) quand ces moyens sont proposés. La plateforme ne conserve
          aucun code secret ni numéro de carte.</li>
        <li>Au départ, le passager présente son <strong>code d'embarquement</strong> (code à 6 chiffres ou QR code) au
          conducteur, qui le valide dans la plateforme. Ce code est personnel : ne le communiquez pas avant de monter.</li>
      </ul>

      <h2 id="annulation">7. Annulations et remboursements</h2>
      <ul>
        <li>Le passager peut annuler sa réservation <strong>avant le départ</strong> : un paiement en ligne est alors
          <strong>remboursé intégralement</strong> sur le portefeuille utilisé.</li>
        <li>Si le conducteur annule le trajet, les passagers sont prévenus et intégralement remboursés.</li>
        <li>Ces règles sont provisoires : elles pourront évoluer (délais, frais d'annulation tardive) ; les changements
          seront annoncés avant de s'appliquer.</li>
      </ul>

      <h2 id="comportement">8. Règles de conduite</h2>
      <p>Chacun s'engage à :</p>
      <ul>
        <li>être ponctuel et prévenir en cas de retard ou d'empêchement ;</li>
        <li>respecter le code de la route, les autres usagers et les préférences annoncées (musique, tabac, animaux…) ;</li>
        <li>ne transporter ni faire transporter aucun objet ou produit illégal ou dangereux ;</li>
        <li>rester courtois : aucun propos ou comportement injurieux, discriminatoire, menaçant ou à caractère sexuel ;</li>
        <li>ne pas utiliser la plateforme à des fins commerciales (transport rémunéré, publicité, collecte de contacts).</li>
      </ul>

      <h2 id="avis">9. Messagerie, avis</h2>
      <ul>
        <li>La messagerie sert à organiser le trajet (point de rendez-vous, bagages, retard). N'y partagez pas de données
          sensibles (codes, mots de passe).</li>
        <li>Après un trajet, passager et conducteur peuvent se noter (1 à 5 étoiles) et laisser un commentaire. Les avis
          doivent être sincères et porter sur le trajet ; un avis injurieux ou mensonger peut être retiré.</li>
      </ul>

      <h2 id="position">10. Position et suivi en direct</h2>
      <ul>
        <li>La plateforme peut utiliser la position de votre appareil, <strong>si vous l'autorisez</strong>, pour remplir
          un lieu de départ et pour le guidage vocal jusqu'au point de rendez-vous.</li>
        <li>Le conducteur peut, s'il le souhaite, <strong>partager sa position en direct</strong> avec ses passagers
          confirmés, à partir d'une heure avant le départ et jusqu'à la fin du trajet. Il peut arrêter le partage à tout
          moment. Les passagers ne doivent pas utiliser cette information à d'autres fins.</li>
      </ul>

      <h2 id="sanctions">11. Suspension et fermeture du compte</h2>
      <p>En cas de manquement à ces conditions (documents faux, comportement dangereux ou injurieux, fraude au paiement,
        absences répétées…), un administrateur peut <strong>bloquer</strong> ou <strong>bannir</strong> le compte. La
        décision et son motif vous sont communiqués par email ou SMS ; vous pouvez la contester à l'adresse de contact.</p>

      <h2 id="responsabilite">12. Responsabilités</h2>
      <ul>
        <li>Les conducteurs et les passagers sont responsables de leurs actes pendant le trajet. Le conducteur répond de
          son véhicule, de son assurance et de sa conduite.</li>
        <li>La plateforme vérifie les documents des conducteurs mais ne peut garantir le comportement des utilisateurs.
          Elle n'est pas partie au contrat de covoiturage conclu entre eux.</li>
        <li>S'agissant d'un projet d'étudiants, le service est fourni <strong>en l'état</strong>, sans garantie de
          disponibilité continue. Les calculs de prix, de distance et d'itinéraire sont des estimations.</li>
        <li>Les cartes, adresses et itinéraires viennent de services tiers (OpenStreetMap) : vérifiez toujours les
          indications sur place.</li>
      </ul>

      <h2 id="modification">13. Modification des conditions</h2>
      <p>Ces conditions peuvent être modifiées, par exemple quand une fonctionnalité est ajoutée. La date de version figure
        en haut de cette page ; les changements importants seront annoncés dans la plateforme avant de s'appliquer.</p>

      <h2 id="droit">14. Droit applicable et contact</h2>
      <p>Ces conditions sont soumises au <strong>droit sénégalais</strong>. En cas de désaccord, écrivez-nous d'abord pour
        chercher une solution amiable : <a [href]="'mailto:' + contact">{{ contact }}</a>.</p>
    </app-page-legale>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Conditions {
  protected readonly contact = CONTACT_LEGAL;
}
