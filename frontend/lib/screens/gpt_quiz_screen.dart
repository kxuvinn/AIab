import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';


class GptQuizScreen extends StatefulWidget {
  final String userGrade;
  final String userId;

  const GptQuizScreen({required this.userGrade, required this.userId, super.key});

  @override
  State<GptQuizScreen> createState() => _GptQuizScreenState();
}

class _GptQuizScreenState extends State<GptQuizScreen> {
  List<dynamic> quizzes = [];
  List<String> userAnswers = [];
  int currentIndex = 0;
  bool loading = true;
  final answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGeneratedQuiz();
  }

  Future<void> fetchGeneratedQuiz() async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/generate-quiz"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": widget.userId}),
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    print("🔁 GPT 응답 데이터: $data");

    if (response.statusCode != 200 || data["quizzes"] == null) {
      String title = "오류 발생";
      String errorMessage = "문제 생성 중 오류가 발생했습니다.\n잠시 후 다시 시도해 주세요.";

      if (data["error"] != null && data["error"].toString().contains("오늘의 퀴즈를 이미 풀었습니다")) {
        title = "오늘의 퀴즈 완료!";
        errorMessage = "오늘의 퀴즈를 이미 완료하셨어요.\n내일 다시 도전해 보세요!";
      }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold),
        ),
        content: Text(
          errorMessage,
          style: const TextStyle(fontFamily: 'NotoSans'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    userGrade: widget.userGrade,
                    userId: widget.userId,
                  ),
                ),
                (route) => false,
              );
            },
            child: const Text("확인", style: TextStyle(fontFamily: 'NotoSans')),
          ),
        ],
      ),
    );

    setState(() => loading = false);
    return;
  }

  setState(() {
    quizzes = data["quizzes"];
    userAnswers = List.filled(quizzes.length, "");
    loading = false;
  });
}


  void nextOrSubmit() {
    userAnswers[currentIndex] = answerController.text.trim();
    answerController.clear();

    if (currentIndex < quizzes.length - 1) {
      setState(() => currentIndex++);
      answerController.text = userAnswers[currentIndex];
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            quizzes: quizzes,
            userAnswers: userAnswers,
            userId: widget.userId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue[700];

    return WillPopScope(
      onWillPop: () async {
        if (currentIndex == 0) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            currentIndex--;
            answerController.text = userAnswers[currentIndex];
          });
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("오늘의 퀴즈", style: TextStyle(color: Colors.black, fontFamily: 'NotoSans')),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : quizzes.isEmpty
                ? const Center(child: Text("생성된 문제가 없습니다"))
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("문제 ${currentIndex + 1} / ${quizzes.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSans')),
                              const SizedBox(height: 16),
                              Text(quizzes[currentIndex]["question"], style: const TextStyle(fontSize: 16, fontFamily: 'NotoSans')),
                              const SizedBox(height: 24),
                              TextField(
                                controller: answerController,
                                decoration: const InputDecoration(labelText: '답을 입력하세요', border: OutlineInputBorder()),
                                style: const TextStyle(fontFamily: 'NotoSans'),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: nextOrSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: Text(currentIndex < quizzes.length - 1 ? "다음" : "제출", style: const TextStyle(fontSize: 16, fontFamily: 'NotoSans')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class QuizResultScreen extends StatefulWidget {
  final List<dynamic> quizzes;
  final List<String> userAnswers;
  final String userId;

  const QuizResultScreen({
    required this.quizzes,
    required this.userAnswers,
    required this.userId,
    super.key,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool saved = false;

  @override
  void initState() {
    super.initState();
    saveResults();
  }

  Future<void> saveResults() async {
    if (saved) return;

    for (int i = 0; i < widget.quizzes.length; i++) {
      final quiz = widget.quizzes[i];
      await saveQuizResult(
        userId: widget.userId,
        question: quiz["question"],
        userAnswer: widget.userAnswers[i],
        correctAnswer: quiz["answer"],
        explanation: quiz["explanation"],
      );
    }

    saved = true;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue[700];

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("퀴즈 결과", style: TextStyle(color: Colors.black, fontFamily: 'NotoSans')),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: ListView.builder(
          itemCount: widget.quizzes.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final quiz = widget.quizzes[index];
            final userAnswer = widget.userAnswers[index];
            final correctAnswer = quiz["answer"].toString().trim();
            final isCorrect = userAnswer.trim() == correctAnswer;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("문제 ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'NotoSans')),
                    const SizedBox(height: 8),
                    Text(quiz["question"], style: const TextStyle(fontSize: 16, fontFamily: 'NotoSans')),
                    const SizedBox(height: 12),
                    Text("내 답변: $userAnswer", style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontFamily: 'NotoSans')),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined, color: isCorrect ? Colors.green : Colors.red),
                        const SizedBox(width: 6),
                        Text(isCorrect ? "정답" : "오답", style: TextStyle(fontWeight: FontWeight.bold, color: isCorrect ? Colors.green : Colors.red, fontFamily: 'NotoSans')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("정답: $correctAnswer", style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSans')),
                    const SizedBox(height: 8),
                    Text("해설:", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontFamily: 'NotoSans')),
                    Text(quiz["explanation"] ?? "해설이 없습니다.", style: const TextStyle(fontFamily: 'NotoSans')),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> saveQuizResult({
  required String userId,
  required String question,
  required String userAnswer,
  required String correctAnswer,
  required String explanation,
}) async {
  final response = await http.post(
    Uri.parse('http://10.0.2.2:8000/save-quiz-result'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "user_id": userId,
      "question": question,
      "user_answer": userAnswer,
      "correct_answer": correctAnswer,
      "explanation": explanation,
    }),
  );

  if (response.statusCode == 200) {
    print("✅ 퀴즈 결과 저장 완료");
  } else {
    print("❌ 저장 실패: ${response.body}");
  }
}
