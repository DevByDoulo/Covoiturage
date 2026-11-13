-- Suppression de compte (RGPD, droit à l'effacement) : délai de grâce de 30 jours après la demande, puis
-- anonymisation des données personnelles (tâche planifiée). Les paiements, trajets et avis sont conservés.
ALTER TABLE utilisateur ADD COLUMN date_suppression_demandee TIMESTAMP;
ALTER TABLE utilisateur ADD COLUMN date_anonymisation TIMESTAMP;

ALTER TABLE utilisateur DROP CONSTRAINT ck_utilisateur_statut;
ALTER TABLE utilisateur ADD CONSTRAINT ck_utilisateur_statut CHECK (statut IN
    ('EN_ATTENTE_OTP', 'ACTIF', 'BLOQUE', 'BANNI', 'DESACTIVE', 'SUPPRESSION_DEMANDEE', 'SUPPRIME'));

CREATE INDEX idx_utilisateur_suppression ON utilisateur (date_suppression_demandee)
    WHERE statut = 'SUPPRESSION_DEMANDEE';

-- Code de confirmation de la suppression (comptes créés avec Google, sans mot de passe).
ALTER TABLE otp_code DROP CONSTRAINT ck_otp_objet;
ALTER TABLE otp_code ADD CONSTRAINT ck_otp_objet CHECK (objet IN
    ('VERIFICATION_TELEPHONE', 'REINITIALISATION_MOT_DE_PASSE', 'CONFIRMATION_SUPPRESSION'));
