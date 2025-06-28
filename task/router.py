from fastapi import APIRouter, Depends, HTTPException
from task.models.schema import Task, TaskCreate


router=APIRouter(prefix='/')



@router.post("tasks", response_model=Task)
def create_task(data: TaskCreate, user=Depends(require_role("admin", "user"))):
    global task_id_counter
    task = {
        "id": task_id_counter,
        "title": data.title,
        "description": data.description,
        "owner": user["username"]
    }
    fake_tasks.append(task)
    task_id_counter += 1
    return task

@app.get("tasks", response_model=List[Task])
def list_tasks(user=Depends(require_role("admin", "user", "viewer"))):
    return fake_tasks

@app.delete("/tasks/{task_id}")
def delete_task(task_id: int, user=Depends(require_role("admin"))):
    for i, task in enumerate(fake_tasks):
        if task["id"] == task_id:
            del fake_tasks[i]
            return {"detail": "Task deleted"}
    raise HTTPException(status_code=404, detail="Task not found")