-- 06 Notifications : lien vers l'écran concerné (ouvert au clic sur la notification) et compteur des non lues.
-- (L'index de la liste par utilisateur et par date existe déjà depuis V1.)
ALTER TABLE notification ADD COLUMN lien VARCHAR(200);
CREATE INDEX idx_notification_non_lues ON notification (id_utilisateur) WHERE NOT lu;
