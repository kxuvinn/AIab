import json
import os

# 템플릿 폴더 경로
TEMPLATE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "templates"))

def normalize_text(text):
    return text.replace(" ", "").lower()

def load_templates_by_grade(grade: str) -> list:
    templates = []
    if grade.startswith("고1"):
        filenames = ["math_templates.json"]
    elif grade.startswith("고2"):
        filenames = ["math1_templates.json", "math2_templates.json"]
    elif grade.startswith("고3"):
        filenames = ["math1_templates.json", "math2_templates.json", "calculus_templates.json", "geometry_templates.json"]
    else:
        return []

    for filename in filenames:
        path = os.path.join(TEMPLATE_DIR, filename)
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                templates.append(json.load(f))
    return templates

def match_template(problem_text: str, grade: str):
    """
    주어진 문제 텍스트와 학년에 따라 적절한 템플릿을 찾아 반환
    """
    normalized_text = normalize_text(problem_text)
    loaded_templates = load_templates_by_grade(grade)

    for template_set in loaded_templates:
        for template_name, template_data in template_set.items():
            keywords = template_data.get("condition_keywords", [])
            for keyword in keywords:
                if normalize_text(keyword) in normalized_text:
                    
                    template_data["name"] = template_name
                    return template_data
    print("❌ 템플릿 매칭 실패")
    return None
