import os
import sys

from pydantic import BaseModel
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi import FastAPI, Body, Query, Form
from fastapi.middleware.cors import CORSMiddleware
from .models import (
    SignupRequest,
    LoginRequest,
    CheckIdRequest,
    QuizSolveRequest,
    ExplanationRequest,
    QuizGenerateRequest,
    QuizResult,
    BulkAnswerRequest,
    AnswerItem
)
from datetime import date, datetime
import json
#from dotenv import load_dotenv
from openai import OpenAI
from typing import List
import re

from fastapi.responses import JSONResponse
import numpy as np
import matplotlib.pyplot as plt
import base64
import io
from sympy import symbols, sympify, lambdify

from AI.ai_processor import process_image
from AI.ai_processor import recommend_problems_with_gpt

import json
from fastapi import FastAPI, APIRouter, UploadFile, File, Form, Body, Request
from fastapi.responses import PlainTextResponse, JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
import shutil
import os
from dotenv import load_dotenv
from AI.ai_processor import process_image
from typing import Any



#load_dotenv()
#client = OpenAI()

# ⛔️ 민감 정보
client = OpenAI(api_key="")


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
USER_DATA_FILE = os.path.join(BASE_DIR, 'users.json')
SOLVE_LOG_FILE = os.path.join(BASE_DIR, 'solve_log.json')   #오늘의퀴즈
AI_TEST_FILE = os.path.join(BASE_DIR, 'ai_test.json')     #AI시험지지


def load_json_file(path):
    if not os.path.exists(path):
        return {}
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json_file(path, data):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if not os.path.exists(USER_DATA_FILE):
    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dumps({}, f, indent=4, ensure_ascii=False)

if not os.path.exists(SOLVE_LOG_FILE):
    with open(SOLVE_LOG_FILE, 'w', encoding='utf-8') as f:
        json.dumps({}, f, indent=4, ensure_ascii=False)

@app.post("/signup")
async def signup(user: SignupRequest):
    try:
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
    except:
        users = {}

    if user.id in users:
        return {"success": False, "message": "이미 존재하는 아이디입니다."}

    users[user.id] = {"password": user.password, "grade": user.grade}

    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(users, f, indent=4, ensure_ascii=False)

    return {"success": True, "message": "회원가입 성공"}

@app.post("/login")
async def login(user: LoginRequest):
    try:
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
    except:
        users = {}

    if user.id not in users:
        return {"success": False, "message": "존재하지 않는 아이디입니다."}

    if users[user.id]["password"] != user.password:
        return {"success": False, "message": "비밀번호가 일치하지 않습니다."}

    return {
        "success": True,
        "message": "로그인 성공",
        "grade": users[user.id]["grade"],
        "userId": user.id
    }

@app.post("/check-id")
async def check_id(request: CheckIdRequest):
    try:
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
    except:
        users = {}

    if request.id in users:
        return {"available": False, "message": "이미 존재하는 아이디입니다."}
    return {"available": True, "message": "사용 가능한 아이디입니다."}

@app.patch("/update-grade")
async def update_grade(user_id: str = Body(...), new_grade: str = Body(...)):
    try:
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
    except:
        return {"success": False, "message": "사용자 데이터 파일을 읽을 수 없습니다."}

    if user_id not in users:
        return {"success": False, "message": "존재하지 않는 사용자입니다."}

    users[user_id]["grade"] = new_grade

    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(users, f, indent=4, ensure_ascii=False)

    return {"success": True, "message": "학년이 성공적으로 수정되었습니다.", "grade": new_grade}

