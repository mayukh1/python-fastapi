#!/bin/bash
set -e

# ==== CONFIG ====
export NS="fastapi-tk"
export username="xxxxx"
export password="xxxxxxxxxx"
export APP="fastapi-auth"
export REGISTRY="image-registry.openshift-image-registry.svc:5000/python-fastapi"
export PORT="8000"
# GITHUB_URL="https://github.com/mayukh1/python-fastapi.git"
# GIT_REVISION="main"

# ==== Install Tekton tasks ====
tkn hub install task git-clone || true
tkn hub install task openshift-client || true


cat <<EOF | oc apply -f -
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: fastapi-auth
  namespace: fastapi-tk
spec:
  params:
    - name: GIT_REPO
      default: 'https://github.com/mayukh1/python-fastapi.git'
      type: string
    - name: GIT_REVISION
      default: main
      type: string
    - name: REGISTRY
      default: 'image-registry.openshift-image-registry.svc:5000/python-fastapi'
      type: string
    - name: AUTH
      default: authentication
      type: string
    - name: APP
      default: FastApi-Auth
      type: string
    - name: PORT
      default: "8000"
      type: string
  tasks:
    - name: fetch-repo
      params:
        - name: url
          value: $(params.GIT_REPO)
        - name: revision
          value: $(params.GIT_REVISION)
        - name: refspec
          value: ''
      taskRef:
        kind: ClusterTask
        name: git-clone
      workspaces:
        - name: output
          workspace: testmayukh

    - name: build-authentication
      params:
        - name: IMAGE
          value: $(params.REGISTRY)/$(params.AUTH):latest
        - name: DOCKERFILE
          value: Dockerfile
        - name: CONTEXT
          value: $(params.AUTH)
        - name: TLSVERIFY
          value: 'true'
      runAfter:
        - fetch-repo
      taskRef:
        kind: ClusterTask
        name: buildah
      workspaces:
        - name: source
          workspace: testmayukh

    - name: deployment-authentication
      runAfter:
        - build-authentication
      taskRef:
        kind: ClusterTask
        name: openshift-client
      params:
        - name: SCRIPT
          value: |
            #!/bin/sh
            set -e
            echo "Running script..."
            chmod +x ./deployment-tk.sh
            ./deployment-tk.sh $(params.APP) $(params.REGISTRY) $(params.PORT)
        - name: VERSION
          value: latest

  workspaces:
    - name: testmayukh
      optional: false
  finally: []
EOF
