import base64
import requests
import os
import re
import json
import numpy as np
import matplotlib.pyplot as plt
from openai import OpenAI
from AI.template_matcher import match_template  # 템플릿 매칭 함수 불러오기
from dotenv import load_dotenv

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY") or "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"
MATHPIX_APP_ID = os.getenv("MATHPIX_APP_ID") or "alab_team_7172e0_86e9ca"
MATHPIX_APP_KEY = os.getenv("MATHPIX_APP_KEY") or "54a3d42f8bd629cbbb564c94d4b87e9f9b8568dae0fe11fabe927729033cbf33"

client = OpenAI(api_key=OPENAI_API_KEY)

def process_image(image_path: str, grade: str) -> str:
    with open(image_path, "rb") as image_file:
        img_base64 = base64.b64encode(image_file.read()).decode()

    ocr_response = requests.post("https://api.mathpix.com/v3/text", json={
        "src": f"data:image/jpeg;base64,{img_base64}",
        "formats": ["text"],
        "ocr": ["math", "text"],
        "math_inline_delimiters": ["$", "$"],
        "skip_recrop": True
    }, headers={
        "app_id": MATHPIX_APP_ID,
        "app_key": MATHPIX_APP_KEY,
        "Content-type": "application/json"
    })

    text_raw = ocr_response.json().get("text", "").replace("$", "").strip()
    if not text_raw:
        return "❗ OCR 실패: 수식을 읽을 수 없습니다."

    matched_template = match_template(text_raw, grade)
    matched_name = matched_template.get("name", "❌ 매칭 실패") if matched_template else "❌ 매칭 실패"

    if matched_template:
        steps = matched_template.get("solution_steps", [])
        step_text = "\n".join([f"{i+1}. {s}" for i, s in enumerate(steps)])
        explain_prompt = f"""
문제를 아래 풀이 구조에 따라 자세히 해결하되, 사용자는 오직 해설만 보고 이해해야 하므로 다음 사항을 반드시 지켜라:

- 아래의 풀이 순서를 따르되, 답변에 절대 보여주지 마라.
- 각 단계의 제목은 그대로 따르되, 출력에는 1. 2. 이런식의 5단계의의 설명과 계산만 보여줘라.
- 출력에는 문제 문장, 지시문, 구조 등의 메타정보를 절대 포함하지 마라.
- 계산은 정확하게 하고, 답이 보기 중 하나가 아니면 반드시 검토하라.
풀이 순서:
{step_text}

문제:
{text_raw}

마지막 줄에는 '정답: (숫자)' 형태로 써줘.
"""
    else:
        explain_prompt = f"""
다음 수학 문제를 논리적으로 5단계로 나눠 자세히 풀어줘. Latex 말고 일반 수식과 설명을 섞어서, 고등학생이 이해할 수 있도록 써줘.
마지막 줄에 '정답: (숫자)' 형태로 써줘.
문제:
{text_raw}
"""

    solve_response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": explain_prompt}]
    )
    explanation = solve_response.choices[0].message.content.strip()

    # 정답 추출
    lines = explanation.splitlines()
    last_line = lines[-1]
    answer_match = re.search(r'정답:\s*\(?(\d+)', last_line)
    final_answer = answer_match.group(1) if answer_match else "?"

    # 그래프 코드 생성 (에러 발생 시 무시)
    graph_prompt = f"""
다음 수학 함수(또는 구간별 함수)의 그래프를 matplotlib 코드로 그려줘.
조건:
- np.linspace 사용
- 조건부 함수면 구간을 나눠 각각 plot
- x축과 y축 라벨 추가
- plt.savefig('graph_output.png') 으로 저장
- plt.show() 하지 말고 저장만
- 코드 외 텍스트 없이 순수 Python 코드만 줘
수식:
{text_raw}
"""
    graph_response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": graph_prompt}]
    )
    code_block = re.findall(r"```python(.*?)```", graph_response.choices[0].message.content, re.DOTALL)
    if code_block:
        try:
            exec(code_block[0], {"np": np, "plt": plt})
        except Exception as e:
            explanation += f"\n\n[⚠️ 그래프 코드 실행 실패: {e}]"

    # 해설 본문 (마지막 정답 줄 제외)
    body = "\n".join(lines[:-1]) if len(lines) > 1 else explanation

    # ✅ 최종 출력 포맷
    return (
        f"[🧠 OCR 결과]\n{text_raw}\n\n"
        f"[🧩 템플릿 매칭]\n{matched_name}\n\n"
        f"[🧾 5단계 해설]\n{body.strip()}\n\n"
        f"[🎯 최종 정답]\n{final_answer}"
    )


#추천문제생성 (GPT기반)
def recommend_problems_with_gpt(user_id: str, solve_log_path: str) -> list:
    with open(solve_log_path, "r", encoding="utf-8") as f:
        log = json.load(f)

    user_log = log.get(user_id)
    if not user_log:
        return "[]"

    entries = []
    for date, problems in user_log.items():
        for p in problems:
            q = p.get("question", "")[:80].replace("\n", " ")
            ua = p.get("user_answer", "")
            ca = p.get("correct_answer", "")
            status = "맞음" if ua == ca else "틀림"
            entries.append(f"- Q: {q} / 사용자의 답: {ua} / 정답: {ca} → {status}")

    prompt = (
    "다음은 사용자의 수학 문제 풀이 기록입니다. 많이 틀린 단원을 바탕으로 "
    "**단원명(unit), 난이도(difficulty), 문제(question)** 정보를 포함한 "
    "**JSON 리스트 형식**으로 출력하세요. 설명 없이 JSON만 출력하세요.\n\n"
    + "\n".join(entries[-20:])
)
    print("📦 GPT PROMPT:\n", prompt) 

    response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7,
    )
    print("📦 GPT RESPONSE:\n", response.choices[0].message.content) 
    try:
        return json.loads(response.choices[0].message.content)
    except json.JSONDecodeError:
        return []
