from fastapi import APIRouter, File, UploadFile
import os, shutil

router = APIRouter()

UPLOAD_DIR = "problems"
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) 
UPLOAD_DIR = os.path.join(BASE_DIR, "AI", "testcases", "problems")

print("UPLOAD_DIR: ", UPLOAD_DIR)

os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    file_path = os.path.join(UPLOAD_DIR, file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    return {"filename": file.filename}