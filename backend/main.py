from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from models import SignupRequest, LoginRequest, CheckIdRequest
import os
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
USER_DATA_FILE = os.path.join(BASE_DIR, 'users.json')

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 파일 없으면 생성
if not os.path.exists(USER_DATA_FILE):
    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump({}, f, indent=4, ensure_ascii=False)

@app.post("/signup")
async def signup(user: SignupRequest):
    try:
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        users = {}

    if user.id in users:
        return {"success": False, "message": "이미 존재하는 아이디입니다."}

    users[user.id] = {
        "password": user.password,
        "grade": user.grade
    }

    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(users, f, indent=4, ensure_ascii=False)

    return {"success": True, "message": "회원가입 성공"}

@app.post("/login")
async def login(user: LoginRequest):
    try:
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        users = {}

    if user.id not in users:
        return {"success": False, "message": "존재하지 않는 아이디입니다."}

    if users[user.id]["password"] != user.password:
        return {"success": False, "message": "비밀번호가 일치하지 않습니다."}

    return {"success": True, "message": "로그인 성공", "grade": users[user.id]["grade"]}

@app.post("/check-id")
async def check_id(request: CheckIdRequest):
    try:
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            users = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        users = {}

    if request.id in users:
        return {"available": False, "message": "이미 존재하는 아이디입니다."}
    return {"available": True, "message": "사용 가능한 아이디입니다."}
