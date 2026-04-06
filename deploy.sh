#!/usr/bin/env bash
# ============================================================
# deploy.sh — Generic DCM Project deployer
# ============================================================
# Usage:
#   ./deploy.sh <env> [--connection <name>]
#
# Examples:
#   ./deploy.sh dev  --connection DEMO_XXXX
#   ./deploy.sh prod --connection DEMO_XXXX
#
# The script expects these files in the same directory:
#   - dcm.conf              — environment config (sourced)
#   - manifest_<env>.yml    — manifest per environment
#   - sources/definitions/  — SQL definition files
#
# Features:
#   - Always uploads all files (PUT OVERWRITE=TRUE); DCM handles
#     change detection via PLAN.
#   - Pretty-prints the PLAN changeset as a readable table.
#
# Prerequisites:
#   - snow CLI installed and a connection configured
#   - Snowflake connection must inherit DCM_ADMIN
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <env> [--connection <name>]"
  exit 1
fi

ENV="${1}"
shift 1

CONN_FLAG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --connection|-c) CONN_FLAG="--connection $2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

PROJECT_PATH="${SCRIPT_DIR}"
CONF_FILE="${PROJECT_PATH}/dcm.conf"

if [[ ! -f "${CONF_FILE}" ]]; then
  echo "ERROR: No dcm.conf found in '${SCRIPT_DIR}'."
  exit 1
fi

source "${CONF_FILE}"

MANIFEST="$(eval echo "\${${ENV}_MANIFEST:-}")"
STAGE="$(eval echo "\${${ENV}_STAGE:-}")"
PROJECT="$(eval echo "\${${ENV}_PROJECT:-}")"
CONFIG="$(eval echo "\${${ENV}_CONFIG:-}")"

if [[ -z "${STAGE}" || -z "${PROJECT}" || -z "${CONFIG}" ]]; then
  echo "ERROR: Environment '${ENV}' not defined in dcm.conf."
  echo ""
  echo "Expected variables: ${ENV}_MANIFEST, ${ENV}_STAGE, ${ENV}_PROJECT, ${ENV}_CONFIG"
  exit 1
fi

ENV_UPPER="$(echo ${ENV} | tr '[:lower:]' '[:upper:]')"

run_sql() {
  snow sql -q "$1" ${CONN_FLAG}
}

run_sql_json() {
  snow sql -q "$1" ${CONN_FLAG} --format json
}

DCM_TMP=$(mktemp)
trap "rm -f ${DCM_TMP}" EXIT

upload_file() {
  local local_file="$1"
  local stage_target="$2"
  local label="$3"
  local l_size
  l_size=$(wc -c < "${local_file}" | tr -d ' ')
  echo "  -> ${label} (${l_size}B)"
  run_sql "PUT 'file://${local_file}' @${stage_target} AUTO_COMPRESS=FALSE OVERWRITE=TRUE;"
}

