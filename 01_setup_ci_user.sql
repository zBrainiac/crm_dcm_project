-- ============================================================
-- CI User Setup — Run as ACCOUNTADMIN in Snowsight
-- ============================================================
-- Creates a dedicated service user for GitHub Actions CI/CD
-- using RSA key-pair (JWT) authentication.
--
-- Steps after running:
--   1. Generate an RSA key pair (PKCS#8, unencrypted):
--        openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
--        openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
--   2. Copy the public key (without headers) and paste below.
--   3. Store the full private key PEM as GitHub secret SNOWFLAKE_PRIVATE_KEY.
-- ============================================================

USE ROLE ACCOUNTADMIN;

CREATE USER IF NOT EXISTS DCM_CI_SVC
  TYPE = SERVICE
  COMMENT = 'Service user for DCM CI/CD via GitHub Actions';

CREATE ROLE IF NOT EXISTS DCM_CI_SVC_ROLE
  COMMENT = 'Role for DCM CI/CD service user';

GRANT ROLE DCM_CI_SVC_ROLE TO USER DCM_CI_SVC;
GRANT ROLE DCM_ADMIN TO ROLE DCM_CI_SVC_ROLE;
GRANT ROLE DCM_ADMIN TO USER DCM_CI_SVC;
GRANT USAGE ON WAREHOUSE MD_TEST_WH TO ROLE DCM_CI_SVC_ROLE;

ALTER USER DCM_CI_SVC SET DEFAULT_ROLE = DCM_CI_SVC_ROLE;
ALTER USER DCM_CI_SVC SET DEFAULT_WAREHOUSE = MD_TEST_WH;

-- Set the RSA public key (paste your key between the quotes)
ALTER USER DCM_CI_SVC SET RSA_PUBLIC_KEY = '<paste-public-key-here>';

-- ============================================================
-- GitHub Secrets to configure at:
--   https://github.com/zBrainiac/crm_dcm_project/settings/secrets/actions
--
--   SNOWFLAKE_ACCOUNT     = sfseeurope-demo_mdaeppen
--   SNOWFLAKE_USER        = DCM_CI_SVC
--   SNOWFLAKE_PRIVATE_KEY = (full PEM content of rsa_key.p8,
--                            including -----BEGIN/END PRIVATE KEY-----)
-- ============================================================
