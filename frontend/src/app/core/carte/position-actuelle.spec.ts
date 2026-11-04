import { firstValueFrom } from 'rxjs';
import { localiserAvec } from './position-actuelle';

/** Fausse géolocalisation : renvoie la position ou l'erreur donnée. */
function geolocalisation(resultat: { lat: number; lng: number; precision: number } | { code: number }): Geolocation {
  return {
    getCurrentPosition: (succes: PositionCallback, echec?: PositionErrorCallback | null) => {
      if ('code' in resultat) echec?.({ code: resultat.code } as GeolocationPositionError);
      else succes({ coords: { latitude: resultat.lat, longitude: resultat.lng, accuracy: resultat.precision } } as GeolocationPosition);
    },
  } as Geolocation;
}

describe('localiserAvec', () => {
  it("renvoie la position de l'appareil et sa précision arrondie", async () => {
    const p = await firstValueFrom(localiserAvec(geolocalisation({ lat: 14.6928, lng: -17.4467, precision: 12.6 })));
    expect(p).toEqual({ latitude: 14.6928, longitude: -17.4467, precisionM: 13 });
  });

  it('explique un refus, un délai dépassé ou une position introuvable', async () => {
    await expect(firstValueFrom(localiserAvec(geolocalisation({ code: 1 })))).rejects.toThrow('refusé');
    await expect(firstValueFrom(localiserAvec(geolocalisation({ code: 3 })))).rejects.toThrow('à temps');
    await expect(firstValueFrom(localiserAvec(geolocalisation({ code: 2 })))).rejects.toThrow('introuvable');
  });

  it('prévient quand le navigateur ne connaît pas la géolocalisation', async () => {
    await expect(firstValueFrom(localiserAvec(undefined))).rejects.toThrow('ne permet pas');
  });
});
