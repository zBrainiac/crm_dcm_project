# DCM Projects — Declarative Change Management for Snowflake

## Why

Manual SQL scripts and over-extended Terraform usage lead to **configuration drift**, **poor change visibility**, and **brittle rollbacks** across Snowflake environments. Data engineers need a Snowflake-native, SQL-first way to promote changes safely across DEV/TEST/UAT/PRD without leaving their native language.

**DCM Projects** solve this from inside the platform: you describe the desired end state with `DEFINE` statements and Snowflake computes the diff — no imperative DDL sequences, no external state files, no click-ops in production.

## What

This repository contains a complete, production-ready example of a **CRM domain** managed entirely through DCM Projects:

| File | Purpose |
|------|---------|  
| `deploy.sh` | Generic deployer -- uploads definitions, runs PLAN, prompts, then DEPLOY |
| `manifest_*.yml` | Per-environment manifest with Jinja templating (DEV/PROD) |
| `dcm.conf` | Environment configuration (stage, project, config name) |
| `00_setup_accountadmin.sql` | One-time setup: DCM_ADMIN role, database, stage, project |
| `sources/definitions/010-030` | Schemas, tables (SCD Type 2), dynamic tables (OMG Party Model) |
| `sources/definitions/800-810` | Functional roles and least-privilege grant wiring |
| `.github/workflows/` | GitHub Actions: PLAN on PR, gated DEPLOY on merge to main |

## How

**1. One-time setup** — Run `00_setup_accountadmin.sql` in Snowsight as ACCOUNTADMIN.

**2. Local deploy**
```bash
./deploy.sh dev  --connection DEMO_XXXX
./deploy.sh prod --connection DEMO_XXXX
```

The script uploads all definition files to the stage, runs `EXECUTE DCM PROJECT ... PLAN` to show a human-readable changeset, then prompts before `DEPLOY`.

**3. CI/CD setup (key-pair auth)**

Generate an RSA key pair for the CI service user:
```bash
# 1. Generate private key (PKCS#8, unencrypted)
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt

# 2. Extract public key
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub

# 3. Set public key on the Snowflake CI user (run as ACCOUNTADMIN)
#    Strip the -----BEGIN/END PUBLIC KEY----- headers first:
grep -v "PUBLIC KEY" rsa_key.pub | tr -d '\n'
```
```sql
ALTER USER DCM_CI_SVC SET RSA_PUBLIC_KEY = '<paste key without headers>';
```

Store these GitHub secrets (`Settings > Secrets > Actions`):
| Secret | Value |
|--------|-------|
| `SNOWFLAKE_ACCOUNT` | `<org>-<account>` (e.g. `sfseeurope-demo_mdaeppen`) |
| `SNOWFLAKE_USER` | `DCM_CI_SVC` |
| `SNOWFLAKE_PRIVATE_KEY` | Full content of `rsa_key.p8` (including `-----BEGIN/END PRIVATE KEY-----`) |

Push to `main` triggers GitHub Actions: automatic DEV deploy, gated PROD deploy with manual approval.

**4. Adding objects** — Add a new `.sql` file under `sources/definitions/`, use `DEFINE` statements with Jinja variables, and deploy.

Available Jinja variables (set per environment in `manifest_*.yml`):

| Variable | DEV | PROD | Usage |
|----------|-----|------|-------|
| `{{ sf_env }}` | `DEV` | `PRD` | Environment suffix for roles, grants |
| `{{ sf_db }}` | `CRM_DEV` | `CRM_PRD` | Target database name |
| `{{ wh }}` | `MD_TEST_WH` | `MD_TEST_WH` | Warehouse for dynamic tables |
| `{{ SCHEMA_CRM_RAW }}` | `CRM_RAW_V001` | `CRM_RAW_V001` | Raw ingestion schema |
| `{{ SCHEMA_CRM_SILVER }}` | `CRM_SILVER_V001` | `CRM_SILVER_V001` | Curated/silver schema |

## References

- [Snowflake DCM Projects Documentation](https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-overview)
- [Deploy and Manage DCM Projects](https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-use)

