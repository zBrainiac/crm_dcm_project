-- ============================================================
-- 800 — CRM Functional Roles
-- DCM Project: CRM Domain
-- ============================================================
--
-- OVERVIEW:
-- Two functional roles providing least-privilege access to the
-- CRM domain schemas. Role names follow the pattern:
--   CRM_<ENV>_FR_<PERSONA>
--
-- OBJECTS DEFINED:
-- ┌─ ROLES (2):
-- │  ├─ CRM_{{ sf_env }}_FR_INGEST    — Read+write RAW, read SILVER
-- │  └─ CRM_{{ sf_env }}_FR_ANALYTICS — Read-only RAW + SILVER
-- ============================================================

DEFINE ROLE CRM_{{ sf_env }}_FR_INGEST;
DEFINE ROLE CRM_{{ sf_env }}_FR_ANALYTICS;
