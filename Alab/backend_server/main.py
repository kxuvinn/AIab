import os
import json
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

USER_DATA_FILE = 'users.json'
PROBLEM_DATA_FILE = 'problems.json'
CURRICULUM_DATA_FILE = 'curriculum.json'

# 파일 없으면 자동 생성
if not os.path.exists(USER_DATA_FILE):
    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump({}, f, indent=4, ensure_ascii=False)

with open(PROBLEM_DATA_FILE, 'r', encoding='utf-8') as f:
    problems_data = json.load(f)

with open(CURRICULUM_DATA_FILE, 'r', encoding='utf-8') as f:
    curriculum_data = json.load(f)

# 회원가입 요청 모델
class SignupRequest(BaseModel):
    nickname: str
    grade: str

# 로그인 요청 모델
class LoginRequest(BaseModel):
    nickname: str

@app.post("/signup")
async def signup(user: SignupRequest):
    with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
        users = json.load(f)

    if user.nickname in users:
        return {"success": False, "message": "닉네임 중복"}

    users[user.nickname] = {
        "grade": user.grade,
        "subject": None  # 단원은 나중에 선택
    }

    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(users, f, indent=4, ensure_ascii=False)

    return {"success": True}

@app.post("/login")
async def login(user: LoginRequest):
    with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
        users = json.load(f)

    if user.nickname not in users:
        return {"success": False, "message": "존재하지 않는 사용자"}

    return {"success": True}

@app.get("/curriculum/{grade}")
async def get_curriculum(grade: str):
    return curriculum_data.get(grade, [])
