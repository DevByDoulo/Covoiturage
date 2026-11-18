import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { environment } from '../../../environments/environment';
import { MessageConversation, MessagesService } from './messages.service';

describe('MessagesService : messages vocaux', () => {
  let service: MessagesService;
  let backend: HttpTestingController;
  const api = `${environment.apiUrl}/moi/conversations`;
  const vocal: MessageConversation = {
    id: 9,
    type: 'VOCAL',
    contenu: null,
    dureeMs: 3000,
    formeOnde: [10, 50],
    audioDisponible: true,
    dateEnvoi: '2026-11-18T10:00:00',
    deMoi: true,
    lu: false,
    ecoute: false,
  };

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideHttpClient(), provideHttpClientTesting()] });
    service = TestBed.inject(MessagesService);
    backend = TestBed.inject(HttpTestingController);
  });

  afterEach(() => backend.verify());

  it('envoie le fichier et la forme d’onde en multipart', () => {
    let recu: MessageConversation | undefined;
    service.envoyerVocal(4, new Blob(['son'], { type: 'audio/webm' }), 'vocal.webm', [10, 50]).subscribe((m) => (recu = m));
    const req = backend.expectOne(`${api}/4/vocaux`);
    expect(req.request.method).toBe('POST');
    const corps = req.request.body as FormData;
    expect(corps.get('formeOnde')).toBe('10,50');
    expect((corps.get('fichier') as File).name).toBe('vocal.webm');
    req.flush(vocal, { status: 201, statusText: 'Created' });
    expect(recu?.type).toBe('VOCAL');
  });

  it('n’envoie pas de forme d’onde vide', () => {
    service.envoyerVocal(4, new Blob(['son']), 'vocal.m4a', []).subscribe();
    const req = backend.expectOne(`${api}/4/vocaux`);
    expect((req.request.body as FormData).has('formeOnde')).toBe(false);
    req.flush(vocal);
  });

  it('charge le fichier audio en blob (API authentifiée, sans URL publique)', () => {
    let blob: Blob | undefined;
    service.audio(4, 9).subscribe((b) => (blob = b));
    const req = backend.expectOne(`${api}/4/messages/9/audio`);
    expect(req.request.responseType).toBe('blob');
    req.flush(new Blob(['son'], { type: 'audio/webm' }));
    expect(blob?.size).toBe(3);
  });

  it('signale l’écoute du vocal', () => {
    let recu: MessageConversation | undefined;
    service.marquerEcoute(4, 9).subscribe((m) => (recu = m));
    const req = backend.expectOne(`${api}/4/messages/9/ecoute`);
    expect(req.request.method).toBe('POST');
    req.flush({ ...vocal, deMoi: false, ecoute: true });
    expect(recu?.ecoute).toBe(true);
  });
});
