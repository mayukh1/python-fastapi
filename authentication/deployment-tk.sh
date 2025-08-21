#!/bin/bash
set -e

# ==== CONFIG ====
# export NS="fastapi-tk"
# export APP="FastApi-Auth"
# export REGISTRY="image-registry.openshift-image-registry.svc:5000/python-fastapi"
# export PORT="8000"

APP=$1
REGISTRY=$2
PORT=$3

cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $APP
  template:
    metadata:
      labels:
        app: $APP
    spec:
      containers:
        - name: authentication
          image: $REGISTRY/authentication:latest
          ports:
            - containerPort: $PORT
---
apiVersion: v1
kind: Service
metadata:
  name: $APP
spec:
  selector:
    app: $APP
  ports:
    - port: $PORT
      targetPort: $PORT
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: $APP
spec:
  to:
    kind: Service
    name: $APP
  port:
    targetPort: $PORT
  tls:
    termination: edge
EOF
