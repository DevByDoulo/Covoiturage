import { Coordonnee } from '../../shared/carte/polyline';
import { Etape, Itineraire, ModeDeplacement, distanceAuTraceM, distanceM, distanceParlee } from './itineraire';

/** Seuils en mètres selon le mode : on prévient plus tôt en voiture. */
const SEUILS: Record<ModeDeplacement, { loin: number; proche: number; passage: number; horsRoute: number }> = {
  pied: { loin: 100, proche: 25, passage: 15, horsRoute: 40 },
  voiture: { loin: 300, proche: 60, passage: 30, horsRoute: 60 },
};

/** Nombre de positions consécutives loin du tracé avant de recalculer l'itinéraire (évite les faux écarts GPS). */
const ECARTS_AVANT_RECALCUL = 3;

export interface EtatGuidage {
  /** Phrases à lire maintenant, dans l'ordre. */
  annonces: string[];
  /** Prochaine manœuvre (null une fois arrivé). */
  prochaine: Etape | null;
  distanceProchaineM: number;
  /** Distance restante le long de l'itinéraire (approchée). */
  distanceRestanteM: number;
  arrive: boolean;
  /** L'utilisateur s'est écarté du tracé : il faut recalculer l'itinéraire. */
  horsRoute: boolean;
}

/**
 * 08 — Guidage pas à pas : à chaque nouvelle position, dit quoi annoncer (« Dans 300 mètres, tournez à droite… »,
 * puis « Tournez à droite… » au moment de tourner), détecte l'arrivée et les sorties d'itinéraire.
 * Logique pure, sans navigateur : testée dans guide.spec.ts.
 */
export class Guide {
  private index = 1;
  private readonly dites = new Set<string>();
  private ecarts = 0;
  private termine = false;
  /** Plus petite distance atteinte à la manœuvre en cours (pour savoir qu'on l'a dépassée). */
  private plusProche = Infinity;
  private readonly seuils;

  constructor(
    private readonly itineraire: Itineraire,
    mode: ModeDeplacement,
  ) {
    this.seuils = SEUILS[mode];
    if (itineraire.etapes.length < 2) this.index = itineraire.etapes.length - 1;
  }

  /** Première annonce : longueur, durée et première consigne. */
  annonceDepart(): string {
    const minutes = Math.max(1, Math.round(this.itineraire.dureeS / 60));
    const premiere = this.itineraire.etapes[0]?.instruction;
    return `Itinéraire calculé : ${distanceParlee(this.itineraire.distanceM)}, environ ${minutes} minute${minutes > 1 ? 's' : ''}.`
      + (premiere ? ` ${premiere}.` : '');
  }

  avancer(p: Coordonnee): EtatGuidage {
    const etapes = this.itineraire.etapes;
    const annonces: string[] = [];

    if (!this.termine) {
      // Écart au tracé : recalcul après plusieurs positions consécutives trop loin.
      this.ecarts = distanceAuTraceM(p, this.itineraire.trace) > this.seuils.horsRoute ? this.ecarts + 1 : 0;

      let etape = etapes[this.index];
      let d = etape ? distanceM(p, etape) : 0;
      // Manœuvre atteinte, ou dépassée (consigne déjà dite et on s'en éloigne : le GPS ne passe pas toujours
      // à moins de quelques mètres du point exact) : on la dit si ce n'est pas fait, puis on passe aux suivantes.
      this.plusProche = Math.min(this.plusProche, d);
      const depassee = () => {
        const courante = etapes[this.index];
        const suivante = etapes[this.index + 1];
        if (courante.arrivee || !this.dites.has(`${this.index}:proche`)) return false;
        // On s'éloigne du point de manœuvre, ou on est déjà engagé sur le tronçon suivant.
        return d > this.plusProche + this.seuils.passage || (!!suivante && distanceM(p, suivante) < distanceM(courante, suivante));
      };
      while (etape) {
        // Arrivée : dite une seule fois, dès qu'on est « proche » (le GPS n'atteint pas toujours le point exact).
        if (etape.arrivee) {
          if (d <= this.seuils.proche) {
            annonces.push(etape.instruction + '.');
            this.termine = true;
          }
          break;
        }
        if (d > this.seuils.passage && !depassee()) break;
        if (!this.dites.has(`${this.index}:proche`)) annonces.push(this.consigne(this.index));
        this.index++;
        etape = etapes[this.index];
        d = etape ? distanceM(p, etape) : 0;
        this.plusProche = d;
      }
      if (!this.termine && etape) {
        if (!etape.arrivee && d <= this.seuils.proche && !this.dites.has(`${this.index}:proche`)) {
          annonces.push(this.consigne(this.index));
        } else if (d <= this.seuils.loin && d > this.seuils.proche && !this.dites.has(`${this.index}:loin`)) {
          this.dites.add(`${this.index}:loin`);
          annonces.push(
            etape.arrivee
              ? `Le point de rendez-vous est à ${distanceParlee(d)}.`
              : `Dans ${distanceParlee(d)}, ${minuscule(etape.instruction)}.`,
          );
        }
      }
    }

    const prochaine = this.termine ? null : (etapes[this.index] ?? null);
    const distanceProchaineM = prochaine ? distanceM(p, prochaine) : 0;
    const resteApres = etapes.slice(this.index).reduce((s, e) => s + e.distanceM, 0);
    return {
      annonces,
      prochaine,
      distanceProchaineM,
      distanceRestanteM: this.termine ? 0 : distanceProchaineM + resteApres,
      arrive: this.termine,
      horsRoute: !this.termine && this.ecarts >= ECARTS_AVANT_RECALCUL,
    };
  }

  /** Consigne au moment de la manœuvre ; si la suivante arrive juste après, on l'enchaîne (« … puis … »). */
  private consigne(i: number): string {
    const etapes = this.itineraire.etapes;
    this.dites.add(`${i}:proche`);
    let phrase = etapes[i].instruction;
    const suivante = etapes[i + 1];
    if (suivante && !suivante.arrivee && etapes[i].distanceM < this.seuils.loin / 2) {
      // La suivante est dite maintenant : on ne la répétera pas en l'atteignant.
      this.dites.add(`${i + 1}:loin`);
      this.dites.add(`${i + 1}:proche`);
      phrase += `, puis ${minuscule(suivante.instruction)}`;
    }
    return phrase + '.';
  }
}

function minuscule(s: string): string {
  return s.charAt(0).toLowerCase() + s.slice(1);
}
