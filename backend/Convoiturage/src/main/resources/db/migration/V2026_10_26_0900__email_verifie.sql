-- Vérification par canal : un code reçu par email prouve la possession de l'adresse, pas celle du numéro.
-- utilisateur.email_verifie complète telephone_verifie ; otp_code.canal retient par où le code est parti.

ALTER TABLE utilisateur ADD COLUMN email_verifie BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE otp_code ADD COLUMN canal VARCHAR(10) NOT NULL DEFAULT 'SMS';
ALTER TABLE otp_code ADD CONSTRAINT ck_otp_canal CHECK (canal IN ('EMAIL', 'SMS'));
