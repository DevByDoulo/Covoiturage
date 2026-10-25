-- =====================================================================
-- CoVoitIA - Lot 1 : comptes, véhicules, documents, trajets, tarification,
-- réservations, paiement espèces, embarquement, notifications.
-- Noms de tables/colonnes alignés sur le diagramme de classes.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- ---------------------------------------------------------------------
-- Utilisateurs
-- ---------------------------------------------------------------------
CREATE TABLE utilisateur (
    id_utilisateur     BIGSERIAL PRIMARY KEY,
    prenom             VARCHAR(80)  NOT NULL,
    nom                VARCHAR(80)  NOT NULL,
    email              VARCHAR(160) UNIQUE,
    telephone          VARCHAR(20)  UNIQUE,
    telephone_verifie  BOOLEAN      NOT NULL DEFAULT FALSE,
    mot_de_passe       VARCHAR(100),
    google_id          VARCHAR(64)  UNIQUE,
    sexe               VARCHAR(10),
    photo_profil       VARCHAR(255),
    bio                VARCHAR(500),
    role               VARCHAR(20)  NOT NULL,
    statut             VARCHAR(20)  NOT NULL,
    conducteur_valide  BOOLEAN      NOT NULL DEFAULT FALSE,
    note_moyenne       NUMERIC(3, 2),
    fcm_token          VARCHAR(255),
    date_creation      TIMESTAMP    NOT NULL,
    CONSTRAINT ck_utilisateur_role   CHECK (role IN ('PASSAGER', 'CONDUCTEUR', 'ADMIN')),
    CONSTRAINT ck_utilisateur_statut CHECK (statut IN ('EN_ATTENTE_OTP', 'ACTIF', 'BLOQUE', 'BANNI', 'DESACTIVE')),
    CONSTRAINT ck_utilisateur_sexe   CHECK (sexe IS NULL OR sexe IN ('HOMME', 'FEMME'))
);

CREATE TABLE preference (
    id_preference        BIGSERIAL PRIMARY KEY,
    id_utilisateur       BIGINT  NOT NULL UNIQUE REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    fumeur_accepte       BOOLEAN NOT NULL DEFAULT FALSE,
    musique_acceptee     BOOLEAN NOT NULL DEFAULT TRUE,
    animaux_acceptes     BOOLEAN NOT NULL DEFAULT FALSE,
    discussion_acceptee  BOOLEAN NOT NULL DEFAULT TRUE
);

-- Codes OTP (SMS) : seul le hash est stocké.
CREATE TABLE otp_code (
    id_otp           BIGSERIAL PRIMARY KEY,
    telephone        VARCHAR(20) NOT NULL,
    code_hash        VARCHAR(100) NOT NULL,
    objet            VARCHAR(30) NOT NULL,
    tentatives       INTEGER     NOT NULL DEFAULT 0,
    utilise          BOOLEAN     NOT NULL DEFAULT FALSE,
    date_expiration  TIMESTAMP   NOT NULL,
    date_creation    TIMESTAMP   NOT NULL,
    CONSTRAINT ck_otp_objet CHECK (objet IN ('VERIFICATION_TELEPHONE', 'REINITIALISATION_MOT_DE_PASSE'))
);
CREATE INDEX idx_otp_telephone ON otp_code (telephone, objet, date_creation DESC);

-- Jetons de rafraîchissement (rotation à chaque usage) : seul le hash SHA-256 est stocké.
CREATE TABLE refresh_token (
    id_refresh_token  BIGSERIAL PRIMARY KEY,
    id_utilisateur    BIGINT      NOT NULL REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    token_hash        VARCHAR(64) NOT NULL UNIQUE,
    revoque           BOOLEAN     NOT NULL DEFAULT FALSE,
    date_expiration   TIMESTAMP   NOT NULL,
    date_creation     TIMESTAMP   NOT NULL
);

