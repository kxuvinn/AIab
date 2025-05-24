import os
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

from AI.ai_processor import process_image

PROBLEM_DIR = os.path.join(os.path.dirname(__file__), "problems")


def run_all_tests():
    problems = [f for f in os.listdir(PROBLEM_DIR) if f.lower().endswith((".jpg", ".png"))]
    if not problems:
        print("❗ 테스트할 이미지가 없습니다. 'testcases/problems/' 폴더를 확인하세요.")
        return
    
    grade ="고3" #임의로 고3설정해둠!

    for fname in problems:
        print("=" * 80)
        print(f"📸 테스트 문제: {fname}")
        image_path = os.path.join(PROBLEM_DIR, fname)
        result = process_image(image_path, grade)
        print(result)
        print("=" * 80)


if __name__ == "__main__":
    run_all_tests()
