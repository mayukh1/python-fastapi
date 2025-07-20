#!/bin/bash
set -e

# ==== CONFIG ====
NAMESPACE="fastapi"
APP_NAME="user_auth"
POSTGRES_NAME="postgresql"
GITHUB_URL="https://github.com/mayukh1/python-fastapi.git"
GIT_REVISION="main"
IMAGE_NAME="image-registry.openshift-image-registry.svc:5000/test/python-fastapi-git"

# ==== 4. Install Tekton tasks ====
tkn hub install task git-clone || true
tkn hub install task openshift-client || true

# ==== 5. Create Tekton Pipeline ====
cat <<EOF | oc apply -f -
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
spec:
  params:
    - name: GITHUB_URL
      type: string
      default: 'https://github.com/mayukh1/python-fastapi.git'
    - name: GIT_REVISION
      type: string
      default: main
    - name: APP_NAME
      type: string
    - name: NAMESPACE
      type: string
    - name: IMAGE_NAME
      type: string
      default: 'image-registry.openshift-image-registry.svc:5000/test/python-fastapi-git'
  workspaces:
    - name: shared
  tasks:
    - name: fetch-repository
      taskRef:
        kind: ClusterTask
        name: git-clone
      params:
        - name: url
          value: $(params.GITHUB_URL)
        - name: revision
          value: $(params.GIT_REVISION)
        - name: subdirectory
          value: ''
        - name: deleteExisting
          value: 'true'
      workspaces:
        - name: output
          workspace: shared

    - name: build
      runAfter: fetch-repository
      taskRef:
        kind: ClusterTask
        name: buildah
      workspaces:
        - name: source
          workspace: workspace
      params:
        - name: IMAGE
          value: $(params.IMAGE_NAME)
        - name: TLSVERIFY
          value: 'false'
        - name: CONTEXT
          value: $(params.PATH_CONTEXT)

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
