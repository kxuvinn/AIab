from fastapi import FastAPI, APIRouter, UploadFile, File, Form
from fastapi.responses import PlainTextResponse
import shutil
import os
from dotenv import load_dotenv
from AI.ai_processor import process_image

load_dotenv()

app = FastAPI()
router = APIRouter()

UPLOAD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "AI", "testcases", "problems"))
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload", response_class=PlainTextResponse)
async def upload_and_process(file: UploadFile = File(...), grade: str = Form(...)):
    if not grade:
        return "❗ 학년 정보가 제공되지 않았습니다."

    file_path = os.path.join(UPLOAD_DIR, file.filename)
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        return f"❗ 파일 저장 중 오류 발생: {str(e)}"

    try:
        result = process_image(file_path, grade)
    except Exception as e:
        return f"❗ 이미지 처리 중 오류 발생: {str(e)}"

    return result

# 라우터를 app에 등록
app.include_router(router)
