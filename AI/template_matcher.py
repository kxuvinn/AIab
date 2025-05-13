import json
import os

# ✅ 템플릿 JSON 파일 경로 (절대 경로 기준으로 수정)
template_path = os.path.abspath(os.path.join(os.path.dirname(__file__),  "templates", "templates.json"))

# 템플릿 로딩
with open(template_path, "r", encoding="utf-8") as f:
    templates = json.load(f)

def normalize_text(text):
    return text.replace(" ", "").lower()

def match_template(problem_text):
    """
    주어진 문제 텍스트에 대해 적절한 템플릿을 찾아 반환
    """
    normalized_text = normalize_text(problem_text)
    for template_name, template_data in templates.items():
        keywords = template_data.get("condition_keywords", [])
        for keyword in keywords:
            if normalize_text(keyword) in normalized_text:
                print(f"✅ 템플릿 매칭됨: {template_name}")
                template_data["name"] = template_name
                return template_data
    print("❌ 템플릿 매칭 실패")
    return None