# task_service/main.py

from fastapi import FastAPI, Depends, HTTPException
from models import TaskCreate, Task
from typing import List

app = FastAPI()

# In-memory task DB
fake_tasks = []
task_id_counter = 1


