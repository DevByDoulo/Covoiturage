-- =====================================================================
-- Initialisation d'une base PostgreSQL locale (sans Docker) pour YOBALEMAsn.
-- À exécuter en tant que superutilisateur « postgres », APRÈS avoir installé
-- PostGIS (postgis-bundle-pg16x64-setup-*.exe). Le script peut être relancé
-- sans risque : il ne crée que ce qui manque.
--
--   & "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -p 5433 -f db\init-local.sql
--
-- (adapter -p au port de votre installation ; 5432 par défaut)
-- Les tables sont ensuite créées automatiquement par Flyway au démarrage du backend.
-- =====================================================================

\set ON_ERROR_STOP on

-- Utilisateur applicatif (mot de passe de développement uniquement).
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'covoiturage') THEN
        CREATE ROLE covoiturage LOGIN PASSWORD 'covoiturage';
    ELSE
        ALTER ROLE covoiturage WITH LOGIN PASSWORD 'covoiturage';
    END IF;
END
$$;

-- CREATE DATABASE ne peut pas être conditionnel : on le génère seulement si la base manque.
SELECT 'CREATE DATABASE covoiturage OWNER covoiturage'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'covoiturage') \gexec

SELECT 'CREATE DATABASE covoiturage_test OWNER covoiturage'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'covoiturage_test') \gexec

-- PostGIS doit être activé par un superutilisateur, dans chaque base.
\connect covoiturage
CREATE EXTENSION IF NOT EXISTS postgis;
GRANT ALL ON SCHEMA public TO covoiturage;

\connect covoiturage_test
CREATE EXTENSION IF NOT EXISTS postgis;
GRANT ALL ON SCHEMA public TO covoiturage;

\echo 'Bases covoiturage et covoiturage_test prêtes, PostGIS activé.'
