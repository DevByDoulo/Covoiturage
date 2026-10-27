-- 02 Gestion des véhicules : la pièce d'identité (CNI ou passeport) fait partie des documents à faire valider,
-- et chaque véhicule peut avoir une photo.
ALTER TABLE document DROP CONSTRAINT ck_document_type;
ALTER TABLE document ADD CONSTRAINT ck_document_type
    CHECK (type_document IN ('PERMIS_CONDUIRE', 'CARTE_GRISE', 'PIECE_IDENTITE'));

ALTER TABLE vehicule ADD COLUMN photo VARCHAR(255);
