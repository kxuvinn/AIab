import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchHistoryScreen extends StatefulWidget {
  final String userId;

  const SearchHistoryScreen({required this.userId, super.key});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  Map<String, List<dynamic>> quizData = {};
  Set<String> expandedDates = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchQuizHistory();
  }

  String recoverCorruptedUtf8(String input) {
    try {
      return utf8.decode(latin1.encode(input));
    } catch (_) {
      return input; // fallback
    }
  }

  Future<void> fetchQuizHistory() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/search-history?user_id=${widget.userId}'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final fixedData = decoded.map((date, list) {
        return MapEntry(
          date,
          List.from(list).map((item) {
            final steps = (item['steps'] as List?)?.map((step) {
              return {
                "title": recoverCorruptedUtf8(step["title"] ?? ""),
                "content": recoverCorruptedUtf8(step["content"] ?? ""),
              };
            }).toList();

            return {
              ...item,
              "answer": recoverCorruptedUtf8(item["answer"] ?? ""),
              "steps": steps,
            };
          }).toList(),
        );
      });

      setState(() {
        quizData = fixedData;
        loading = false;
      });
    } else {
      print("❌ 기록 불러오기 실패: ${response.body}");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue[700];

    return Scaffold(
      appBar: AppBar(
        title: const Text("질문 기록", style: TextStyle(fontFamily: 'NotoSans', color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : quizData.isEmpty
              ? const Center(child: Text("기록이 없습니다.", style: TextStyle(fontFamily: 'NotoSans')))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: quizData.entries.map((entry) {
                    final date = entry.key;
                    final items = entry.value;
                    final isExpanded = expandedDates.contains(date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                expandedDates.remove(date);
                              } else {
                                expandedDates.add(date);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  date,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'NotoSans'),
                                ),
                                Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded)
                          ...items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;

                            final steps = (item["steps"] as List?) ?? [];
                            final answer = item["answer"]?.toString().trim() ?? "";
                            final imageUrl = item["image_url"]?.toString().trim();

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("풀이 ${index + 1}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            fontFamily: 'NotoSans')),

                                    const SizedBox(height: 12),

                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              'http://10.0.2.2:8000/history-image-preview/${Uri.parse(imageUrl).pathSegments.last}',
                                              height: 200,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Text("이미지를 불러올 수 없습니다."),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),

                                    if (steps.isNotEmpty)
                                      ...steps.asMap().entries.map((stepEntry) {
                                        final step = stepEntry.value;
                                        return ExpansionTile(
                                          title: Text(
                                            step["title"] ?? "단계",
                                            style: const TextStyle(fontFamily: 'NotoSans'),
                                          ),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                              child: Text(
                                                step["content"] ?? "",
                                                style: const TextStyle(fontFamily: 'NotoSans'),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),

                                    const SizedBox(height: 16),

                                    Text("최종 정답",
                                        style: TextStyle(
                                            color: themeColor,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'NotoSans')),
                                    const SizedBox(height: 4),
                                    Text(answer,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'NotoSans')),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
