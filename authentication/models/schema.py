from authentication.database import Base
from sqlalchemy import Column, Integer, String, Boolean,BigInteger,ForeignKey

class Users(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String, unique=True)
    username = Column(String, unique=True)
    first_name = Column(String)
    last_name = Column(String)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    #is_admin = Column(Boolean,default=False)
    #is_createdAt = Column()
    role = Column(String)
    phone_number = Column(String)


class Todos(Base):
    __tablename__ = 'todos'

    id = Column(Integer, primary_key=True, index=True)
    comment = Column(String)
    owner_id = Column(Integer, ForeignKey("users.id"))
