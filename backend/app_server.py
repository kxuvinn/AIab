import json
from fastapi import FastAPI, APIRouter, UploadFile, File, Form, Request
from fastapi.responses import PlainTextResponse
import shutil
import os
from dotenv import load_dotenv
from AI.ai_processor import process_image
from fastapi.responses import JSONResponse

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

@router.post("/save-json")
async def save_json_to_file(request: Request):
    json_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend", "ai_result.json"))
    try:
        data = await request.json()
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return {"message": "JSON 저장 완료"}
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


@router.get("/search-history")
async def get_search_history():
    json_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend", "ai_result.json"))

    if not os.path.exists(json_path):
        return JSONResponse(content={"error": "파일이 존재하지 않습니다."}, status_code=404)

    try:
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return JSONResponse(content=data)
    except Exception as e:
        return JSONResponse(content={"error": f"파일 읽기 오류: {str(e)}"}, status_code=500)

# 라우터를 app에 등록
app.include_router(router)