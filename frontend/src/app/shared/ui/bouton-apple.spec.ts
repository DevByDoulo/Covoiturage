import { TestBed } from '@angular/core/testing';
import { BoutonApple, estAbandonApple } from './bouton-apple';

describe('BoutonApple', () => {
  it("sans Services ID configuré, le clic signale que la connexion Apple n'est pas activée", async () => {
    const fixture = TestBed.createComponent(BoutonApple);
    fixture.detectChanges();
    let indisponible = false;
    fixture.componentInstance.indisponible.subscribe(() => (indisponible = true));
    (fixture.nativeElement as HTMLElement).querySelector('button')!.click();
    await fixture.whenStable();
    expect(indisponible).toBe(true);
    expect((fixture.nativeElement as HTMLElement).textContent).toContain('Continuer avec Apple');
  });

  it("reconnaît une fenêtre Apple fermée ou annulée (rien à signaler)", () => {
    expect(estAbandonApple({ error: 'popup_closed_by_user' })).toBe(true);
    expect(estAbandonApple({ error: 'user_cancelled_authorize' })).toBe(true);
    expect(estAbandonApple({ error: 'invalid_client' })).toBe(false);
    expect(estAbandonApple(null)).toBe(false);
  });
});
