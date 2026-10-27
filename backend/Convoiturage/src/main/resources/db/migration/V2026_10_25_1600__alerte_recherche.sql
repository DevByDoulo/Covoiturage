-- F5 — Alertes de recherche : un passager dont la recherche n'a rien donné est prévenu
-- dès qu'un trajet correspondant est publié. Colonnes conformes à ALERTE_RECHERCHE du diagramme de classes.

CREATE TABLE alerte_recherche (
    id_alerte          BIGSERIAL PRIMARY KEY,
    id_utilisateur     BIGINT           NOT NULL REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    ville_depart       VARCHAR(200)     NOT NULL,
    latitude_depart    DOUBLE PRECISION NOT NULL,
    longitude_depart   DOUBLE PRECISION NOT NULL,
    ville_arrivee      VARCHAR(200)     NOT NULL,
    latitude_arrivee   DOUBLE PRECISION NOT NULL,
    longitude_arrivee  DOUBLE PRECISION NOT NULL,
    rayon_km           NUMERIC(5, 2)    NOT NULL DEFAULT 5,
    date_depart        DATE             NOT NULL,
    prix_max           NUMERIC(10, 2),
    actif              BOOLEAN          NOT NULL DEFAULT TRUE,
    date_creation      TIMESTAMP        NOT NULL,
    CONSTRAINT ck_alerte_rayon CHECK (rayon_km > 0 AND rayon_km <= 30)
);

-- Recherche des alertes concernées par un trajet publié : par date d'abord.
CREATE INDEX idx_alerte_recherche_date ON alerte_recherche (date_depart) WHERE actif;
CREATE INDEX idx_alerte_recherche_utilisateur ON alerte_recherche (id_utilisateur);
