import {
  BARRES,
  Chrono,
  DUREE_MAX_MS,
  EnregistreurNatif,
  EnregistreurVocal,
  MESSAGE_INCOMPATIBLE,
  PlateformeAudio,
  choisirType,
  extensionPour,
  formaterDuree,
  formaterDureeTotale,
  messageErreurMicro,
  reduireNiveaux,
} from './vocal';

describe('Messages vocaux : minuteur et utilitaires', () => {
  it('formate la durée comme le lecteur', () => {
    expect(formaterDuree(0)).toBe('0:00');
    expect(formaterDuree(999)).toBe('0:00');
    expect(formaterDuree(23_400)).toBe('0:23');
    expect(formaterDuree(83_000)).toBe('1:23');
    expect(formaterDuree(DUREE_MAX_MS)).toBe('5:00');
    expect(formaterDuree(-5)).toBe('0:00');
    expect(formaterDureeTotale(2721)).toBe('0:03');
    expect(formaterDureeTotale(299_600)).toBe('5:00');
  });

  it('chronomètre avec pause sur une horloge factice', () => {
    let t = 1000;
    const chrono = new Chrono(() => t);
    chrono.demarrer();
    t += 2500;
    expect(chrono.ecoule()).toBe(2500);
    chrono.pause();
    t += 10_000;
    expect(chrono.ecoule()).toBe(2500);
    expect(chrono.enPause).toBe(true);
    chrono.reprendre();
    t += 500;
    expect(chrono.ecoule()).toBe(3000);
    chrono.demarrer();
    expect(chrono.ecoule()).toBe(0);
  });

  it('choisit un format accepté par le navigateur et son extension', () => {
    expect(choisirType((t) => t.startsWith('audio/webm'))).toBe('audio/webm;codecs=opus');
    expect(choisirType((t) => t === 'audio/mp4')).toBe('audio/mp4');
    expect(choisirType(() => false)).toBe('');
    expect(extensionPour('audio/webm;codecs=opus')).toBe('webm');
    expect(extensionPour('audio/ogg;codecs=opus')).toBe('ogg');
    expect(extensionPour('audio/mp4')).toBe('m4a');
    expect(extensionPour('')).toBe('webm');
  });

  it('réduit les niveaux mesurés à un nombre fixe de barres entre 0 et 100', () => {
    expect(reduireNiveaux([])).toEqual([]);
    expect(reduireNiveaux([5, 120, -3])).toEqual([5, 100, 0]);
    const longs = Array.from({ length: 600 }, (_, i) => i % 100);
    const barres = reduireNiveaux(longs);
    expect(barres).toHaveLength(BARRES);
    expect(Math.max(...barres)).toBeLessThanOrEqual(100);
  });

  it('explique chaque refus du micro', () => {
    expect(messageErreurMicro(new DOMException('x', 'NotAllowedError'))).toContain('refusé');
    expect(messageErreurMicro({ name: 'NotFoundError' })).toContain('Aucun micro');
    expect(messageErreurMicro({ name: 'NotReadableError' })).toContain('autre application');
    expect(messageErreurMicro(new Error('?'))).toContain("Impossible d'accéder");
  });
});

/** Fausse plateforme : horloge et minuterie pilotées par le test, MediaRecorder simulé. */
class FaussePlateforme implements PlateformeAudio {
  t = 0;
  tic: (() => void) | null = null;
  compatibleRetour = true;
  erreurMicro: unknown = null;
  liberes = 0;
  dernier: FauxEnregistreur | null = null;

  compatible(): boolean {
    return this.compatibleRetour;
  }
  typeSupporte(t: string): boolean {
    return t === 'audio/webm;codecs=opus';
  }
  micro(): Promise<MediaStream> {
    return this.erreurMicro ? Promise.reject(this.erreurMicro) : Promise.resolve({} as MediaStream);
  }
  enregistreur(_flux: MediaStream, type: string): EnregistreurNatif {
    this.dernier = new FauxEnregistreur(type);
    return this.dernier;
  }
  analyseur() {
    return { niveau: () => 42, fermer: () => {} };
  }
  liberer(): void {
    this.liberes++;
  }
  maintenant(): number {
    return this.t;
  }
  repeter(fn: () => void): () => void {
    this.tic = fn;
    return () => (this.tic = null);
  }
  avancer(ms: number): void {
    for (let i = 0; i < ms / 100; i++) {
      this.t += 100;
      this.tic?.();
    }
  }
}