-- ---------------------------------------------------------------------
-- Véhicules et documents
-- ---------------------------------------------------------------------
CREATE TABLE vehicule (
    id_vehicule             BIGSERIAL PRIMARY KEY,
    id_proprietaire         BIGINT       NOT NULL REFERENCES utilisateur (id_utilisateur),
    immatriculation         VARCHAR(20)  NOT NULL UNIQUE,
    marque                  VARCHAR(60)  NOT NULL,
    modele                  VARCHAR(60)  NOT NULL,
    annee                   INTEGER      NOT NULL,
    puissance_fiscale       INTEGER      NOT NULL,
    nombre_places           INTEGER      NOT NULL,
    type_energie            VARCHAR(20)  NOT NULL,
    consommation_theorique  NUMERIC(5, 2),
    consommation_reelle     NUMERIC(5, 2),
    amortissement_par_km    NUMERIC(8, 2),
    statut_validation       VARCHAR(20)  NOT NULL,
    actif                   BOOLEAN      NOT NULL DEFAULT TRUE,
    date_creation           TIMESTAMP    NOT NULL,
    CONSTRAINT ck_vehicule_energie CHECK (type_energie IN ('ESSENCE', 'DIESEL', 'HYBRIDE', 'ELECTRIQUE')),
    CONSTRAINT ck_vehicule_statut  CHECK (statut_validation IN ('EN_ATTENTE', 'VALIDE', 'REFUSE')),
    CONSTRAINT ck_vehicule_places  CHECK (nombre_places BETWEEN 2 AND 9)
);
CREATE INDEX idx_vehicule_proprietaire ON vehicule (id_proprietaire);

CREATE TABLE document (
    id_document          BIGSERIAL PRIMARY KEY,
    id_utilisateur       BIGINT       NOT NULL REFERENCES utilisateur (id_utilisateur),
    id_vehicule          BIGINT       REFERENCES vehicule (id_vehicule),
    id_admin_validateur  BIGINT       REFERENCES utilisateur (id_utilisateur),
    type_document        VARCHAR(30)  NOT NULL,
    fichier              VARCHAR(255) NOT NULL,
    nom_original         VARCHAR(255),
    type_mime            VARCHAR(100) NOT NULL,
    statut_validation    VARCHAR(20)  NOT NULL,
    commentaire_admin    VARCHAR(500),
    date_soumission      TIMESTAMP    NOT NULL,
    date_validation      TIMESTAMP,
    CONSTRAINT ck_document_type   CHECK (type_document IN ('PERMIS_CONDUIRE', 'CARTE_GRISE')),
    CONSTRAINT ck_document_statut CHECK (statut_validation IN ('EN_ATTENTE', 'VALIDE', 'REFUSE')),
    CONSTRAINT ck_document_carte_grise_vehicule CHECK (type_document <> 'CARTE_GRISE' OR id_vehicule IS NOT NULL)
);
CREATE INDEX idx_document_file_validation ON document (statut_validation, date_soumission);
CREATE INDEX idx_document_utilisateur ON document (id_utilisateur);

-- ---------------------------------------------------------------------
-- Trajets
-- ---------------------------------------------------------------------
CREATE TABLE trajet (
    id_trajet                  BIGSERIAL PRIMARY KEY,
    id_conducteur              BIGINT        NOT NULL REFERENCES utilisateur (id_utilisateur),
    id_vehicule                BIGINT        NOT NULL REFERENCES vehicule (id_vehicule),
    lieu_depart                VARCHAR(200)  NOT NULL,
    latitude_depart            DOUBLE PRECISION NOT NULL,
    longitude_depart           DOUBLE PRECISION NOT NULL,
    lieu_arrivee               VARCHAR(200)  NOT NULL,
    latitude_arrivee           DOUBLE PRECISION NOT NULL,
    longitude_arrivee          DOUBLE PRECISION NOT NULL,
    date_heure_depart          TIMESTAMP     NOT NULL,
    flexibilite_minutes        INTEGER       NOT NULL,
    nombre_places_total        INTEGER       NOT NULL,
    nombre_places_disponibles  INTEGER       NOT NULL,
    mode_reservation           VARCHAR(20)   NOT NULL,
    taille_bagage              VARCHAR(10)   NOT NULL,
    femmes_uniquement          BOOLEAN       NOT NULL DEFAULT FALSE,
    distance_km                NUMERIC(8, 2) NOT NULL,
    denivele_m                 INTEGER       NOT NULL DEFAULT 0,
    type_route                 VARCHAR(20)   NOT NULL,
    montant_peages             NUMERIC(10, 2) NOT NULL DEFAULT 0,
    duree_estimee_min          INTEGER       NOT NULL,
    itineraire                 geometry(LineString, 4326) NOT NULL,
    statut                     VARCHAR(20)   NOT NULL,
    motif_annulation           VARCHAR(500),
    date_creation              TIMESTAMP     NOT NULL,
    date_modification          TIMESTAMP     NOT NULL,
    CONSTRAINT ck_trajet_flexibilite CHECK (flexibilite_minutes BETWEEN 15 AND 30),
    CONSTRAINT ck_trajet_places      CHECK (nombre_places_disponibles BETWEEN 0 AND nombre_places_total),
    CONSTRAINT ck_trajet_mode        CHECK (mode_reservation IN ('AUTOMATIQUE', 'MANUELLE')),
    CONSTRAINT ck_trajet_bagage      CHECK (taille_bagage IN ('PETIT', 'MOYEN', 'GRAND')),
    CONSTRAINT ck_trajet_route       CHECK (type_route IN ('AUTOROUTE', 'NATIONALE', 'VILLE', 'MIXTE')),
    CONSTRAINT ck_trajet_statut      CHECK (statut IN ('PUBLIE', 'COMPLET', 'EN_COURS', 'TERMINE', 'ANNULE'))
);
-- Recherche de proximité (ST_DWithin en mètres sur geography) : objectif < 1,5 s.
CREATE INDEX idx_trajet_itineraire_geo ON trajet USING GIST ((itineraire::geography));
CREATE INDEX idx_trajet_statut_date ON trajet (statut, date_heure_depart);
CREATE INDEX idx_trajet_conducteur ON trajet (id_conducteur);

