import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Observable, catchError, forkJoin, map, of, switchMap } from 'rxjs';
import { SessionService } from '../../core/auth/session.service';
import { Icone, NomIcone } from '../../shared/ui/icone';
import { Notification, NotificationsService } from '../notifications/notifications.service';
import { ContactUrgence, ProfilService } from '../profil/profil.service';
import { Reservation } from '../reservations/reservations.models';
import { ReservationsService } from '../reservations/reservations.service';
import { Trajet } from '../trajets/trajets.models';
import { TrajetsService } from '../trajets/trajets.service';
import { PieceJustificative, Vehicule, VehiculesService, dernierePiece } from '../vehicules/vehicules.service';

/** Prochain départ de l'utilisateur, qu'il conduise ou qu'il voyage comme passager. */
interface ProchainTrajet {
  role: 'conducteur' | 'passager';
  id: number;
  depart: string;
  arrivee: string;
  date: string;
  detail: string;
  lien: string;
}

interface Tache {
  icone: NomIcone;
  texte: string;
  lien: string;
  ton: 'attente' | 'erreur' | 'info';
}

interface Raccourci {
  icone: NomIcone;
  titre: string;
  detail: string;
  lien: string;
}

interface Donnees {
  trajets: Trajet[];
  reservations: Reservation[];
  demandesEnAttente: number;
  vehicules: Vehicule[];
  pieces: PieceJustificative[];
  contacts: ContactUrgence[];
  notifications: Notification[];
}

const A_VENIR = ['PUBLIE', 'COMPLET', 'EN_COURS'];

