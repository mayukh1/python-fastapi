from datetime import datetime, timedelta, timezone
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy.orm import Session
from authentication.database import get_db
from starlette import status
from passlib.context import CryptContext
from authentication.models.schema import Users
from jose import jwt,JWTError

router=APIRouter(prefix='/register')

class CreateUserRequest(BaseModel):
    firstname: str
    lastname: str
    email: str
    password: str
    username: str
  
class Config:
    orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

db_dependency=Annotated[Session,Depends(get_db)]
bcrypt_context = CryptContext(schemes=['bcrypt'], deprecated='auto')
oauth2_bearer = OAuth2PasswordBearer(tokenUrl='auth/token')

SECRET_KEY = '197b2c37c391bed93fe80344fe73b806947a65e36206e05a1a23c2fa12702fe3'
ALGORITHM = 'HS256'

# extract the jwt token to verify user and do other things
async def get_current_user(token: Annotated[str, Depends(oauth2_bearer)]):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get('sub')
        user_id: int = payload.get('id')
        user_role: str = payload.get('role')
        if username is None or user_id is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                                detail='Could not validate user.')
        return {'username': username, 'id': user_id,'user_role': user_role}
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail='Could not validate user.')


def authenticate_user(username: str, password: str, db):
    user = db.query(Users).filter(Users.username == username).first()
    if not user:
        return False
    if not bcrypt_context.verify(password, user.hashed_password):
        return False
    return user
def create_access_token(username: str, user_id: int, role: str, expires_delta: timedelta):
    encode = {'sub': username, 'id': user_id,'role': role}
    expires = datetime.now(timezone.utc) + expires_delta
    encode.update({'exp': expires})
    return jwt.encode(encode, SECRET_KEY, algorithm=ALGORITHM)

@router.post("/user",status_code=status.HTTP_201_CREATED)
async def create(db:db_dependency,create_user:CreateUserRequest):
    user=db.query(Users).filter(Users.username==create_user.username).first()
    if user:
        raise HTTPException(status_code="409",detail="user already exists")
    create_user_model=Users(
        first_name=create_user.firstname,
        last_name=create_user.lastname,
        email=create_user.email,
        hashed_password=bcrypt_context.hash(create_user.password),
        username=create_user.username,
        is_active=True
        #is_createdAt= datetime.now().time()
    )
    db.add(create_user_model)
    db.commit()
    db.refresh(create_user_model)
    return {"id": create_user_model.id, "firstname": create_user_model.first_name, "email": create_user_model.email}

# click on login it will request for token and store that token in frontend and verify the user
@router.post("/user/token",response_model=Token)
async def login_token(form_data:Annotated[OAuth2PasswordRequestForm,Depends()],db:db_dependency):
    user = authenticate_user(form_data.username, form_data.password, db)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)
    token= create_access_token(user.username, user.id, user.role, timedelta(minutes=20))
    return {'access_token': token, 'token_type': 'bearer'}