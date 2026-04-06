-- ============================================================
-- 810 — CRM Grant Wiring
-- DCM Project: CRM Domain
-- ============================================================
--
-- OVERVIEW:
-- Privilege assignments connecting functional roles to CRM
-- domain objects. Follows least-privilege principle.
--
-- GRANT MATRIX:
-- ┌───────────────────────────────┬───────────┬───────────────┐
-- │ Object                        │ FR_INGEST │ FR_ANALYTICS  │
-- ├───────────────────────────────┼───────────┼───────────────┤
-- │ DATABASE {{ sf_db }}          │ USAGE     │ USAGE         │
-- │ SCHEMA {{ SCHEMA_CRM_RAW }}   │ USAGE     │ USAGE         │
-- │ TABLES IN {{ SCHEMA_CRM_RAW }}│ CRUD      │ SELECT        │
-- │ SCHEMA {{ SCHEMA_CRM_SILVER }}│ —         │ USAGE         │
-- │ DYN TABLES IN SILVER          │ —         │ SELECT        │
-- └───────────────────────────────┴───────────┴───────────────┘
--
-- Both roles are granted to DCM_ADMIN for deployment access.
-- ============================================================

GRANT USAGE ON DATABASE {{ sf_db }} TO ROLE CRM_{{ sf_env }}_FR_INGEST;
GRANT USAGE ON SCHEMA {{ sf_db }}.{{ SCHEMA_CRM_RAW }} TO ROLE CRM_{{ sf_env }}_FR_INGEST;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA {{ sf_db }}.{{ SCHEMA_CRM_RAW }}
  TO ROLE CRM_{{ sf_env }}_FR_INGEST;

GRANT USAGE ON DATABASE {{ sf_db }} TO ROLE CRM_{{ sf_env }}_FR_ANALYTICS;
GRANT USAGE ON SCHEMA {{ sf_db }}.{{ SCHEMA_CRM_RAW }} TO ROLE CRM_{{ sf_env }}_FR_ANALYTICS;
GRANT SELECT ON ALL TABLES IN SCHEMA {{ sf_db }}.{{ SCHEMA_CRM_RAW }}
  TO ROLE CRM_{{ sf_env }}_FR_ANALYTICS;
GRANT USAGE ON SCHEMA {{ sf_db }}.{{ SCHEMA_CRM_SILVER }} TO ROLE CRM_{{ sf_env }}_FR_ANALYTICS;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA {{ sf_db }}.{{ SCHEMA_CRM_SILVER }}
  TO ROLE CRM_{{ sf_env }}_FR_ANALYTICS;

GRANT ROLE CRM_{{ sf_env }}_FR_INGEST    TO ROLE DCM_ADMIN;
GRANT ROLE CRM_{{ sf_env }}_FR_ANALYTICS TO ROLE DCM_ADMIN;
