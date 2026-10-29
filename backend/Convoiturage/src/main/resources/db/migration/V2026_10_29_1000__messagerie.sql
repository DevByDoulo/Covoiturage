-- 09 — Messagerie : un fil par trajet et par passager, entre ce passager et le conducteur du trajet.

CREATE TABLE conversation (
    id_conversation       BIGSERIAL PRIMARY KEY,
    id_trajet             BIGINT    NOT NULL REFERENCES trajet (id_trajet) ON DELETE CASCADE,
    id_passager           BIGINT    NOT NULL REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    date_creation         TIMESTAMP NOT NULL,
    date_dernier_message  TIMESTAMP,
    CONSTRAINT uq_conversation_trajet_passager UNIQUE (id_trajet, id_passager)
);

CREATE INDEX idx_conversation_passager ON conversation (id_passager);

CREATE TABLE message (
    id_message       BIGSERIAL PRIMARY KEY,
    id_conversation  BIGINT        NOT NULL REFERENCES conversation (id_conversation) ON DELETE CASCADE,
    id_expediteur    BIGINT        NOT NULL REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    contenu          VARCHAR(1000) NOT NULL,
    date_envoi       TIMESTAMP     NOT NULL,
    date_lecture     TIMESTAMP
);

CREATE INDEX idx_message_conversation ON message (id_conversation, date_envoi);
CREATE INDEX idx_message_non_lus ON message (id_conversation) WHERE date_lecture IS NULL;
