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
  --from-literal=POSTGRESQL_USER=postgres \
  --from-literal=POSTGRESQL_PASSWORD=root \
  --from-literal=POSTGRESQL_DATABASE=test_db \
  --dry-run=client -o yaml | oc apply -f -

# ==== 3. Deploy PostgreSQL ====
if ! oc get deploy "$POSTGRES_NAME" >/dev/null 2>&1; then
  oc new-app postgres:13 \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=root \
    -e POSTGRES_DB=test_db \
    --name="$POSTGRES_NAME"
  oc expose svc/"$POSTGRES_NAME"
fi

# ==== 4. Install Tekton tasks ====
tkn hub install task git-clone || true
tkn hub install task openshift-client || true

# ==== 5. Create Tekton Pipeline ====
cat <<EOF | oc apply -f -
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: user-auto-deploy
spec:
  params:
    - name: GITHUB_URL
      type: string
    - name: APP_NAME
      type: string
    - name: NAMESPACE
      type: string
  workspaces:
    - name: shared
  tasks:
    - name: clone-repo
      taskRef:
        name: git-clone
      params:
        - name: url
          value: \$(params.GITHUB_URL)
      workspaces:
        - name: output
          workspace: shared

    - name: build-and-deploy
      taskRef:
        name: openshift-client
      runAfter: [clone-repo]
      params:
        - name: SCRIPT
          value: |
            #!/bin/bash
            set -xe

            oc project \$(params.NAMESPACE)

            if ! oc get bc \$(params.APP_NAME); then
              oc new-build --name=\$(params.APP_NAME) --binary --strategy=docker
            fi
            # Start build from the checked-out source
            
			oc start-build \$(params.APP_NAME) --from-dir=\$(workspaces.source.path) --wait

            if ! oc get deploy \$(params.APP_NAME); then
              oc new-app \$(params.APP_NAME) \
                --name=\$(params.APP_NAME) \
                -e POSTGRESQL_USER=postgres \
                -e POSTGRESQL_PASSWORD=root \
                -e POSTGRESQL_DATABASE=test_db \
                -e POSTGRESQL_HOST=postgresql \
                -e POSTGRESQL_PORT=5432 \
				-e POSTGRESQL_DATABASE_URL=postgresql://${POSTGRESQL_USER}:${POSTGRESQL_PASSWORD}@${POSTGRESQL_HOST}:${POSTGRESQL_PORT}/${POSTGRESQL_DATABASE} \

              oc expose svc/\$(params.APP_NAME)
            fi
      workspaces:
        - name: source
          workspace: shared
EOF

# ==== 7. Create TriggerTemplate ====
cat <<EOF | oc apply -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: user-deploy-run
spec:
  pipelineRef:
    name: user-auto-deploy
  params:
    - name: GITHUB_URL
      value: $GITHUB_URL
    - name: APP_NAME
      value: $APP_NAME
    - name: NAMESPACE
      value: $NAMESPACE
  workspaces:
    - name: shared
      volumeClaimTemplate:
        metadata:
          name: fastapi-workspace-pvc
        spec:
          accessModes: [ "ReadWriteOnce" ]
          resources:
            requests:
              storage: 1Gi
EOF
