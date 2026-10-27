import { LignePaiement, Reservation, paiementEnLigneAttendu, totalEncaisse } from './reservations.models';

function reservation(changements: Partial<Reservation>): Reservation {
  return {
    id: 1,
    trajet: {
      id: 7,
      lieuDepart: 'Dakar',
      lieuArrivee: 'Thiès',
      dateHeureDepart: '2026-11-02T10:00:00',
      statut: 'PUBLIE',
      conducteur: { id: 2, prenom: 'Awa', nomInitiale: 'D.', photoProfil: null, noteMoyenne: null },
    },
    passager: { id: 3, prenom: 'Moussa', nomInitiale: 'N.', photoProfil: null, noteMoyenne: null },
    nombrePlaces: 1,
    prixUnitaire: 1650,
    montantTotal: 1650,
    statut: 'ACCEPTEE',
    pointRamassage: 'Dakar',
    moyenPaiement: 'WAVE',
    statutPaiement: 'EN_ATTENTE',
    embarque: false,
    dateDemande: '2026-10-28T09:00:00',
    ...changements,
  };
}

function ligne(role: LignePaiement['role'], statut: LignePaiement['statut'], montant: number): LignePaiement {
  return {
    referenceTransaction: `YBL-${role}-${statut}-${montant}`,
    idReservation: 1,
    role,
    trajet: 'Dakar → Thiès',
    dateHeureDepart: '2026-11-02T10:00:00',
    contrepartie: 'Awa Diop',
    montant,
    moyen: 'WAVE',
    statut,
    dateInitiation: '2026-10-28T09:00:00',
  };
}

describe('Facturation : paiement en ligne attendu', () => {
  it('propose de payer une réservation confirmée par Wave, y compris après un échec', () => {
    expect(paiementEnLigneAttendu(reservation({}))).toBe(true);
    expect(paiementEnLigneAttendu(reservation({ statutPaiement: 'ECHOUE' }))).toBe(true);
  });

  it('ne propose rien pour les espèces, une demande en attente, un paiement réglé ou un passager à bord', () => {
    expect(paiementEnLigneAttendu(reservation({ moyenPaiement: 'ESPECES' }))).toBe(false);
    expect(paiementEnLigneAttendu(reservation({ statut: 'EN_ATTENTE' }))).toBe(false);
    expect(paiementEnLigneAttendu(reservation({ statutPaiement: 'REUSSI' }))).toBe(false);
    expect(paiementEnLigneAttendu(reservation({ embarque: true }))).toBe(false);
  });
});

describe('Facturation : total encaissé', () => {
  it('ne compte que les encaissements réussis du conducteur', () => {
    const lignes = [
      ligne('CONDUCTEUR', 'REUSSI', 3300),
      ligne('CONDUCTEUR', 'REUSSI', 1650),
      ligne('CONDUCTEUR', 'REMBOURSE', 1650),
      ligne('CONDUCTEUR', 'EN_ATTENTE', 1650),
      ligne('PASSAGER', 'REUSSI', 2000),
    ];
    expect(totalEncaisse(lignes)).toBe(4950);
    expect(totalEncaisse([])).toBe(0);
  });
});
