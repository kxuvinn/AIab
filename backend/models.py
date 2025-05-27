from pydantic import BaseModel
from typing import Optional, List

class SignupRequest(BaseModel):
    id: str
    password: str
    grade: str

class LoginRequest(BaseModel):
    id: str
    password: str

class CheckIdRequest(BaseModel):
    id: str

class QuizSolveRequest(BaseModel):
    user_id: str
    quiz_id: int
    answer: str

class ExplanationRequest(BaseModel):
    question: str

class QuizRecord(BaseModel):
    question: str
    answer: str
    explanation: str
    userAnswer: str
    isCorrect: bool
    
class QuizResult(BaseModel):
    user_id: str
    question: str
    user_answer: str
    correct_answer: str
    explanation: str
    
class QuizGenerateRequest(BaseModel):
    user_id: str
    subject: Optional[str] = None
    selected_range: Optional[str] = None
    
class AnswerItem(BaseModel):
    question: str
    user_answer: str
    correct_answer: str
    
class BulkAnswerRequest(BaseModel):
    user_id: str
    answers: List[dict]