@app.post("/generate-quiz")
async def generate_quiz(data: QuizGenerateRequest):
    try:
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
        grade = users[data.user_id]["grade"]
    except:
        return {"error": "사용자 정보를 찾을 수 없습니다."}

    is_ai_test_request = data.selected_range is not None

    if not is_ai_test_request:
        try:
            with open(SOLVE_LOG_FILE, 'r', encoding='utf-8') as f:
                logs = json.load(f)
        except:
            logs = {}

        today = str(date.today())
        if data.user_id in logs and today in logs[data.user_id]:
            return {"error": "오늘의 퀴즈를 이미 풀었습니다"}

        prompt = f"""
너는 대한민국 수학 선생님이야.
'{grade}' 학생을 위해 수학 문제를 적절한 난이도로 3개 만들어줘.

문제는 반드시 대한민국 교육과정에 맞춰야 해.

아래 JSON 형식만 정확히 지켜서 출력해:
[
  {{
    "id": 1,
    "question": "문제 설명",
    "answer": "정답 (단 하나의 숫자만, 단위 없이)",
    "explanation": "왜 그런 정답이 되는지 해설"
  }},
  ...
]
📌 주의사항:
- answer는 반드시 숫자 하나만. "또는", "x=", 쉼표 등 금지
- 문제는 정확히 3개만, id는 1, 2, 3
"""
    else:
        subject = data.subject or ""
        prompt = f"""
너는 대한민국 수학 선생님이야.
"{grade}" 학생을 위한 "{subject} - {data.selected_range}" 단원에서 출제 가능한 수학 문제 5개를 만들어줘.

정답은 반드시 숫자 하나여야 해. 수식(x+3)(x+2)이나 x=3 같은 형태는 절대 쓰지 말고, "정답": "3" 같은 형식으로만 줘.

아래 JSON 형식만 정확히 지켜서 출력해:
[
  {{
    "id": 1,
    "question": "문제 설명",
    "answer": "정답 (단 하나의 숫자만, 단위 없이)",
    "explanation": "문제 해설"
  }},
  ...
]
📌 조건:
- 문제는 정확히 5개 (id는 1~5)
- answer는 반드시 숫자 하나만. 예: "3", "2.5"
- 절대 answer에 수식 (예: x^2 + 2x), 문자, 단위, 'x=', '또는', '답:', '=' 등을 포함하지 말 것
- JSON 외의 텍스트는 절대 포함하지 말고, 딱 JSON만 출력해
- 질문은 여러 유형으로 만들어
- 동일한 유형의 문제가 반복되면 안돼
- 학년 수준에 맞게 난이도 조절 해줘
- 숫자 이외의 텍스트가 들어가면 무조건 잘못된 답안으로 처리
"""

    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "너는 대한민국 수학 선생님이다."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7
        )

        content = response.choices[0].message.content.strip()
        content = re.sub(r'```json', '', content)
        content = re.sub(r'```', '', content).strip()

        try:
            quiz_list = json.loads(content)
        except json.JSONDecodeError:
            return {"error": "GPT 응답 JSON 해석 실패", "raw": content}

        for q in quiz_list:
            if not all(k in q for k in ("id", "question", "answer", "explanation")):
                return {"error": "문제 필드 누락", "quiz": q}
            
            answer = str(q["answer"]).strip()
            
            try:
                float(answer)
            except ValueError:
                print("[❌ answer 오류]", q["answer"])
                return {"error": "answer는 숫자여여어야 함", "answer": q["answer"]}
                
            q["answer"] = answer
        
        return {
            "grade": grade,
            "subject": data.subject,
            "range": data.selected_range,
            "quizzes": quiz_list
        }

    except Exception as e:
        return {"error": f"GPT 생성 오류: {str(e)}"}

@app.post("/save-quiz-result")
async def save_quiz_result(result: QuizResult):
    try:
        with open(SOLVE_LOG_FILE, 'r', encoding='utf-8') as f:
            logs = json.load(f)
    except:
        logs = {}

    today = str(date.today())
    user_id = result.user_id

    if user_id not in logs:
        logs[user_id] = {}

    if today not in logs[user_id]:
        logs[user_id][today] = []

    logs[user_id][today].append({
        "question": result.question,
        "user_answer": result.user_answer,
        "correct_answer": result.correct_answer,
        "explanation": result.explanation
    })

    with open(SOLVE_LOG_FILE, 'w', encoding='utf-8') as f:
        json.dump(logs, f, indent=4, ensure_ascii=False)

    return {"message": "퀴즈 결과 저장 완료"}

