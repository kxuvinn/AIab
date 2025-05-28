import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ResultScreen extends StatelessWidget {
  final XFile image;
  final String result;

  const ResultScreen({super.key, required this.image, required this.result});

  List<Widget> _buildStepTiles(String explanation) {
    final stepRegExp = RegExp(
      r'(?<=^|\n)(?:\d+\s*단계:|\d+\s*단계:|\d+\s*단계|\d+\s*\.\s*|\d+\))',
      multiLine: true,
    );

    final matches = stepRegExp.allMatches(explanation).toList();
    if (matches.isEmpty) {
      return [Text(explanation)]; // fallback
    }

    List<Widget> tiles = [];
    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i + 1 < matches.length ? matches[i + 1].start : explanation.length;
      final stepText = explanation.substring(start, end).trim();

      tiles.add(
        ExpansionTile(
          title: Text("${i + 1}단계"),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(stepText),
            ),
          ],
        ),
      );
    }

    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    // 분할
    final resultParts = result.split(RegExp(r'[🎯최종\s*정답\]'));
    final hasExplanation = resultParts.length > 1;

    final explanationPart = hasExplanation ? resultParts[0] : result;
    final answerPart = hasExplanation ? resultParts[1].trim() : '';

    final explanationSplit = explanationPart.split(RegExp(r'5\s*단계\s*해설\]'));
    final mainExplanation = explanationSplit.length > 1 ? explanationSplit[1].trim() : explanationPart;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 해설", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.file(File(image.path), height: 250),
                const SizedBox(height: 24),
                const Text("해설", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ..._buildStepTiles(mainExplanation),
                      if (answerPart.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text("최종 정답", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(answerPart),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text("홈으로 돌아가기"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
