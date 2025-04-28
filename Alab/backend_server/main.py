from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json
import os

app = FastAPI()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 파일 경로
USER_DATA_FILE = 'users.json'
PROBLEM_DATA_FILE = 'problems.json'
CURRICULUM_DATA_FILE = 'curriculum.json'

# users.json 없으면 생성
if not os.path.exists(USER_DATA_FILE):
    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump({}, f, indent=4, ensure_ascii=False)

# 문제 데이터 로딩
with open(PROBLEM_DATA_FILE, 'r', encoding='utf-8') as f:
    problems_data = json.load(f)

# curriculum 데이터 로딩
with open(CURRICULUM_DATA_FILE, 'r', encoding='utf-8') as f:
    curriculum_data = json.load(f)

# 회원가입 요청 모델
class SignupRequest(BaseModel):
    nickname: str
    grade: str
    subject: str

# 로그인 요청 모델
class LoginRequest(BaseModel):
    nickname: str

# 회원가입 API
@app.post("/signup")
def signup(request: SignupRequest):
    nickname = request.nickname.strip()
    grade = request.grade.strip()
    subject = request.subject.strip()

    with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
        users = json.load(f)

    if nickname in users:
        return {"success": False, "message": "이미 존재하는 닉네임입니다."}

    users[nickname] = {
        "grade": grade,
        "subject": subject
    }

    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(users, f, indent=4, ensure_ascii=False)

    return {"success": True, "message": f"{nickname}님 회원가입 완료"}

# 로그인 API
@app.post("/login")
def login(request: LoginRequest):
    nickname = request.nickname.strip()

    with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
        users = json.load(f)

    if nickname in users:
        user_info = users[nickname]
        return {
            "success": True,
            "message": f"{nickname}님 로그인 성공",
            "nickname": nickname,
            "grade": user_info["grade"],
            "subject": user_info["subject"]
        }
    else:
        return {"success": False, "message": "존재하지 않는 닉네임입니다."}

# 문제 추천 API
@app.get("/recommend")
def recommend(grade: str, subject: str):
    key = f"{grade}_{subject}"

    if key in problems_data:
        selected = problems_data[key]
        return {"success": True, "problems": selected}
    else:
        return {"success": False, "message": "해당 학년/단원의 문제가 없습니다."}
