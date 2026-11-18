-- 09 — Messagerie : messages vocaux. Un message est un texte (contenu) ou un vocal (fichier audio stocké hors de la
-- base, sous un nom aléatoire). Le fichier peut disparaître (expiration ou compte supprimé) : le message reste.

ALTER TABLE message
    ADD COLUMN type            VARCHAR(10) NOT NULL DEFAULT 'TEXTE',
    ADD COLUMN fichier_audio   VARCHAR(60),
    ADD COLUMN type_mime_audio VARCHAR(30),
    ADD COLUMN duree_ms        INTEGER,
    ADD COLUMN forme_onde      VARCHAR(400),
    ADD COLUMN date_ecoute     TIMESTAMP;

ALTER TABLE message ALTER COLUMN contenu DROP NOT NULL;

ALTER TABLE message ADD CONSTRAINT ck_message_type CHECK (
    (type = 'TEXTE' AND contenu IS NOT NULL)
    OR (type = 'VOCAL' AND duree_ms IS NOT NULL AND duree_ms > 0));

CREATE UNIQUE INDEX uq_message_fichier_audio ON message (fichier_audio) WHERE fichier_audio IS NOT NULL;

-- 10 — Signalement d'un message précis (texte ou vocal) ; vidé si le message disparaît.
ALTER TABLE signalement ADD COLUMN id_message BIGINT REFERENCES message (id_message) ON DELETE SET NULL;
