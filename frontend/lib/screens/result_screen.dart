import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ResultScreen extends StatelessWidget {
  final XFile image;
  final String result;

  const ResultScreen({super.key, required this.image, required this.result});

  static bool _hasSent = false;

  /// UTF-8 인코딩 복구 함수
  String recoverCorruptedUtf8(String input) {
    try {
      final bytes = latin1.encode(input);
      return utf8.decode(bytes);
    } catch (e) {
      return input;
    }
  }

  List<Widget> _buildStepTiles(String explanation) {
    final stepRegExp = RegExp(
      r'(?<=^|\n)(?:\d+\s*단계:|\d+\s*단계|\d+\s*번째\s*단계|\d+\s*\.\s*|\d+\))',
      multiLine: true,
    );

    final matches = stepRegExp.allMatches(explanation).toList();
    if (matches.isEmpty) {
      return [Text(explanation)];
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

  Map<String, dynamic> parseResultToJson(String result) {
    final resultParts = result.split(RegExp(r'\[\u{1F3AF}?\s*최종\s*정답\]', unicode: true));
    final hasExplanation = resultParts.length > 1;

    final explanationPart = hasExplanation ? resultParts[0] : result;
    final answerPart = hasExplanation ? resultParts[1].trim() : '';

    final explanationSplit = explanationPart.split(RegExp(r'5\s*단계\s*해설\]'));
    final mainExplanation = explanationSplit.length > 1 ? explanationSplit[1].trim() : explanationPart;

    final stepRegExp = RegExp(
      r'(?<=^|\n)(?:\d+\s*단계:|\d+\s*단계|\d+\s*번째\s*단계|\d+\s*\.\s*|\d+\))',
      multiLine: true,
    );

    final matches = stepRegExp.allMatches(mainExplanation).toList();

    if (matches.isEmpty) {
      return {
        "steps": [
          {"title": "해설", "content": mainExplanation}
        ],
        "answer": answerPart
      };
    }

    List<Map<String, String>> steps = [];
    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i + 1 < matches.length ? matches[i + 1].start : mainExplanation.length;
      final stepContent = mainExplanation.substring(start, end).trim();
      steps.add({
        "title": "${i + 1}단계",
        "content": stepContent,
      });
    }

    return {
      "steps": steps,
      "answer": answerPart,
    };
  }

  Future<String?> uploadImageToServer(XFile image) async {
    final uri = Uri.parse('http://10.0.2.2:8000/history-image');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['image_url'];
      } else {
        debugPrint('❌ 이미지 업로드 실패: ${response.body}');
      }
    } catch (e) {
      debugPrint('❗ 이미지 업로드 예외 발생: $e');
    }

    return null;
  }

  Future<void> sendJsonToServer(String result, BuildContext context) async {
    if (_hasSent) return;
    _hasSent = true;

    final parsedJson = parseResultToJson(result);
    final today = DateTime.now().toIso8601String().split('T').first;

    final imageUrl = await uploadImageToServer(image);

    try {
      // 1. 기존 데이터 가져오기
      final getResponse = await http.get(Uri.parse('http://10.0.2.2:8000/search-history'));
      Map<String, dynamic> existingData = {};
      if (getResponse.statusCode == 200) {
        final recoveredBody = recoverCorruptedUtf8(getResponse.body);
        existingData = jsonDecode(recoveredBody);
      }

      // 2. 오늘 데이터 병합
      final todayData = existingData[today] != null && existingData[today] is List
          ? List.from(existingData[today])
          : [];
      final newEntry = {
        ...parsedJson,
        if (imageUrl != null) "image_url": imageUrl,
      };
      todayData.add(newEntry);
      existingData[today] = todayData;

      // 3. 서버에 다시 저장
      final postResponse = await http.post(
        Uri.parse('http://10.0.2.2:8000/save-json'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: utf8.encode(jsonEncode(existingData)),
      );

      if (postResponse.statusCode == 200) {
        debugPrint('✅ JSON 저장 성공');
      } else {
        debugPrint('❌ 서버 응답 오류: ${postResponse.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ JSON 저장 실패')),
        );
      }
    } catch (e) {
      debugPrint('❗ JSON 저장 예외 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 서버 연결 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultParts = result.split(RegExp(r'\[\u{1F3AF}?\s*최종\s*정답\]', unicode: true));

    final hasExplanation = resultParts.length > 1;

    final explanationPart = hasExplanation ? resultParts[0] : result;
    final answerPart = hasExplanation ? resultParts[1].trim() : '';

    final explanationSplit = explanationPart.split(RegExp(r'5\s*단계\s*해설\]'));
    final mainExplanation = explanationSplit.length > 1 ? explanationSplit[1].trim() : explanationPart;

    // ✅ 서버 전송
    sendJsonToServer(result, context);

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
