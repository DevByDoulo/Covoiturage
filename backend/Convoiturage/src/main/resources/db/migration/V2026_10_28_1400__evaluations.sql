-- 05 Évaluations et avis (classe EVALUATION du diagramme de classes).
-- Après un trajet terminé, le passager embarqué note son conducteur et le conducteur note ce passager :
-- une évaluation par sens et par réservation. La moyenne est reportée dans utilisateur.note_moyenne.
CREATE TABLE evaluation (
    id_evaluation    BIGSERIAL PRIMARY KEY,
    id_reservation   BIGINT       NOT NULL REFERENCES reservation (id_reservation),
    id_trajet        BIGINT       NOT NULL REFERENCES trajet (id_trajet),
    id_evaluateur    BIGINT       NOT NULL REFERENCES utilisateur (id_utilisateur),
    id_evalue        BIGINT       NOT NULL REFERENCES utilisateur (id_utilisateur),
    note             SMALLINT     NOT NULL,
    commentaire      VARCHAR(500),
    date_evaluation  TIMESTAMP    NOT NULL,
    CONSTRAINT ck_evaluation_note CHECK (note BETWEEN 1 AND 5),
    CONSTRAINT ck_evaluation_personnes CHECK (id_evaluateur <> id_evalue),
    CONSTRAINT uk_evaluation_reservation_evaluateur UNIQUE (id_reservation, id_evaluateur)
);

-- Avis reçus par une personne, du plus récent au plus ancien (profil public, calcul de la moyenne).
CREATE INDEX idx_evaluation_evalue ON evaluation (id_evalue, date_evaluation DESC);
