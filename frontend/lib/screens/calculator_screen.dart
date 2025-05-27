import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../widgets/custom_navbar.dart';

class CalculatorScreen extends StatelessWidget {
  final String userGrade;
  final String userId;

  const CalculatorScreen({
    required this.userGrade,
    required this.userId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '계산기',
          style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: const Expanded(child: SimpleAndGraphCalculator()),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: CustomNavBar(
          currentIndex: 1,
          userGrade: userGrade,
          userId: userId,
        ),
      ),
    );
  }
}

class SimpleAndGraphCalculator extends StatefulWidget {
  const SimpleAndGraphCalculator({super.key});

  @override
  State<SimpleAndGraphCalculator> createState() => _SimpleAndGraphCalculatorState();
}

class _SimpleAndGraphCalculatorState extends State<SimpleAndGraphCalculator>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final simpleController = TextEditingController();
  final graphController = TextEditingController();

  String simpleResult = '';
  Uint8List? graphImage;

  final baseUrl = "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> calculateSimple() async {
    final res = await http.post(
      Uri.parse('$baseUrl/calculate'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"expression": simpleController.text},
    );
    final data = jsonDecode(res.body);
    setState(() {
      simpleResult = data['result']?.toString() ?? data['error'] ?? '오류 발생';
    });
  }

  Future<void> drawGraph() async {
    final res = await http.post(
      Uri.parse('$baseUrl/plot'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"expression": graphController.text},
    );
    final data = jsonDecode(res.body);
    setState(() {
      if (data['image'] != null) {
        graphImage = base64Decode(data['image']);
      } else {
        graphImage = null;
        simpleResult = data['error'] ?? '그래프 오류';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '수식 계산기'),
              Tab(text: '그래프 계산기')
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            indicatorColor: Colors.blue,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: simpleController,
                      style: TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: "수식 입력",
                        hintText: "예: 2+3*4",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: calculateSimple,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("계산", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("결과:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(simpleResult, style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: graphController,
                      style: TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: "수식 입력",
                        hintText: "예: x^2 - 3*x + 2",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: drawGraph,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("그래프 보기", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    graphImage != null
                        ? Center(
                            child: Image.memory(graphImage!, height: 250),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}