-- 07 Administration : journal des décisions des administrateurs (validation des documents, blocage des comptes),
-- affiché dans la fiche utilisateur, et date de dernière connexion.
ALTER TABLE utilisateur ADD COLUMN derniere_connexion TIMESTAMP;

CREATE TABLE action_admin (
    id_action_admin  BIGSERIAL PRIMARY KEY,
    id_admin         BIGINT       NOT NULL REFERENCES utilisateur (id_utilisateur),
    id_utilisateur   BIGINT       NOT NULL REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    type_action      VARCHAR(30)  NOT NULL,
    detail           VARCHAR(500),
    date_action      TIMESTAMP    NOT NULL,
    CONSTRAINT ck_action_admin_type CHECK (type_action IN
        ('DOCUMENT_VALIDE', 'DOCUMENT_REFUSE', 'COMPTE_BLOQUE', 'COMPTE_BANNI', 'COMPTE_REACTIVE'))
);
CREATE INDEX idx_action_admin_utilisateur ON action_admin (id_utilisateur, date_action DESC);
