-- 01 Gestion des utilisateurs : contacts d'urgence (écran « Mon profil »), prévenus en cas d'alerte pendant un trajet.
CREATE TABLE contact_urgence (
    id_contact_urgence  BIGSERIAL PRIMARY KEY,
    id_utilisateur      BIGINT      NOT NULL REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    nom                 VARCHAR(120) NOT NULL,
    telephone           VARCHAR(20) NOT NULL,
    lien                VARCHAR(40),
    date_creation       TIMESTAMP   NOT NULL,
    CONSTRAINT uq_contact_urgence_telephone UNIQUE (id_utilisateur, telephone)
);
CREATE INDEX idx_contact_urgence_utilisateur ON contact_urgence (id_utilisateur);
