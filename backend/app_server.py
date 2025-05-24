from fastapi import FastAPI, UploadFile, File
from fastapi.responses import PlainTextResponse
import shutil
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from dotenv import load_dotenv
from AI.ai_processor import process_image 
load_dotenv()

app = FastAPI()

UPLOAD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "AI", "testcases", "problems"))
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.post("/upload", response_class=PlainTextResponse)
async def upload_and_process(file: UploadFile = File(...)):
    file_path = os.path.join(UPLOAD_DIR, file.filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    result = process_image(file_path)
    return result