-- 08 — Suivi du conducteur en temps réel : dernière position partagée par le conducteur pour un trajet.
-- Une seule ligne par trajet (remplacée à chaque envoi) ; supprimée à la fin ou à l'annulation du trajet,
-- quand le conducteur arrête le partage, et au plus tard 30 minutes après le dernier envoi.
CREATE TABLE position_conducteur (
    id_trajet    BIGINT           PRIMARY KEY REFERENCES trajet (id_trajet) ON DELETE CASCADE,
    latitude     DOUBLE PRECISION NOT NULL,
    longitude    DOUBLE PRECISION NOT NULL,
    precision_m  INTEGER,
    cap          DOUBLE PRECISION,
    vitesse      DOUBLE PRECISION,
    date_debut   TIMESTAMP        NOT NULL,
    date_maj     TIMESTAMP        NOT NULL
);

CREATE INDEX idx_position_conducteur_date_maj ON position_conducteur (date_maj);
