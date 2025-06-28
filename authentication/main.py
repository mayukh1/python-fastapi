from fastapi import FastAPI
from authentication.database import engine, Base
from authentication.routes import todo,user

app = FastAPI(debug=True)

Base.metadata.create_all(bind=engine)

# it will route to every single page where the link was given
#app.include_router(login.router)
app.include_router(todo.router)
app.include_router(user.router)
