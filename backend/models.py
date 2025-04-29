from pydantic import BaseModel

class SignupRequest(BaseModel):
    id: str
    password: str
    grade: str

class LoginRequest(BaseModel):
    id: str
    password: str
    
class CheckIdRequest(BaseModel):
    id: str