@app.get("/quiz-history")
async def get_quiz_history(user_id: str = Query(...)):
    try:
        with open(SOLVE_LOG_FILE, 'r', encoding='utf-8') as f:
            logs = json.load(f)
    except FileNotFoundError:
        return {"error": "solve_log.json 파일이 없습니다."}
    except json.JSONDecodeError:
        return {"error": "solve_log.json을 읽는 중 오류가 발생했습니다."}

    if user_id not in logs:
        return {}

    return logs[user_id]

#AI추천문제
@app.get("/recommend/{user_id}")
async def recommend(user_id: str):
    path = os.path.join(os.path.dirname(__file__), "solve_log.json")
    try:
        result = recommend_problems_with_gpt(user_id, path)

        #  이미 리스트로 파싱된 경우 처리 (str이 아님)
        if isinstance(result, list):
            return {"recommended": result}
        else:
            parsed = json.loads(result)
            return {"recommended": parsed}

    except Exception as e:
        return {"recommended": [], "error": str(e)}
#AI추천문제푼거해설＋기록

SOLVE_LOG_FILE = os.path.join(os.path.dirname(__file__), "solve_log.json")

class AnswerRequest(BaseModel):
    user_id: str
    question: str
    user_answer: str
    correct_answer: str

@app.post("/check-answer-bulk")
async def check_answer_bulk(data: BulkAnswerRequest):
    results = []
    today = str(date.today())

    for item in data.answers:
        user = item["user_answer"].strip()
        correct = item.get("correct_answer","")
        
        if not isinstance(correct, str):
            correct = str(correct or "").strip()
        else:
            correct = correct.strip()
            
        is_correct = user == correct

        prompt = (
            f"문제: {item['question']}\n"
            f"사용자 답: {user}\n"
            f"정답: {correct}\n\n"
            f"문제 풀이를 3단계 ~ 5단계로 나눠서 설명해줘."
            f"답을 맞췄는지 여부나 사용자의 답은 언급하지 말고,"
            f"단계별로 문제를 푸는 과정을 자연스럽게 설명해줘."
            f"각 단계는 '1단계:', '2단계:' 형식으로 시작해."
        )

        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
        )

        explanation = response.choices[0].message.content.strip()

        results.append({
            "question": item["question"],
            "user_answer": user,
            "correct_answer": correct or "알 수 없음",
            "is_correct": is_correct,
            "explanation": explanation
        })

    return results

@app.post("/save-note")
async def save_note(user_id: str = Body(...), grade: str = Body(...),
                    subject: str = Body(None), range_name: str = Body(...),
                    quizzes: List[dict] = Body(...)):
    notes = load_json_file(AI_TEST_FILE)
    today = datetime.today().strftime("%Y-%m-%d")

    if user_id not in notes:
        notes[user_id] = []

    # 제목 포맷
    if subject:
        title = f"{grade}_{subject}_{range_name}"
    else:
        title = f"{grade}_{range_name}"

    notes[user_id].append({
        "title": title,
        "date": today,
        "quizzes": quizzes
    })

    save_json_file(AI_TEST_FILE, notes)
    return {"message": "노트 저장 완료", "title": title, "date": today}

@app.get("/get-note-list")
async def get_note_list(user_id: str):
    notes = load_json_file(AI_TEST_FILE)
    if user_id not in notes:
        return []

    return notes[user_id]

@app.get("/get-user-info")
async def get_user_info(user_id: str = Query(...)):
    try:
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
        with open(os.path.join(BASE_DIR, 'grade_to_ranges.json'), 'r', encoding='utf-8') as f:
            range_data = json.load(f)
    except:
        return {"error": "파일을 불러올 수 없습니다."}

    if user_id not in users:
        return {"error": "존재하지 않는 사용자입니다."}

    grade = users[user_id]["grade"]
    data = range_data.get(grade)

    if isinstance(data, list):  # 중학생
        return {
            "grade": grade,
            "available_ranges": data
        }

    elif isinstance(data, dict):  # 고등학생
        return {
            "grade": grade,
            "available_subjects": list(data.keys()),
            "available_ranges": data
        }

    return {"error": "해당 학년에 대한 시험범위 정보를 찾을 수 없습니다."}

