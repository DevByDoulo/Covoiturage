import { TestBed } from '@angular/core/testing';
import { Subject, of } from 'rxjs';
import { vi } from 'vitest';
import { Position, PositionActuelle } from '../../core/carte/position-actuelle';
import { PartagePosition } from './partage-position.service';
import { EnvoiPosition, SuiviService } from './suivi.service';

/** Décale un point de [m] mètres vers le nord. */
const nord = (m: number): Position => ({ latitude: 14.69 + m / 111_195, longitude: -17.44, precisionM: 10 });

describe('PartagePosition : rythme des envois', () => {
  let gps: Subject<Position>;
  let envois: EnvoiPosition[];
  let partage: PartagePosition;

  beforeEach(() => {
    vi.useFakeTimers();
    gps = new Subject<Position>();
    envois = [];
    TestBed.configureTestingModule({
      providers: [
        { provide: PositionActuelle, useValue: { suivre: () => gps } },
        {
          provide: SuiviService,
          useValue: {
            envoyer: (_: number, p: EnvoiPosition) => {
              envois.push(p);
              return of({});
            },
            arreter: () => of(undefined),
          },
        },
      ],
    });
    partage = TestBed.inject(PartagePosition);
    partage.demarrer(3);
  });

  afterEach(() => {
    partage.arreter(false);
    vi.useRealTimers();
  });

  it('envoie la première position tout de suite, puis au plus toutes les 5 s', () => {
    gps.next(nord(0));
    expect(envois).toHaveLength(1);
    vi.advanceTimersByTime(2_000);
    gps.next(nord(100));
    expect(envois).toHaveLength(1); // trop tôt : mise en attente
    vi.advanceTimersByTime(3_000);
    expect(envois).toHaveLength(2); // envoyée à la fin du délai, même sans nouvelle position du GPS
    expect(envois[1].latitude).toBeCloseTo(nord(100).latitude, 6);
  });

  it("n'envoie pas un petit déplacement, sauf après 20 s", () => {
    gps.next(nord(0));
    vi.advanceTimersByTime(6_000);
    gps.next(nord(5)); // 5 m : inutile
    expect(envois).toHaveLength(1);
    vi.advanceTimersByTime(15_000);
    gps.next(nord(6));
    expect(envois).toHaveLength(2); // 20 s écoulées : on confirme la position
  });

  it("garde la dernière position en attente, pas l'une des précédentes", () => {
    gps.next(nord(0));
    vi.advanceTimersByTime(1_000);
    gps.next(nord(50));
    vi.advanceTimersByTime(1_000);
    gps.next(nord(120));
    vi.advanceTimersByTime(3_000);
    expect(envois).toHaveLength(2);
    expect(envois[1].latitude).toBeCloseTo(nord(120).latitude, 6);
  });
});
