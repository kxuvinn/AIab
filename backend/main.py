import os
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi import FastAPI, Body, Query
from fastapi.middleware.cors import CORSMiddleware
from models import (
    SignupRequest,
    LoginRequest,
    CheckIdRequest,
    QuizSolveRequest,
    ExplanationRequest,
    QuizGenerateRequest,
    QuizResult
)
from datetime import date
import json
from dotenv import load_dotenv
from openai import OpenAI
from typing import List
import re

from app_server import router as upload_router
from AI.ai_processor import process_image
from AI.ai_processor import recommend_problems_with_gpt

load_dotenv()
client = OpenAI()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
USER_DATA_FILE = os.path.join(BASE_DIR, 'users.json')
SOLVE_LOG_FILE = os.path.join(BASE_DIR, 'solve_log.json')

app = FastAPI()

app.include_router(upload_router)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if not os.path.exists(USER_DATA_FILE):
    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump({}, f, indent=4, ensure_ascii=False)

if not os.path.exists(SOLVE_LOG_FILE):
    with open(SOLVE_LOG_FILE, 'w', encoding='utf-8') as f:
        json.dump({}, f, indent=4, ensure_ascii=False)

# ✅ 회원가입
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

# ✅ 로그인
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

# ✅ ID 중복 확인
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

# ✅ GPT 문제 생성
@app.post("/generate-quiz")
async def generate_quiz(data: QuizGenerateRequest):
    try:
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
        grade = users[data.user_id]["grade"]
    except:
        return {"error": "사용자 정보를 찾을 수 없습니다."}

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
'{grade}' 수준의 수학 문제를 3개 만들어줘.

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
- 예: "1", "12.75", "1.5" 또는 "12.5" 처럼 숫자만
- 단위 (cm, %, m² 등)는 answer에 넣지 말고, 해설에는 포함해도 됨
- JSON 외 다른 텍스트 절대 금지 (예: 설명 문장, 안내 문구, 라벨, 들여쓰기 안내 등)
- 문제는 정확히 3개만, 각 문제의 id는 1, 2, 3으로
- 세 문제 모두 정답은 정확히 하나만 있어야 해
"""

    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "당신은 대한민국 수학 선생님입니다."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7
        )

        content = response.choices[0].message.content.strip()
        print("🟢 GPT로부터 받은 raw 응답:", content)
        
        content = re.sub(r'```json', '', content)
        content = re.sub(r'```', '', content).strip()

        try:
            quiz_list = json.loads(content)
        except json.JSONDecodeError:
            return {"error": "GPT 응답을 JSON으로 해석할 수 없습니다", "raw": content}

        for q in quiz_list:
            if not all(k in q for k in ("id", "question", "answer", "explanation")):
                return {"error": "문제 하나 이상에 필드가 빠져 있습니다", "quiz": q}
            if not isinstance(q["answer"], str) or not q["answer"].replace('.', '', 1).isdigit():
                return {"error": "answer는 하나의 숫자여야 합니다", "answer": q["answer"]}

        return {
            "grade": grade,
            "quizzes": quiz_list
        }

    except Exception as e:
        print("❌ GPT 생성 오류:", e)
        return {"error": str(e)}

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

@app.post("/check-answer")
async def check_answer(data: AnswerRequest):
    user = data.user_answer.strip()
    correct = data.correct_answer.strip()
    today = str(date.today())

    is_correct = user == correct

    explanation = ""
    if not is_correct:
        prompt = (
            f"문제: {data.question}\n"
            f"사용자 답: {user}\n"
            f"정답: {correct}\n\n"
            f"문제 풀이를 5단계로 나눠서 차근차근 설명해줘. 각 단계는 '1단계:', '2단계:' 형식으로 시작하게 해."
        )
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
        )
        explanation = response.choices[0].message.content.strip()

    # 기록 저장
    try:
        with open(SOLVE_LOG_FILE, "r", encoding="utf-8") as f:
            logs = json.load(f)
    except:
        logs = {}

    if data.user_id not in logs:
        logs[data.user_id] = {}
    if today not in logs[data.user_id]:
        logs[data.user_id][today] = []

    logs[data.user_id][today].append({
        "question": data.question,
        "user_answer": data.user_answer,
        "correct_answer": data.correct_answer,
        "is_correct": is_correct,
        "explanation": explanation
    })

    with open(SOLVE_LOG_FILE, "w", encoding="utf-8") as f:
        json.dump(logs, f, indent=2, ensure_ascii=False)

    return {
        "result": "정답입니다!" if is_correct else "틀렸습니다.",
        "is_correct": is_correct,
        "explanation": explanation
    }
