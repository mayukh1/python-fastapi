import os
from dotenv import load_dotenv
load_dotenv()
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker


# Build DB URL from environment variables
POSTGRESQL_USER = os.getenv("POSTGRESQL_USER","postgres")
POSTGRESQL_PASSWORD = os.getenv("POSTGRESQL_PASSWORD","root")
POSTGRESQL_HOST = os.getenv("POSTGRESQL_HOST", "postgresql")
POSTGRESQL_PORT = os.getenv("POSTGRESQL_PORT", "5432")
POSTGRESQL_DATABASE = os.getenv("POSTGRESQL_DATABASE","test_db")

#POSTGRESQL_DATABASE_URL = "postgresql://postgres:root@localhost:5432/test_db"
# Dynamically build the connection string
POSTGRESQL_DATABASE_URL = (
    f"postgresql://{POSTGRESQL_USER}:{POSTGRESQL_PASSWORD}@{POSTGRESQL_HOST}:{POSTGRESQL_PORT}/{POSTGRESQL_DATABASE}"
)
engine = create_engine(POSTGRESQL_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# you can use this function to every created python file injecting Annotated[Session,Depend(get_db)]
def get_db():
    db = SessionLocal()
    try:
        yield db
    except Exception:
        db.rollback()
        raise 
    finally:
        db.close()



