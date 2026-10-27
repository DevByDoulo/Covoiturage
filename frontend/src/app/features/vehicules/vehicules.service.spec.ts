import { PieceJustificative, dernierePiece } from './vehicules.service';

function piece(id: number, type: PieceJustificative['typeDocument'], idVehicule: number | null = null): PieceJustificative {
  return {
    id,
    typeDocument: type,
    idVehicule,
    immatriculation: null,
    nomOriginal: null,
    typeMime: 'image/png',
    statutValidation: 'EN_ATTENTE',
    commentaireAdmin: null,
    dateSoumission: '2026-10-27T10:00:00',
    dateValidation: null,
    urlFichier: `/api/documents/${id}/fichier`,
  };
}

describe('Véhicules et documents : pièce affichée', () => {
  // Le backend renvoie les pièces de la plus récente à la plus ancienne.
  const pieces = [piece(5, 'CARTE_GRISE', 2), piece(4, 'PERMIS_CONDUIRE'), piece(3, 'CARTE_GRISE', 1), piece(1, 'PERMIS_CONDUIRE')];

  it('prend la plus récente pour un type', () => {
    expect(dernierePiece(pieces, 'PERMIS_CONDUIRE')?.id).toBe(4);
  });

  it('distingue la carte grise de chaque véhicule', () => {
    expect(dernierePiece(pieces, 'CARTE_GRISE', 1)?.id).toBe(3);
    expect(dernierePiece(pieces, 'CARTE_GRISE', 2)?.id).toBe(5);
  });

  it("renvoie null quand rien n'a été envoyé", () => {
    expect(dernierePiece(pieces, 'PIECE_IDENTITE')).toBeNull();
  });
});
