import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'answer_loading_screen.dart';

class ImageUploadScreen extends StatefulWidget {
  final String userGrade;

  const ImageUploadScreen({super.key, required this.userGrade});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final picker = ImagePicker();

  // 문제 사진을 선택하고 → AnswerLoadingScreen으로 이동
  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await picker.pickImage(source: source);
    if (pickedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnswerLoadingScreen(
            image: pickedImage,
            userGrade: widget.userGrade,
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
        title: const Text("문제 검색", style: TextStyle(color: Colors.black, fontFamily: 'NotoSans')),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // 문제 사진 촬영 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.add_a_photo, size: 28, color: Colors.white),
                label: const Text('문제 사진 촬영', style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 갤러리에서 문제 사진 선택 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 28, color: Colors.white),
                label: const Text('갤러리에서 문제 사진 선택', style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
