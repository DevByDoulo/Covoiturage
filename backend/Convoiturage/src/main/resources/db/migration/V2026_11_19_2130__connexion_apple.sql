-- Connexion avec Apple : identifiant stable du compte Apple (claim « sub » de l'identityToken), comme google_id.
ALTER TABLE utilisateur ADD COLUMN apple_id VARCHAR(100) UNIQUE;
