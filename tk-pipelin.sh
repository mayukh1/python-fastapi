#!/bin/bash
set -e

# ==== CONFIG ====
NAMESPACE="fastapi"
APP_NAME="user_auth"
POSTGRES_NAME="postgresql"
GITHUB_URL="https://github.com/mayukh1/python-fastapi.git"
GIT_REVISION="main"
IMAGE_NAME="image-registry.openshift-image-registry.svc:5000/test/python-fastapi-git"
PATH_CONTEXT="app"

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
      params:
        - name: IMAGE
          value: $(params.IMAGE_NAME)
        - name: TLSVERIFY
          value: 'false'
        - name: CONTEXT
          value: $(params.PATH_CONTEXT)    #docker build -t my-image . similar to this command
        - name: DOCKERFILE
          value: $(params.PATH_CONTEXT)/Dockerfile
      workspaces:
        - name: source
          workspace: workspace

    - name: deploy
      runAfter: build
      taskRef:
        kind: ClusterTask
        name: openshift-client
      params:
        - name: SCRIPT
          value: |
            if ! oc get deploy/$(params.APP_NAME); then
              oc new-app --name=$(params.APP_NAME) --docker-image=$(params.IMAGE_NAME)
            fi
            oc rollout status deploy/$(params.APP_NAME)
      workspaces:
        - name: source
          workspace: shared
EOF

