-- ============================================================
-- init-db.sql — PostgreSQL initialization script
-- ============================================================
-- This file is mounted at:
--   /docker-entrypoint-initdb.d/01-init.sql
--
-- PostgreSQL runs it automatically the FIRST TIME the data
-- volume is created (i.e., on first "docker compose up").
-- It will NOT run again on subsequent starts.
--
-- Creates two databases inside the PostgreSQL instance:
--   nocodb   → Used by NocoDB to store all its data
--   superset → Used by Superset to store dashboards, charts,
--              users, and configuration
-- ============================================================

-- Create the NocoDB metadata database
CREATE DATABASE nocodb;

-- Create the Superset metadata database
CREATE DATABASE superset;
