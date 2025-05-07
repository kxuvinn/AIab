import base64
import requests
import os
import re
import numpy as np
import matplotlib.pyplot as plt
from openai import OpenAI
from AI.template_matcher import match_template  # 템플릿 매칭 함수 불러오기

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY") or "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"
MATHPIX_APP_ID = os.getenv("MATHPIX_APP_ID") or "alab_team_7172e0_86e9ca"
MATHPIX_APP_KEY = os.getenv("MATHPIX_APP_KEY") or "54a3d42f8bd629cbbb564c94d4b87e9f9b8568dae0fe11fabe927729033cbf33"

client = OpenAI(api_key=OPENAI_API_KEY)

def process_image(image_path: str) -> str:
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

    # 템플릿 매칭 시도
    matched_template = match_template(text_raw)

    if matched_template:
        print(f"✅ 템플릿 매칭됨: {matched_template.get('name', '이름 없음')}")
        steps = matched_template.get("solution_steps", [])
        step_text = "\n".join([f"{i+1}. {s}" for i, s in enumerate(steps)])
        explain_prompt = f"""
다음 수학 문제를 반드시 아래의 5단계 풀이 흐름을 그대로 따르며, 각 단계 번호와 설명 문장은 절대 수정하지 말고 사용해.
각 단계 아래에 필요한 계산과 해설만 추가해. 구조나 문장 수정 없이 고정된 틀을 지켜야 해.

풀이 순서:
{step_text}

문제:
{text_raw}

마지막 줄에는 '정답: (숫자)' 형태로 써줘.
"""
    else:
        print("⚠️ 템플릿 매칭 안됨. 기본 프롬프트 사용.")
        explain_prompt = f"""
다음 수학 문제를 논리적으로 5단계로 나눠 자세히 풀어줘. Latex 말고 일반 수식과 설명을 섞어서, 고등학생이 이해할 수 있도록 써줘.
마지막 줄에 '정답: (숫자)' 형태로 써줘.
문제:
{text_raw}
"""

    print("🧠 최종 프롬프트:")
    print(explain_prompt)

    solve_response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": explain_prompt}]
    )
    explanation = solve_response.choices[0].message.content.strip()

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

    result_output = (
        f"📄 OCR 인식된 문제:\n{text_raw}\n\n"
        f"🧠 문제 풀이:\n{explanation}"
    )
    return result_output
