import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

@override
State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

  final picker = ImagePicker();
  XFile? image; // 카메라로 촬영한 이미지를 저장할 변수
  List<XFile?> images = []; // 가져온 사진들을 보여주기 위한 변수

class _ImageUploadScreenState extends State<ImageUploadScreen>{

  //서버에 이미지 업로드 함수
    Future<void> uploadImage(XFile image) async {
    var uri = Uri.parse('http://10.0.2.2:8000/upload'); // 에뮬레이터 기준 주소
    var request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      image.path,
    ));

    var response = await request.send();

    if (response.statusCode == 200) {
      print('업로드 성공');
    } else {
      print('업로드 실패: ${response.statusCode}');
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 세로로 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center, //가로로 중앙 정렬
            children: [
              const SizedBox(height: 40),

              // 문제 사진 촬영 버튼
              ElevatedButton.icon(
                onPressed: () async {
                  final img = await picker.pickImage(source: ImageSource.camera);
                  if (img != null) {
                    if (!mounted) return;
                    setState(() {
                      images.add(img);
                    });
                    await uploadImage(img); //서버로 사진 업로드
                  }
                },
                icon: const Icon(Icons.add_a_photo, size: 30, color: Colors.white),
                label: const Text(
                  '문제 사진 촬영',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // 갤러리에서 문제 사진 선택 버튼
              ElevatedButton.icon(
                onPressed: () async {
                  final pickedImages = await picker.pickMultiImage();
                  if (pickedImages.isNotEmpty) {
                    if (!mounted) return;
                    setState(() {
                      images.addAll(pickedImages);
                    });
                    for (var img in pickedImages) {
                      await uploadImage(img); // 업로드 함수 호출
                    }
                  }
                },
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 30, color: Colors.white),
                label: const Text(
                  '갤러리에서 문제 사진 선택',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
            ],
          ),
        )
      ),
    );
  }
}
