# python-fastapi
fastapi using jwt authentication
# requirement.txt is required for installing the dependencies
# uvicorn authentication.main:app --reload
# pip install fastapi[all] uvicorn sqlalchemy asyncpg psycopg2-binary
# pip install psycopg[binary]
# POSTGRESQL_HOST = os.getenv("POSTGRESQL_HOST", "localhost") try this on production with the postgres svc name(postgresql instate of localhost because both backend and db service are running via two different pods)

# step 1: build the dockerfile and push the images to quay.io and deploy as a container images
# step 2: build as a deployment config with a build strategy docker push it to image stream and then finally run the application( build step[1,2,3] set the env for both the pods as env in auth and db applications)
# oc set env 
POSTGRESQL_USER 
POSTGRESQL_PASSWORD 
POSTGRESQL_HOST 
POSTGRESQL_PORT 
POSTGRESQL_DATABASE
POSTGRESQL_DATABASE_URL = postgresql://${POSTGRESQL_USER}:${POSTGRESQL_PASSWORD}@${POSTGRESQL_HOST}:${POSTGRESQL_PORT}/${POSTGRESQL_DATABASE}

Note: there will be chances you need to create the db name by inside(terminal) db pods
