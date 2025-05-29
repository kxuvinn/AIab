import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'result_screen.dart';

class AnswerLoadingScreen extends StatefulWidget {
  final XFile image;
  final String userGrade;

  const AnswerLoadingScreen({super.key, required this.image, required this.userGrade});

  @override
  State<AnswerLoadingScreen> createState() => _AnswerLoadingScreenState();
}

class _AnswerLoadingScreenState extends State<AnswerLoadingScreen> {
  @override
  void initState() {
    super.initState();
    sendImageAndGetResult();
  }

  Future<void> sendImageAndGetResult() async {
    var uri = Uri.parse('http://10.0.2.2:8000/upload');
    var request = http.MultipartRequest('POST', uri);

    // 사진 파일 첨부
    request.files.add(await http.MultipartFile.fromPath('file', widget.image.path));
    // grade 필드 추가
    request.fields['grade'] = widget.userGrade;

    try {
      var response = await request.send();

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // 백엔드에서 plain text로 결과 반환
        final resultText = responseBody;

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(image: widget.image, result: resultText),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              image: widget.image,
              result: '⚠️ AI 처리 실패: 서버 응답 코드 ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            image: widget.image,
            result: '❌ 네트워크 오류 발생: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("AI 분석 중", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.file(File(widget.image.path), height: 250),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text("AI가 문제를 분석 중입니다...", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}