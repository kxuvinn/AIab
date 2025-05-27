import 'package:flutter/material.dart';

class QuizReviewScreen extends StatefulWidget {
  final Map<String, dynamic> note;

  const QuizReviewScreen({super.key, required this.note});

  @override
  State<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends State<QuizReviewScreen> {
  late List<bool> showExplanation;

  @override
  void initState() {
    super.initState();
    showExplanation = List.filled(widget.note["quizzes"].length, false);
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = widget.note["quizzes"];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note["title"], style: TextStyle(fontFamily: 'NotoSans')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizzes[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("문제 ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text(quiz["question"], style: TextStyle(fontSize: 15)),
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => showExplanation[index] = !showExplanation[index]),
                      child: Text(showExplanation[index] ? "해설 닫기" : "해설 보기"),
                    ),
                  ),
                  if (showExplanation[index])
                    Text(quiz["explanation"] ?? "해설 없음", style: TextStyle(height: 1.4)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
