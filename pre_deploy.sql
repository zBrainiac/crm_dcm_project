CREATE DATABASE IF NOT EXISTS {{ sf_db }}
    COMMENT = 'CRM domain development database';

CREATE SCHEMA IF NOT EXISTS {{ sf_db }}.CRM_DCM;
CREATE SCHEMA IF NOT EXISTS {{ sf_db }}.{{ SCHEMA_CRM_RAW }}
    COMMENT = 'RAW layer - CRM customer data landing zone';
CREATE SCHEMA IF NOT EXISTS {{ sf_db }}.{{ SCHEMA_CRM_CUR }}
    COMMENT = 'CUR layer - curated analytics-ready customer data';

CREATE DCM PROJECT IF NOT EXISTS {{ sf_db }}.CRM_DCM.CRM_DCM_DEV;
