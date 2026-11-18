import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { Geocodage, Lieu } from '../../core/carte/geocodage';
import { BarreRecherche } from './barre-recherche';

@Component({
  imports: [BarreRecherche],
  template: `
    <app-barre-recherche [(depart)]="depart" [(arrivee)]="arrivee" [(passagers)]="passagers" [(date)]="date"
                         [erreur]="erreur()" (lancer)="lancements = lancements + 1" />
  `,
})
class Hote {
  readonly depart = signal<Lieu | null>({ libelle: 'Dakar', latitude: 14.69, longitude: -17.44 });
  readonly arrivee = signal<Lieu | null>({ libelle: 'Thiès', latitude: 14.79, longitude: -16.93 });
  readonly passagers = signal(1);
  readonly date = signal('2026-11-20');
  readonly erreur = signal<string | null>(null);
  lancements = 0;
}

describe('BarreRecherche', () => {
  function creer() {
    TestBed.configureTestingModule({
      providers: [{ provide: Geocodage, useValue: { rechercher: () => of([]), adresseDe: () => of(null) } }],
    });
    const fixture = TestBed.createComponent(Hote);
    fixture.detectChanges();
    const el = fixture.nativeElement as HTMLElement;
    const bouton = (texte: string) =>
      [...el.querySelectorAll('button')].find((b) => (b.getAttribute('aria-label') ?? b.textContent)!.includes(texte))!;
    return { fixture, hote: fixture.componentInstance, el, bouton };
  }

  it('affiche les lieux et la date choisis par le parent', () => {
    const { el } = creer();
    expect((el.querySelector('#r-depart') as HTMLInputElement).value).toBe('Dakar');
    expect((el.querySelector('#r-arrivee') as HTMLInputElement).value).toBe('Thiès');
    expect((el.querySelector('#r-date') as HTMLInputElement).value).toBe('2026-11-20');
    expect(el.querySelector('[role="search"]')).not.toBeNull();
  });

  it('inverse départ et arrivée chez le parent', () => {
    const { fixture, hote, bouton } = creer();
    bouton('Inverser').click();
    fixture.detectChanges();
    expect(hote.depart()?.libelle).toBe('Thiès');
    expect(hote.arrivee()?.libelle).toBe('Dakar');
  });

  it('garde le nombre de passagers entre 1 et 8', () => {
    const { fixture, hote, bouton } = creer();
    bouton('de moins').click();
    expect(hote.passagers()).toBe(1);
    for (let i = 0; i < 10; i++) bouton('de plus').click();
    fixture.detectChanges();
    expect(hote.passagers()).toBe(8);
  });

  it('le bouton Rechercher (ou Entrée) prévient le parent, sans recharger la page', () => {
    const { el, hote } = creer();
    const formulaire = el.querySelector('form')!;
    const evenement = new Event('submit', { cancelable: true });
    formulaire.dispatchEvent(evenement);
    expect(evenement.defaultPrevented).toBe(true);
    expect(hote.lancements).toBe(1);
  });

  it("affiche l'erreur transmise par le parent", () => {
    const { fixture, hote, el } = creer();
    hote.erreur.set("Choisissez un lieu de départ et un lieu d'arrivée.");
    fixture.detectChanges();
    expect(el.querySelector('[role="alert"]')?.textContent).toContain('Choisissez un lieu');
  });
});