CREATE TABLE escale (
    id_escale  BIGSERIAL PRIMARY KEY,
    id_trajet  BIGINT       NOT NULL REFERENCES trajet (id_trajet) ON DELETE CASCADE,
    ordre      INTEGER      NOT NULL,
    lieu       VARCHAR(200) NOT NULL,
    latitude   DOUBLE PRECISION NOT NULL,
    longitude  DOUBLE PRECISION NOT NULL,
    CONSTRAINT uk_escale_ordre UNIQUE (id_trajet, ordre)
);

-- ---------------------------------------------------------------------
-- Tarification
-- ---------------------------------------------------------------------
CREATE TABLE tarification (
    id_tarification         BIGSERIAL PRIMARY KEY,
    id_trajet               BIGINT         NOT NULL UNIQUE REFERENCES trajet (id_trajet) ON DELETE CASCADE,
    prix_ia                 NUMERIC(10, 2) NOT NULL,
    prix_min                NUMERIC(10, 2) NOT NULL,
    prix_max                NUMERIC(10, 2) NOT NULL,
    prix_final              NUMERIC(10, 2) NOT NULL,
    prix_carburant_utilise  NUMERIC(10, 2) NOT NULL,
    meteo                   VARCHAR(40),
    heure_de_pointe         BOOLEAN        NOT NULL DEFAULT FALSE,
    version_modele          VARCHAR(40)    NOT NULL,
    date_prediction         TIMESTAMP      NOT NULL,
    CONSTRAINT ck_tarification_bornes CHECK (prix_final BETWEEN prix_min AND prix_max)
);
CREATE INDEX idx_tarification_prix ON tarification (prix_final);

CREATE TABLE parametre_tarification (
    id_parametre       BIGSERIAL PRIMARY KEY,
    id_admin           BIGINT        REFERENCES utilisateur (id_utilisateur),
    cle                VARCHAR(60)   NOT NULL UNIQUE,
    valeur             NUMERIC(12, 4) NOT NULL,
    unite              VARCHAR(30),
    description        VARCHAR(255),
    actif              BOOLEAN       NOT NULL DEFAULT TRUE,
    date_modification  TIMESTAMP     NOT NULL
);

-- Valeurs indicatives (FCFA) à vérifier/ajuster depuis le back-office.
INSERT INTO parametre_tarification (cle, valeur, unite, description, date_modification) VALUES
  ('PRIX_ESSENCE',               990,  'FCFA/L',   'Prix moyen du litre de super à la pompe', NOW()),
  ('PRIX_GASOIL',                755,  'FCFA/L',   'Prix moyen du litre de gasoil à la pompe', NOW()),
  ('PRIX_ELECTRICITE',           120,  'FCFA/kWh', 'Prix moyen du kWh pour la recharge', NOW()),
  ('AMORTISSEMENT_KM_DEFAUT',    25,   'FCFA/km',  'Usure/amortissement par km si non déclaré pour le véhicule', NOW()),
  ('MAJORATION_HEURE_POINTE',    0.08, 'ratio',    'Surconsommation liée au trafic aux heures de pointe', NOW()),
  ('MARGE_AJUSTEMENT',           0.10, 'ratio',    'Marge +/- laissée au conducteur autour du prix proposé', NOW()),
  ('ARRONDI',                    50,   'FCFA',     'Le prix par place est arrondi à ce multiple', NOW()),
  ('PRIX_MINIMUM',               500,  'FCFA',     'Prix plancher par place', NOW());

