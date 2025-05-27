import 'package:flutter/material.dart';

class QuizResultScreen extends StatefulWidget {
  final List<dynamic> quizzes;
  final List<String> userAnswers;
  final String userId;
  final bool isFromNote;

  const QuizResultScreen({
    required this.quizzes,
    required this.userAnswers,
    required this.userId,
    this.isFromNote = false,
    super.key,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late List<bool> showExplanationList;

  @override
  void initState() {
    super.initState();
    showExplanationList = List.filled(widget.quizzes.length, false);
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
            final correctAnswer = quiz["correct_answer"]?.toString().trim() ?? "정답 없음";
            final isCorrect = quiz["is_correct"].toString().toLowerCase() == "true";


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
                    Text("내 답: $userAnswer", style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontFamily: 'NotoSans')),
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
                    const SizedBox(height: 12),

                    // 해설 표시 조건 분기
                    if (!widget.isFromNote || showExplanationList[index])
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("해설:", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontFamily: 'NotoSans')),
                          SelectableText(quiz["explanation"] ?? "해설 없음", style: TextStyle(fontFamily: 'NotoSans')),
                        ],
                      ),

                    // 토글 버튼 (저장된 노트에서만 보여짐)
                    if (widget.isFromNote)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showExplanationList[index] = !showExplanationList[index];
                          });
                        },
                        child: Text(
                          showExplanationList[index] ? "해설 닫기" : "해설 (단계별)",
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      )
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
