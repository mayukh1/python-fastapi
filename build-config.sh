#!/bin/bash
set -e

# ==== CONFIG ====
NAMESPACE="fastapi"
APP_NAME="user_auth"
POSTGRES_NAME="postgresql"
GITHUB_URL="https://github.com/mayukh1/python-fastapi.git"
#SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# ==== 1. Setup OpenShift project ====
oc new-project "$NAMESPACE" || oc project "$NAMESPACE"

# ==== 2. Create DB credentials secret ====
oc create secret generic db-secret \
  --from-literal=POSTGRESQL_USER=postgresql \
  --from-literal=POSTGRESQL_PASSWORD=root \
  --from-literal=POSTGRESQL_DATABASE=test_db \
  --dry-run=client -o yaml | oc apply -f -

# ==== 3. Deploy PostgreSQL ====
if ! oc get deploy "$POSTGRES_NAME" >/dev/null 2>&1; then
  oc new-app postgres:13 \    #can change you image name according to availbility registry.redhat.io/rhel8/postgresql-13:latest
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=root \
    -e POSTGRES_DB=test_db \
    --name="$POSTGRES_NAME"
  oc expose svc/"$POSTGRES_NAME"
fi
#=== 4. you can use env value from secret itself ====
oc set env bc/"$POSTGRES_NAME" --from=secret/db-secret
NOTE you can use any one 3 or 4

# ==== 5. Deploy FastAPI app ====
oc new-app $GITHUB_URL \
--name="$APP_NAME" --strategy=docker \
-e POSTGRESQL_USER=postgresql \
-e POSTGRESQL_PASSWORD=root \
-e POSTGRESQL_DATABASE=test_db \
-e POSTGRESQL_HOST=postgresql \
-e POSTGRESQL_PORT=5432
-e POSTGRESQL_DATABASE_URL=postgresql://postgresql:root@postgresql:5432/test_db  # you don't need to give this because the url mentioned in authentication.database.py file

# ==== 6. Route FastAPI app ====
oc expose svc/"$APP_NAME"
# oc get route
# <url>/docs #open the swagger form of fast api

Note:
# postgresql://{POSTGRESQL_USER}:{POSTGRESQL_PASSWORD}@{POSTGRESQL_HOST}:{POSTGRESQL_PORT}/{POSTGRESQL_DATABASE}
# Check the build config log for all the pods try