class FauxEnregistreur implements EnregistreurNatif {
  ondataavailable: ((e: { data: Blob }) => void) | null = null;
  onstop: (() => void) | null = null;
  demarre = false;
  arrete = false;
  constructor(readonly mimeType: string) {}
  start(): void {
    this.demarre = true;
  }
  stop(): void {
    this.arrete = true;
    this.ondataavailable?.({ data: new Blob(['son'], { type: this.mimeType }) });
    queueMicrotask(() => this.onstop?.());
  }
}

describe('Messages vocaux : états de l’enregistreur', () => {
  it('enregistre, mesure le temps et renvoie le fichier avec sa forme d’onde', async () => {
    const p = new FaussePlateforme();
    const e = new EnregistreurVocal(p);
    expect(await e.demarrer()).toBe(true);
    expect(e.etat()).toBe('enregistrement');
    expect(p.dernier?.demarre).toBe(true);
    p.avancer(3000);
    expect(e.ecouleMs()).toBe(3000);
    const vocal = await e.terminer();
    expect(vocal?.dureeMs).toBe(3000);
    expect(vocal?.type).toBe('audio/webm;codecs=opus');
    expect(vocal?.blob.size).toBeGreaterThan(0);
    expect(vocal?.niveaux.every((n) => n === 42)).toBe(true);
    expect(e.etat()).toBe('inactif');
    expect(p.liberes).toBe(1);
  });

  it('ignore un enregistrement de moins d’une seconde', async () => {
    const p = new FaussePlateforme();
    const e = new EnregistreurVocal(p);
    await e.demarrer();
    p.avancer(700);
    expect(await e.terminer()).toBeNull();
    expect(e.etat()).toBe('inactif');
  });

  it('annule sans rien envoyer et libère le micro', async () => {
    const p = new FaussePlateforme();
    const e = new EnregistreurVocal(p);
    await e.demarrer();
    p.avancer(2000);
    e.annuler();
    expect(e.etat()).toBe('inactif');
    expect(p.liberes).toBe(1);
    expect(p.tic).toBeNull();
    expect(await e.terminer()).toBeNull();
  });

  it('prévient à la limite de 5 minutes (pour envoyer automatiquement)', async () => {
    const p = new FaussePlateforme();
    let limite = 0;
    const e = new EnregistreurVocal(p, () => limite++);
    await e.demarrer();
    p.avancer(DUREE_MAX_MS - 100);
    expect(limite).toBe(0);
    p.avancer(500);
    expect(limite).toBe(1);
    expect((await e.terminer())?.dureeMs).toBe(DUREE_MAX_MS);
  });

  it('affiche un message si le micro est refusé ou si le navigateur est incompatible', async () => {
    const p = new FaussePlateforme();
    p.erreurMicro = new DOMException('refus', 'NotAllowedError');
    const e = new EnregistreurVocal(p);
    expect(await e.demarrer()).toBe(false);
    expect(e.etat()).toBe('inactif');
    expect(e.erreur()).toContain('refusé');

    const q = new FaussePlateforme();
    q.compatibleRetour = false;
    const f = new EnregistreurVocal(q);
    expect(await f.demarrer()).toBe(false);
    expect(f.erreur()).toBe(MESSAGE_INCOMPATIBLE);
  });

  it('libère le micro si l’enregistrement est annulé pendant la demande d’autorisation', async () => {
    const p = new FaussePlateforme();
    const e = new EnregistreurVocal(p);
    const demarrage = e.demarrer();
    expect(e.etat()).toBe('demande');
    e.annuler();
    expect(await demarrage).toBe(false);
    expect(e.etat()).toBe('inactif');
    expect(p.liberes).toBe(1);
  });
});
