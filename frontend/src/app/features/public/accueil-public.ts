import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { Lieu } from '../../core/carte/geocodage';
import { Icone, NomIcone } from '../../shared/ui/icone';
import { BarreRecherche } from '../recherche/barre-recherche';
import { aujourdhui, parametresRecherche } from '../recherche/parametres-recherche';
import { TrajetsPopulaires } from './trajets-populaires';

interface Garantie {
  icone: NomIcone;
  titre: string;
  texte: string;
}

/** Accueil public (sans compte), façon BlaBlaCar : recherche en grand, garanties, appel aux conducteurs. */
@Component({
  selector: 'app-accueil-public',
  imports: [RouterLink, Icone, BarreRecherche, TrajetsPopulaires],
  templateUrl: './accueil-public.html',
  styleUrl: './accueil-public.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AccueilPublic {
  private readonly router = inject(Router);

  protected readonly depart = signal<Lieu | null>(null);
  protected readonly arrivee = signal<Lieu | null>(null);
  protected readonly champActif = signal<'depart' | 'arrivee'>('depart');
  protected readonly date = signal(aujourdhui());
  protected readonly passagers = signal(1);
  protected readonly erreur = signal<string | null>(null);

  protected readonly garanties: Garantie[] = [
    {
      icone: 'bouclier',
      titre: 'Conducteurs vérifiés',
      texte: 'Permis de conduire et carte grise contrôlés par notre équipe avant la première publication.',
    },
    {
      icone: 'eclair',
      titre: 'Paiement Wave',
      texte: 'Payez en ligne par Wave une fois votre place acceptée, ou en espèces au conducteur.',
    },
    {
      icone: 'discussion',
      titre: 'Messagerie interne',
      texte: "Échangez avec le conducteur dans l'application : vos numéros de téléphone restent privés.",
    },
    {
      icone: 'alerte',
      titre: 'Signalement',
      texte: 'Un comportement inapproprié ? Signalez-le après le trajet : notre équipe examine chaque signalement.',
    },
  ];

  protected rechercher(): void {
    const d = this.depart();
    const a = this.arrivee();
    if (!d || !a) {
      this.erreur.set("Choisissez un lieu de départ et un lieu d'arrivée.");
      return;
    }
    this.erreur.set(null);
    this.router.navigate(['/rechercher'], { queryParams: parametresRecherche(d, a, this.date(), this.passagers()) });
  }
}
