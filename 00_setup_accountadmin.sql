-- ============================================================
-- DCM Setup Script - Run as ACCOUNTADMIN in Snowsight
-- ============================================================
-- This script creates the DCM_ADMIN role with least-privilege
-- grants, then switches to DCM_ADMIN to create ALL artefacts
-- (database, stage, DCM project). Because DCM_ADMIN creates
-- everything itself, no ownership transfers are ever needed.
--
-- IMPORTANT: Run ALL statements top-to-bottom in Snowsight.
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- 1. Create DCM_ADMIN role
CREATE ROLE IF NOT EXISTS DCM_ADMIN
  COMMENT = 'Deployment role for DCM Projects - owns all managed objects';

-- 2. Grant DCM_ADMIN to ACCOUNTADMIN (so it remains manageable)
GRANT ROLE DCM_ADMIN TO ROLE ACCOUNTADMIN;

-- 3. Grant DCM_ADMIN to the CI/CD service user and its role
GRANT ROLE DCM_ADMIN TO USER NEWS_CREW_SVC;
GRANT ROLE DCM_ADMIN TO ROLE NEWS_CREW_SVC_ROLE;

-- 4. Grant account-level privileges to DCM_ADMIN
GRANT CREATE DATABASE ON ACCOUNT TO ROLE DCM_ADMIN;
GRANT CREATE ROLE ON ACCOUNT TO ROLE DCM_ADMIN;
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE DCM_ADMIN;

-- 5. Grant warehouse usage
GRANT USAGE ON WAREHOUSE MD_TEST_WH TO ROLE DCM_ADMIN;

-- ============================================================
-- Switch to DCM_ADMIN — everything below is created (and
-- therefore owned) by DCM_ADMIN. No ownership transfers needed.
-- ============================================================
USE ROLE DCM_ADMIN;
USE WAREHOUSE MD_TEST_WH;

-- 6. Create CRM_DEV database
CREATE DATABASE IF NOT EXISTS CRM_DEV
  COMMENT = 'CRM domain - DEV environment';

USE DATABASE CRM_DEV;


-- 9. Create the DCM Project
CREATE DCM PROJECT IF NOT EXISTS CRM_DEV.PUBLIC.CRM_DCM_DEV
  COMMENT = 'DCM Project for CRM domain - DEV environment';

-- ============================================================
-- DONE. After running this, return to Cortex Code to continue.
-- ============================================================
