-- 06 Notifications : notifications push sur plusieurs appareils (téléphones Android, navigateurs).
-- Un jeton Firebase Cloud Messaging par appareil ; il est retiré à la déconnexion ou quand FCM le déclare invalide.
CREATE TABLE appareil (
    id_appareil          BIGSERIAL PRIMARY KEY,
    id_utilisateur       BIGINT       NOT NULL REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    jeton                VARCHAR(512) NOT NULL UNIQUE,
    plateforme           VARCHAR(10)  NOT NULL,
    date_enregistrement  TIMESTAMP    NOT NULL DEFAULT now(),
    derniere_utilisation TIMESTAMP    NOT NULL DEFAULT now()
);
CREATE INDEX idx_appareil_utilisateur ON appareil (id_utilisateur);

-- Reprise de l'ancien jeton unique (colonne utilisateur.fcm_token de V1, désormais inutilisée).
INSERT INTO appareil (id_utilisateur, jeton, plateforme)
SELECT id_utilisateur, fcm_token, 'ANDROID' FROM utilisateur WHERE fcm_token IS NOT NULL AND fcm_token <> ''
ON CONFLICT (jeton) DO NOTHING;
UPDATE utilisateur SET fcm_token = NULL WHERE fcm_token IS NOT NULL;

-- Préférence : couper toutes les notifications push (les notifications restent visibles dans l'application).
ALTER TABLE utilisateur ADD COLUMN push_active BOOLEAN NOT NULL DEFAULT TRUE;
