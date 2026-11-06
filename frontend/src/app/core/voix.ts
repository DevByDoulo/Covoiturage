import { Injectable, signal } from '@angular/core';
import { stockage } from './auth/stockage';

const CLE_ACTIVE = 'covoitia.voix';

/**
 * Voix off : lit des phrases en français avec la synthèse vocale du navigateur (aucun service externe).
 * Coupable par l'utilisateur ; le choix est mémorisé sur l'appareil.
 */
@Injectable({ providedIn: 'root' })
export class Voix {
  private readonly synthese = typeof window !== 'undefined' ? window.speechSynthesis : undefined;

  readonly disponible = !!this.synthese;
  readonly active = signal(stockage.lire(CLE_ACTIVE) !== 'non');
  /** Dernière phrase prononcée (affichée aussi à l'écran pour qui n'a pas le son). */
  readonly derniere = signal<string | null>(null);

  basculer(): void {
    const active = !this.active();
    this.active.set(active);
    stockage.ecrire(CLE_ACTIVE, active ? 'oui' : 'non');
    if (!active) this.synthese?.cancel();
  }

  /** [prioritaire] : coupe la phrase en cours (ex. consigne de virage plus urgente qu'une information). */
  dire(texte: string, prioritaire = false): void {
    this.derniere.set(texte);
    if (!this.synthese || !this.active()) return;
    if (prioritaire) this.synthese.cancel();
    const phrase = new SpeechSynthesisUtterance(texte);
    phrase.lang = 'fr-FR';
    const voix = this.synthese.getVoices().find((v) => v.lang.toLowerCase().startsWith('fr'));
    if (voix) phrase.voice = voix;
    phrase.rate = 1;
    this.synthese.speak(phrase);
  }

  taire(): void {
    this.synthese?.cancel();
  }
}
