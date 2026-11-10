-- 10 Signalements (classe SIGNALEMENT du diagramme de classes).
-- Un utilisateur signale une personne avec qui il a partagé un trajet ; un administrateur traite le signalement
-- (classement sans suite, avertissement, blocage ou bannissement du compte signalé).
CREATE TABLE signalement (
    id_signalement    BIGSERIAL PRIMARY KEY,
    id_signaleur      BIGINT       NOT NULL REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    id_signale        BIGINT       NOT NULL REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    id_trajet         BIGINT       REFERENCES trajet (id_trajet) ON DELETE SET NULL,
    motif             VARCHAR(30)  NOT NULL,
    description       VARCHAR(500),
    statut            VARCHAR(20)  NOT NULL,
    decision_admin    VARCHAR(500),
    id_admin          BIGINT       REFERENCES utilisateur (id_utilisateur),
    date_signalement  TIMESTAMP    NOT NULL,
    date_traitement   TIMESTAMP,
    CONSTRAINT ck_signalement_personnes CHECK (id_signaleur <> id_signale),
    CONSTRAINT ck_signalement_motif CHECK (motif IN ('COMPORTEMENT', 'CONDUITE_DANGEREUSE', 'NON_PRESENTATION',
        'ANNULATION_TARDIVE', 'FRAUDE_DOCUMENTS', 'HARCELEMENT', 'AUTRE')),
    CONSTRAINT ck_signalement_statut CHECK (statut IN ('EN_ATTENTE', 'EN_COURS', 'TRAITE', 'REJETE'))
);

-- Un seul signalement ouvert par couple (signaleur, signalé).
CREATE UNIQUE INDEX uk_signalement_ouvert ON signalement (id_signaleur, id_signale)
    WHERE statut IN ('EN_ATTENTE', 'EN_COURS');
CREATE INDEX idx_signalement_statut ON signalement (statut, date_signalement);
CREATE INDEX idx_signalement_signaleur ON signalement (id_signaleur, date_signalement DESC);
CREATE INDEX idx_signalement_signale ON signalement (id_signale);

-- Le journal des décisions d'administration accueille aussi l'avertissement et le classement sans suite.
ALTER TABLE action_admin DROP CONSTRAINT ck_action_admin_type;
ALTER TABLE action_admin ADD CONSTRAINT ck_action_admin_type CHECK (type_action IN
    ('DOCUMENT_VALIDE', 'DOCUMENT_REFUSE', 'COMPTE_BLOQUE', 'COMPTE_BANNI', 'COMPTE_REACTIVE',
     'AVERTISSEMENT', 'SIGNALEMENT_CLASSE'));
