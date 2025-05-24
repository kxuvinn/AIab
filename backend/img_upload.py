# from fastapi import APIRouter, File, UploadFile
# import os, shutil

# router = APIRouter()

# UPLOAD_DIR = "problems"
# BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) 
# UPLOAD_DIR = os.path.join(BASE_DIR, "AI", "testcases", "problems")

# print("UPLOAD_DIR: ", UPLOAD_DIR)

# os.makedirs(UPLOAD_DIR, exist_ok=True)

# @router.post("/upload")
# async def upload_image(file: UploadFile = File(...)):
#     file_path = os.path.join(UPLOAD_DIR, file.filename)
#     with open(file_path, "wb") as buffer:
#         shutil.copyfileobj(file.file, buffer)
#     return {"filename": file.filename}

from fastapi import APIRouter, UploadFile, File
from fastapi.responses import JSONResponse
import os
from shutil import copyfileobj
from AI.ai_processor import process_image

router = APIRouter()

UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "testcases", "problems")
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    file_path = os.path.join(UPLOAD_DIR, file.filename)
    
    with open(file_path, "wb") as f:
        copyfileobj(file.file, f)

    try:
        # 저장 후 바로 AI 분석 수행
        result = process_image(file_path)
        return JSONResponse(content={"success": True, "result": result})
    except Exception as e:
        return JSONResponse(status_code=500, content={"success": False, "error": str(e)})