/** Accueil de l'espace connecté : prochain trajet, choses à faire, raccourcis et dernières notifications. */
@Component({
  selector: 'app-accueil',
  imports: [RouterLink, DatePipe, Icone],
  templateUrl: './accueil.html',
  styleUrl: './accueil.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Accueil {
  protected readonly session = inject(SessionService);
  private readonly trajetsApi = inject(TrajetsService);
  private readonly reservationsApi = inject(ReservationsService);
  private readonly vehiculesApi = inject(VehiculesService);
  private readonly profilApi = inject(ProfilService);
  private readonly notificationsApi = inject(NotificationsService);

  protected readonly donnees = signal<Donnees | null>(null);
  protected readonly conducteur = computed(() => this.session.utilisateur()?.role === 'CONDUCTEUR');

  protected readonly salutation = computed(() => {
    const h = new Date().getHours();
    return h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';
  });

  protected readonly prochain = computed<ProchainTrajet | null>(() => {
    const d = this.donnees();
    if (!d) return null;
    const maintenant = Date.now();
    const candidats: ProchainTrajet[] = [
      ...d.trajets
        .filter((t) => A_VENIR.includes(t.statut) && Date.parse(t.dateHeureDepart) > maintenant - 3_600_000)
        .map((t) => {
          const reserves = t.nombrePlacesTotal - t.nombrePlacesDisponibles;
          return {
            role: 'conducteur' as const,
            id: t.id,
            depart: t.depart.lieu,
            arrivee: t.arrivee.lieu,
            date: t.dateHeureDepart,
            detail: reserves
              ? `${reserves} place${reserves > 1 ? 's' : ''} réservée${reserves > 1 ? 's' : ''} sur ${t.nombrePlacesTotal}`
              : 'Aucune réservation pour le moment',
            lien: `/trajets/${t.id}`,
          };
        }),
      ...d.reservations
        .filter((r) => r.statut === 'ACCEPTEE' && Date.parse(r.trajet.dateHeureDepart) > maintenant - 3_600_000)
        .map((r) => ({
          role: 'passager' as const,
          id: r.trajet.id,
          depart: r.trajet.lieuDepart,
          arrivee: r.trajet.lieuArrivee,
          date: r.trajet.dateHeureDepart,
          detail: `Avec ${r.trajet.conducteur.prenom} • ${r.nombrePlaces} place${r.nombrePlaces > 1 ? 's' : ''}`,
          lien: '/reservations',
        })),
    ];
    return candidats.sort((a, b) => Date.parse(a.date) - Date.parse(b.date))[0] ?? null;
  });

  protected readonly taches = computed<Tache[]>(() => {
    const d = this.donnees();
    const u = this.session.utilisateur();
    if (!d || !u) return [];
    const liste: Tache[] = [];
    if (d.demandesEnAttente) {
      liste.push({
        icone: 'utilisateurs',
        ton: 'attente',
        texte: `${d.demandesEnAttente} demande${d.demandesEnAttente > 1 ? 's' : ''} de réservation à traiter`,
        lien: '/trajets/mes-trajets',
      });
    }
    const enAttente = d.reservations.filter((r) => r.statut === 'EN_ATTENTE').length;
    if (enAttente) {
      liste.push({
        icone: 'horloge',
        ton: 'info',
        texte: `${enAttente} réservation${enAttente > 1 ? 's' : ''} en attente de réponse du conducteur`,
        lien: '/reservations',
      });
    }
    if (u.role === 'CONDUCTEUR' && !u.conducteurValide) {
      const emplacements = [
        dernierePiece(d.pieces, 'PERMIS_CONDUIRE'),
        dernierePiece(d.pieces, 'PIECE_IDENTITE'),
        ...d.vehicules.map((v) => dernierePiece(d.pieces, 'CARTE_GRISE', v.id)),
      ];
      const refuses = emplacements.filter((p) => p?.statutValidation === 'REFUSE').length;
      const manquants = emplacements.filter((p) => !p).length;
      if (refuses) {
        liste.push({ icone: 'document', ton: 'erreur', texte: `${refuses} document${refuses > 1 ? 's' : ''} à renvoyer`, lien: '/vehicules' });
      } else if (manquants) {
        liste.push({ icone: 'document', ton: 'attente', texte: `${manquants} document${manquants > 1 ? 's' : ''} à envoyer pour publier vos trajets`, lien: '/vehicules' });
      } else {
        liste.push({ icone: 'horloge', ton: 'info', texte: 'Vos documents sont en cours de vérification', lien: '/vehicules' });
      }
    }
    if (u.role === 'PASSAGER' && !d.vehicules.length) {
      liste.push({ icone: 'voiture', ton: 'info', texte: 'Vous avez une voiture ? Devenez conducteur', lien: '/vehicules/nouveau' });
    }
    if (!u.photoProfil) liste.push({ icone: 'camera', ton: 'info', texte: 'Ajoutez une photo de profil', lien: '/profil' });
    if (!d.contacts.length) liste.push({ icone: 'bouclier', ton: 'info', texte: 'Ajoutez un contact d’urgence', lien: '/profil' });
    return liste;
  });

  protected readonly raccourcis = computed<Raccourci[]>(() => {
    const liste: Raccourci[] = [
      { icone: 'recherche', titre: 'Trouver un trajet', detail: 'Au départ de chez vous', lien: '/rechercher' },
      { icone: 'plus', titre: 'Publier un trajet', detail: 'Le prix est calculé pour vous', lien: '/trajets/publier' },
      { icone: 'valide', titre: 'Mes réservations', detail: 'Codes d’embarquement, paiements', lien: '/reservations' },
    ];
    if (this.conducteur()) {
      liste.push({ icone: 'route', titre: 'Mes trajets', detail: 'Demandes, départ, arrivée', lien: '/trajets/mes-trajets' });
    }
    return liste;
  });

  constructor() {
    const sur = <T>(appel: Observable<T>, defaut: T) => appel.pipe(catchError(() => of(defaut)));
    const conducteur = this.conducteur();
    const trajets$ = conducteur ? sur(this.trajetsApi.mesTrajets(), [] as Trajet[]) : of([] as Trajet[]);
    forkJoin({
      trajets: trajets$,
      reservations: sur(this.reservationsApi.mesReservations(), [] as Reservation[]),
      vehicules: sur(this.vehiculesApi.mesVehicules(), [] as Vehicule[]),
      pieces: sur(this.vehiculesApi.mesDocuments(), [] as PieceJustificative[]),
      contacts: sur(this.profilApi.contactsUrgence(), [] as ContactUrgence[]),
      notifications: sur(this.notificationsApi.lister(0).pipe(map((p) => p.content.slice(0, 3))), [] as Notification[]),
    })
      .pipe(
        // Demandes en attente sur les trajets à venir du conducteur.
        switchMap((d) => {
          const aVenir = d.trajets.filter((t) => A_VENIR.includes(t.statut) && t.modeReservation === 'MANUELLE');
          if (!aVenir.length) return of({ ...d, demandesEnAttente: 0 });
          return forkJoin(aVenir.map((t) => sur(this.reservationsApi.reservationsDuTrajet(t.id), [] as Reservation[]))).pipe(
            map((listes) => ({ ...d, demandesEnAttente: listes.flat().filter((r) => r.statut === 'EN_ATTENTE').length })),
          );
        }),
      )
      .subscribe((d) => this.donnees.set(d));
  }
}
