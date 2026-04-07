-- ============================================================
-- 020 — CRMI Customer Master (Ingestion Layer)
-- DCM Project: CRM Domain
-- ============================================================
--
-- OVERVIEW:
-- Customer master data with SCD Type 2 support for tracking
-- attribute changes over time. Includes automated CSV ingestion
-- pipeline (stage → file format → task).
--
-- Supports 11 EMEA countries with localized customer data:
-- Norway, Netherlands, Sweden, Germany, France, Italy,
-- United Kingdom, Denmark, Belgium, Austria, Switzerland
--
-- OBJECTS DEFINED:
-- ├─ TABLES (1):
-- │  └─ CRMI_RAW_TB_CUSTOMER             — Customer master data (SCD Type 2)
-- ============================================================

DEFINE TABLE {{ sf_db }}.{{ SCHEMA_CRM_RAW }}.CRMI_RAW_TB_CUSTOMER (
    CUSTOMER_ID             VARCHAR(30)    NOT NULL
      COMMENT 'Unique customer identifier (CUST_XXXXX format)',
    FIRST_NAME              VARCHAR(100)   NOT NULL
      COMMENT 'Customer first name',
    FAMILY_NAME             VARCHAR(100)   NOT NULL
      COMMENT 'Customer family/last name',
    DATE_OF_BIRTH           DATE           NOT NULL
      COMMENT 'Date of birth (YYYY-MM-DD)',
    ONBOARDING_DATE         DATE           NOT NULL
      COMMENT 'Customer onboarding date',
    REPORTING_CURRENCY      VARCHAR(3)     NOT NULL
      COMMENT 'Reporting currency (EUR, GBP, USD, CHF, NOK, SEK, DKK, PLN)',
    HAS_ANOMALY             BOOLEAN        NOT NULL DEFAULT FALSE
      COMMENT 'Flag indicating customer has anomalous transaction patterns',
    EMPLOYER                VARCHAR(200)
      COMMENT 'Employer name (nullable for unemployed/retired)',
    POSITION                VARCHAR(100)
      COMMENT 'Job position/title',
    EMPLOYMENT_TYPE         VARCHAR(30)
      COMMENT 'Employment type (FULL_TIME, PART_TIME, CONTRACT, SELF_EMPLOYED, RETIRED, UNEMPLOYED)',
    INCOME_RANGE            VARCHAR(30)
      COMMENT 'Income range bracket (e.g., 50K-75K, 100K-150K)',
    ACCOUNT_TIER            VARCHAR(30)
      COMMENT 'Account tier (STANDARD, SILVER, GOLD, PLATINUM, PREMIUM)',
    EMAIL                   VARCHAR(255)
      COMMENT 'Customer email address',
    PHONE                   VARCHAR(50)
      COMMENT 'Customer phone number',
    PREFERRED_CONTACT_METHOD VARCHAR(20)
      COMMENT 'Preferred contact method (EMAIL, SMS, POST, MOBILE_APP)',
    RISK_CLASSIFICATION     VARCHAR(20)
      COMMENT 'Risk classification (LOW, MEDIUM, HIGH)',
    CREDIT_SCORE_BAND       VARCHAR(20)
      COMMENT 'Credit score band (POOR, FAIR, GOOD, VERY_GOOD, EXCELLENT)',
    INSERT_TIMESTAMP_UTC    TIMESTAMP_NTZ  NOT NULL
      COMMENT 'UTC timestamp when this customer record version was inserted (for SCD Type 2)',

    CONSTRAINT PK_CRMI_RAW_TB_CUSTOMER PRIMARY KEY (CUSTOMER_ID, INSERT_TIMESTAMP_UTC)
)
COMMENT = 'Customer master data with SCD Type 2 support. Multiple records per customer, uniquely identified by (CUSTOMER_ID, INSERT_TIMESTAMP_UTC). Address data stored separately in CRMI_RAW_TB_ADDRESSES.';

