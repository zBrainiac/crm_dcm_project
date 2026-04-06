-- ============================================================
-- 010 — CRM Schemas
-- DCM Project: CRM Domain
-- ============================================================
--
-- OVERVIEW:
-- Defines the two-layer schema structure for the CRM domain:
--   RAW    — Landing zone for ingested customer data (SCD Type 2)
--   SILVER — Modeled / analytics-ready layer (dynamic tables)
--
-- OBJECTS DEFINED:
-- ┌─ SCHEMAS (2):
-- │  ├─ {{ SCHEMA_CRM_RAW }}    — RAW layer
-- │  └─ {{ SCHEMA_CRM_SILVER }} — SILVER layer
-- ============================================================

DEFINE SCHEMA {{ sf_db }}.{{ SCHEMA_CRM_RAW }}
  COMMENT = 'RAW layer - CRM domain';

DEFINE SCHEMA {{ sf_db }}.{{ SCHEMA_CRM_SILVER }}
  COMMENT = 'SILVER layer - CRM domain (modeled / analytics-ready)';
