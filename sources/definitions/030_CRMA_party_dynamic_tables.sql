-- ============================================================
-- 030 — CRMA Party Dynamic Tables (Aggregation Layer)
-- DCM Project: CRM Domain
-- ============================================================
--
-- OVERVIEW:
-- Silver-layer dynamic tables providing current-state and
-- historical (SCD Type 2) views of customer/party data.
-- Aligned with the OMG Party Model for enterprise data
-- architecture consistency.
--
-- OBJECTS DEFINED:
-- ┌─ DYNAMIC TABLES (2):
-- │  ├─ CRMA_CUR_DT_PARTY      — Current party state (1 row/customer)
-- │  └─ CRMA_CUR_DT_PARTY_HIST — Full SCD Type 2 history with
-- │                               VALID_FROM / VALID_TO ranges
--
-- REFRESH:
-- Both tables use TARGET_LAG = 60 MINUTE for near-real-time
-- propagation from the RAW layer.
-- ============================================================

DEFINE DYNAMIC TABLE {{ sf_db }}.{{ SCHEMA_CRM_SILVER }}.CRMA_CUR_DT_PARTY
  TARGET_LAG = '1 hour'
  WAREHOUSE = {{ wh }}
  COMMENT = 'Current/latest party (customer) attributes. One record per customer showing the most recent state. Aligned with OMG Party Model.'
AS
SELECT
    CUSTOMER_ID,
    FIRST_NAME,
    FAMILY_NAME,
    CONCAT(FIRST_NAME, ' ', FAMILY_NAME) AS FULL_NAME,
    DATE_OF_BIRTH,
    ONBOARDING_DATE,
    REPORTING_CURRENCY,
    HAS_ANOMALY,
    EMPLOYER,
    POSITION,
    EMPLOYMENT_TYPE,
    INCOME_RANGE,
    ACCOUNT_TIER,
    EMAIL,
    PHONE,
    PREFERRED_CONTACT_METHOD,
    RISK_CLASSIFICATION,
    CREDIT_SCORE_BAND,
    INSERT_TIMESTAMP_UTC AS PARTY_FROM,
    TRUE AS IS_CURRENT
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC DESC) AS RN
    FROM {{ sf_db }}.{{ SCHEMA_CRM_RAW }}.CRMI_RAW_TB_CUSTOMER
) RANKED
WHERE RN = 1;


DEFINE DYNAMIC TABLE {{ sf_db }}.{{ SCHEMA_CRM_SILVER }}.CRMA_CUR_DT_PARTY_HIST
  TARGET_LAG = '1 hour'
  WAREHOUSE = {{ wh }}
  COMMENT = 'SCD Type 2 party history with VALID_FROM/VALID_TO ranges. Full customer attribute history for compliance, audit, and point-in-time queries.'
AS
SELECT
    CUSTOMER_ID,
    FIRST_NAME,
    FAMILY_NAME,
    CONCAT(FIRST_NAME, ' ', FAMILY_NAME) AS FULL_NAME,
    DATE_OF_BIRTH,
    ONBOARDING_DATE,
    REPORTING_CURRENCY,
    HAS_ANOMALY,
    EMPLOYER,
    POSITION,
    EMPLOYMENT_TYPE,
    INCOME_RANGE,
    ACCOUNT_TIER,
    EMAIL,
    PHONE,
    PREFERRED_CONTACT_METHOD,
    RISK_CLASSIFICATION,
    CREDIT_SCORE_BAND,
    INSERT_TIMESTAMP_UTC::DATE AS VALID_FROM,
    CASE
        WHEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC) IS NOT NULL
        THEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC)::DATE - 1
        ELSE NULL
    END AS VALID_TO,
    CASE
        WHEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC) IS NULL
        THEN TRUE
        ELSE FALSE
    END AS IS_CURRENT,
    INSERT_TIMESTAMP_UTC
FROM {{ sf_db }}.{{ SCHEMA_CRM_RAW }}.CRMI_RAW_TB_CUSTOMER
ORDER BY CUSTOMER_ID, INSERT_TIMESTAMP_UTC;
