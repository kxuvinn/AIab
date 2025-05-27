import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ai_test_generator_screen.dart';
import '../widgets/custom_navbar.dart';
import '../screens/quiz_review_screen.dart';

class NoteScreen extends StatefulWidget {
  final String userId;
  final String userGrade;

  const NoteScreen({super.key, required this.userId, required this.userGrade});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final res = await http.get(Uri.parse("http://10.0.2.2:8000/get-note-list?user_id=${widget.userId}"));

    if (res.statusCode == 200) {
      final List data = json.decode(utf8.decode(res.bodyBytes));
      return data.cast<Map<String, dynamic>>().reversed.toList();
    } else {
      return [];
    }
  }

  Widget _buildNewNoteTile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
          builder: (_) => AiTestGeneratorScreen(userId: widget.userId),
        ),
      );
      },
      child: Container(
        width: double.infinity,
        height: 160,
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.blue, size: 36),
              SizedBox(height: 8),
              Text("신규", style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "노트",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSans'),
        ),
  backgroundColor: Colors.transparent,
  elevation: 0,
  foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchNotes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

            final notes = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: notes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildNewNoteTile(context);

                final note = notes[index - 1];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => QuizReviewScreen(note: note),
                    ));
                  },
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note["title"], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Text(note["date"], style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: CustomNavBar(
        currentIndex: 2,
        userId: widget.userId,
        userGrade: widget.userGrade,
        ),
      ),
    );
  }
}