@app.post("/calculate")
async def calculate_expression(expression: str = Form(...)):
    try:
        result = eval(expression)
        return {"result": result}
    except Exception as e:
        return JSONResponse(status_code=400, content={"error": str(e)})
    
@app.post("/plot")
async def plot_expression(expression: str = Form(...)):
    try:
        x = symbols('x')
        expr = sympify(expression)
        func = lambdify(x, expr, 'numpy')

        x_vals = np.linspace(-10, 10, 400)
        y_vals = func(x_vals)

        fig, ax = plt.subplots()
        ax.plot(x_vals, y_vals)
        ax.set_title(f"y = {expression}")
        ax.grid(True)

        buf = io.BytesIO()
        plt.savefig(buf, format='png')
        plt.close(fig)
        buf.seek(0)
        img_bytes = base64.b64encode(buf.read()).decode()

        return {"image": img_bytes}
    except Exception as e:
        return JSONResponse(status_code=400, content={"error": str(e)})
    
load_dotenv()

UPLOAD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "AI", "testcases", "problems"))
STATIC_DIR = UPLOAD_DIR
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
print("STATIC_DIR:", STATIC_DIR)

os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.post("/upload", response_class=PlainTextResponse)
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

@app.post("/save-json")
async def save_json_to_file(data: dict = Body(...)):
    json_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend", "ai_result.json"))
    try:
        print("✅ /save-json 라우터 호출됨")
        print("📦 수신 데이터 확인:", data)

        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return {"message": "JSON 저장 완료"}
    except Exception as e:
        print("❌ 예외 발생:", e)
        return JSONResponse(content={"error": str(e)}, status_code=500)


def recover_utf8_string(s: str) -> str:
    try:
        return s.encode('latin1').decode('utf-8')
    except Exception:
        return s

def recover_nested_strings(obj: Any) -> Any:
    if isinstance(obj, dict):
        return {k: recover_nested_strings(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [recover_nested_strings(elem) for elem in obj]
    elif isinstance(obj, str):
        return recover_utf8_string(obj)
    else:
        return obj

@app.get("/search-history")
async def get_search_history():
    json_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend", "ai_result.json"))

    if not os.path.exists(json_path):
        return JSONResponse(content={"error": "파일이 존재하지 않습니다."}, status_code=404)

    try:
        with open(json_path, "r", encoding="utf-8", errors="replace") as f:
            raw_data = f.read()

        try:
            data = json.loads(raw_data)
        except json.JSONDecodeError as e:
            # json 형식이 깨진 경우 대응
            return JSONResponse(content={"error": f"JSON 파싱 오류: {str(e)}"}, status_code=500)

        # ✅ 모든 문자열 복원
        fixed_data = recover_nested_strings(data)

        return JSONResponse(content=fixed_data, media_type="application/json; charset=utf-8")
    except Exception as e:
        return JSONResponse(content={"error": f"파일 읽기 오류: {str(e)}"}, status_code=500)

@app.post("/history-image")
async def history_image_upload(image: UploadFile = File(...)):
    try:
        file_path = os.path.join(UPLOAD_DIR, image.filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)

        image_url = f"http://10.0.2.2:8000/static/{image.filename}"
        return {"image_url": image_url}
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.get("/history-image-preview/{filename}")
async def preview_image(filename: str):
    file_path = os.path.join(UPLOAD_DIR, filename)

    if not os.path.exists(file_path):
        return JSONResponse(content={"error": "파일이 존재하지 않습니다."}, status_code=404)

    return FileResponse(file_path, media_type="image/jpeg")