-- ---------------------------------------------------------------------
-- Réservations, paiement, embarquement
-- ---------------------------------------------------------------------
CREATE TABLE reservation (
    id_reservation       BIGSERIAL PRIMARY KEY,
    id_passager          BIGINT         NOT NULL REFERENCES utilisateur (id_utilisateur),
    id_trajet            BIGINT         NOT NULL REFERENCES trajet (id_trajet),
    id_escale_ramassage  BIGINT         REFERENCES escale (id_escale),
    nombre_places        INTEGER        NOT NULL,
    prix_unitaire        NUMERIC(10, 2) NOT NULL,
    montant_total        NUMERIC(10, 2) NOT NULL,
    statut               VARCHAR(20)    NOT NULL,
    motif_annulation     VARCHAR(500),
    date_demande         TIMESTAMP      NOT NULL,
    date_reponse         TIMESTAMP,
    date_annulation      TIMESTAMP,
    CONSTRAINT ck_reservation_places CHECK (nombre_places >= 1),
    CONSTRAINT ck_reservation_statut CHECK (statut IN ('EN_ATTENTE', 'ACCEPTEE', 'REFUSEE', 'ANNULEE', 'TERMINEE'))
);
-- Une seule réservation active par passager et par trajet.
CREATE UNIQUE INDEX uk_reservation_active ON reservation (id_trajet, id_passager)
    WHERE statut IN ('EN_ATTENTE', 'ACCEPTEE');
CREATE INDEX idx_reservation_passager ON reservation (id_passager);

CREATE TABLE paiement (
    id_paiement            BIGSERIAL PRIMARY KEY,
    id_reservation         BIGINT         NOT NULL REFERENCES reservation (id_reservation),
    montant                NUMERIC(10, 2) NOT NULL,
    moyen_paiement         VARCHAR(20)    NOT NULL,
    fournisseur            VARCHAR(30),
    reference_transaction  VARCHAR(40)    NOT NULL UNIQUE,
    reference_externe      VARCHAR(100),
    numero_telephone       VARCHAR(20),
    statut                 VARCHAR(30)    NOT NULL,
    date_initiation        TIMESTAMP      NOT NULL,
    date_confirmation      TIMESTAMP,
    date_remboursement     TIMESTAMP,
    CONSTRAINT ck_paiement_moyen  CHECK (moyen_paiement IN ('ESPECES', 'WAVE', 'ORANGE_MONEY')),
    CONSTRAINT ck_paiement_statut CHECK (statut IN ('EN_ATTENTE', 'REUSSI', 'ECHOUE', 'REMBOURSEMENT_DEMANDE', 'REMBOURSE'))
);

CREATE TABLE confirmation_embarquement (
    id_confirmation    BIGSERIAL PRIMARY KEY,
    id_reservation     BIGINT      NOT NULL UNIQUE REFERENCES reservation (id_reservation),
    code_pin           VARCHAR(6)  NOT NULL,
    qr_token           VARCHAR(64) NOT NULL UNIQUE,
    statut             VARCHAR(20) NOT NULL,
    date_expiration    TIMESTAMP   NOT NULL,
    date_confirmation  TIMESTAMP,
    CONSTRAINT ck_confirmation_statut CHECK (statut IN ('EN_ATTENTE', 'CONFIRMEE', 'EXPIREE', 'ANNULEE'))
);

-- ---------------------------------------------------------------------
-- Notifications
-- ---------------------------------------------------------------------
CREATE TABLE notification (
    id_notification    BIGSERIAL PRIMARY KEY,
    id_utilisateur     BIGINT       NOT NULL REFERENCES utilisateur (id_utilisateur) ON DELETE CASCADE,
    type_notification  VARCHAR(40)  NOT NULL,
    titre              VARCHAR(120) NOT NULL,
    contenu            VARCHAR(500) NOT NULL,
    canal              VARCHAR(10)  NOT NULL,
    lu                 BOOLEAN      NOT NULL DEFAULT FALSE,
    date_envoi         TIMESTAMP    NOT NULL,
    CONSTRAINT ck_notification_canal CHECK (canal IN ('PUSH', 'EMAIL', 'SMS'))
);
CREATE INDEX idx_notification_utilisateur ON notification (id_utilisateur, lu, date_envoi DESC);
