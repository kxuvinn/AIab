import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendScreen extends StatefulWidget {
  final String nickname;
  final String grade;
  final String subject;

  RecommendScreen({required this.nickname, required this.grade, required this.subject});

  @override
  _RecommendScreenState createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  List<dynamic> problems = [];

  Future<void> _loadProblems() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/recommend?grade=${widget.grade}&subject=${widget.subject}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          problems = data['problems'];
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProblems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('추천 문제')),
      body: ListView.builder(
        itemCount: problems.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(problems[index]['text']),
          );
        },
      ),
    );
  }
}
