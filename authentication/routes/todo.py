
from typing import Annotated
from fastapi import Depends,APIRouter
from pydantic import BaseModel
from authentication.database import get_db
from authentication.models.schema import Todos
from authentication.routes.user import get_current_user
from starlette import status
from sqlalchemy.orm import Session

router=APIRouter(prefix='/todos')

class TodoRequest(BaseModel):
    comment: str
    
user_dependency = Annotated[dict, Depends(get_current_user)]
db_dependency= Annotated[Session,Depends(get_db)]

@router.post("/todo", status_code=status.HTTP_201_CREATED)
async def create_todo(user: user_dependency, db: db_dependency,
                      todo_request: TodoRequest):
    if user is None:
        raise HTTPException(status_code=401, detail='Authentication Failed')
    todo_model = Todos(**todo_request.model_dump(), owner_id=user.get('id'))

    db.add(todo_model)
    db.commit()