format_plan() {
  local infile="$1"
  python3 - "${infile}" << 'PYEOF'
import sys, json, re

raw = open(sys.argv[1]).read()

plan = None
parse_error = None
try:
    data = json.loads(raw)
    if isinstance(data, list) and len(data) > 0:
        row = data[0]
        result = None
        for k in ("result", "RESULT", "Result"):
            if k in row:
                result = row[k]
                break
        if result is None and len(row) == 1:
            result = next(iter(row.values()))
        if isinstance(result, str):
            plan = json.loads(result)
        elif isinstance(result, dict):
            plan = result
    elif isinstance(data, dict):
        plan = data
except Exception as e:
    parse_error = str(e)

if not plan:
    match = re.search(r'\{.*\}', raw, re.DOTALL)
    if match:
        try:
            plan = json.loads(match.group(0))
        except Exception:
            pass

if not plan:
    if parse_error:
        print("  Parse error: %s" % parse_error)
        print("  Raw output (first 300 chars): %s" % raw[:300])
    elif raw.strip():
        for line in raw.splitlines()[:10]:
            stripped = line.strip()
            if stripped:
                print("  " + stripped)
    else:
        print("  (no changeset found in output)")
    sys.exit(0)

cs = plan.get("changeset", [])
if not cs:
    print("  No changes detected.")
    sys.exit(0)

def summarise_grants(changes):
    parts = []
    for g in changes:
        item = g.get("item_id", {})
        desc = item.get("desc", "")
        kind = g.get("kind", "")
        if kind in ("added", "modified"):
            sub = g.get("changes", [])
            privs = []
            for s in sub:
                if s.get("collection_name") == "privileges":
                    for p in s.get("changes", []):
                        pi = p.get("item_id", {})
                        privs.append(pi.get("privilege", pi.get("desc", "")))
            if privs:
                target = desc.split(" ", 1)[-1] if " " in desc else desc
                parts.append("%s ON %s" % (", ".join(privs), target))
            else:
                parts.append(desc)
    return "; ".join(parts[:3]) + (" ..." if len(parts) > 3 else "")

print("")
print("  %d change(s):" % len(cs))
print("")
print("  %-8s %-18s %-35s %s" % ("Action", "Type", "Name", "Details"))
print("  %s %s %s %s" % ("-"*8, "-"*18, "-"*35, "-"*40))
for c in cs:
    action = c.get("type", "?")
    obj = c.get("object_id", {})
    domain = obj.get("domain", "")
    name = obj.get("name", "").strip('"')
    details = ""
    for ch in c.get("changes", []):
        attr = ch.get("attribute_name", "")
        kind = ch.get("kind", "")
        if kind == "changed":
            details = "%s: %s -> %s" % (attr, ch.get("prev_value", ""), ch.get("value", ""))
        elif kind == "set":
            details = "%s = %s" % (attr, ch.get("value", ""))
        elif kind == "collection" and ch.get("collection_name") == "grants":
            details = summarise_grants(ch.get("changes", []))
        else:
            details = "%s: %s" % (kind, attr)
    print("  %-8s %-18s %-35s %s" % (action, domain, name, details))
print("")
PYEOF
}

echo "=========================================="
echo " DCM Deploy — ${PROJECT_LABEL:-DCM} ${ENV_UPPER}"
echo " Project:    ${PROJECT}"
echo " Stage:      ${STAGE}"
echo " Connection: ${CONN_FLAG:-<default>}"
echo "=========================================="

# --- 1. Prepare and upload manifest ---
echo "[1/5] Manifest..."
cp "${PROJECT_PATH}/${MANIFEST}" "${PROJECT_PATH}/manifest.yml"
upload_file \
  "${PROJECT_PATH}/manifest.yml" \
  "${STAGE}/" \
  "manifest.yml"

# --- 2. Upload definition files ---
echo "[2/5] Definition files..."
for f in "${PROJECT_PATH}"/sources/definitions/*.sql; do
  fname="$(basename "$f")"
  upload_file \
    "$f" \
    "${STAGE}/sources/definitions/" \
    "${fname}"
done

# --- 3. Verify stage ---
echo "[3/5] Stage contents:"
run_sql "LIST @${STAGE}/;"

# --- 4. Plan ---
echo "[4/5] Running PLAN..."
PLAN_RC=0
PLAN_OUTPUT=$(run_sql_json "EXECUTE DCM PROJECT ${PROJECT} PLAN USING CONFIGURATION ${CONFIG} FROM @${STAGE}/;" 2>&1) || PLAN_RC=$?
echo "${PLAN_OUTPUT}" > "${DCM_TMP}"
format_plan "${DCM_TMP}"

if [[ ${PLAN_RC} -ne 0 ]]; then
  echo "PLAN failed (exit code ${PLAN_RC}) — fix the issues above before deploying."
  exit 1
fi

# --- 5. Deploy ---
read -rp "Proceed with DEPLOY? [y/N] " confirm
if [[ "${confirm}" =~ ^[Yy]$ ]]; then
  echo "[5/5] Deploying..."
  DEPLOY_RC=0
  DEPLOY_OUTPUT=$(run_sql_json "EXECUTE DCM PROJECT ${PROJECT} DEPLOY USING CONFIGURATION ${CONFIG} FROM @${STAGE}/;" 2>&1) || DEPLOY_RC=$?
  echo "${DEPLOY_OUTPUT}" > "${DCM_TMP}"
  format_plan "${DCM_TMP}"
  if [[ ${DEPLOY_RC} -ne 0 ]]; then
    echo "DEPLOY failed (exit code ${DEPLOY_RC}) — review the output above."
    exit 1
  fi
  echo "Done — ${PROJECT_LABEL:-DCM} ${ENV_UPPER} deployment complete."
else
  echo "Deployment cancelled."
fi
