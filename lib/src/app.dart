import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

// Define the HomeScreen widget.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settingsController,
  });

  final dynamic settingsController;

  // Override the createState method to return an instance of _HomeScreenState.
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Define the _HomeScreenState class, which extends State<HomeScreen>.
class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  XFile? _selectedImage;
  String _result = '';
  bool _isLoading = false;

  // Define the _pickImage method to pick an image from the user's photo gallery.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = picked;
      });
    }
  }

  // call the general Google Cloud API via Cloud Run and REST API.
  Future<void> _callCloudRunAPI() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = '';
    });

    final uri = Uri.parse(
        "https://api-server-636726337012.us-west1.run.app/gemini");
    String? base64Image;

    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        if (base64Image != null) 'base64Image': base64Image,
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => _result = data['result'] ?? '응답 없음');
    } else {
      setState(() => _result = '오류: ${response.body}');
    }
  }

  Future<void> _record() async {
    final audioRecorder = AudioRecorder();
    final directory = await getApplicationDocumentsDirectory();
    if (await audioRecorder.hasPermission()) {
      await audioRecorder.start(const RecordConfig(), path: '${directory.path}/audio0.m4a');
    }
  }

  // Build the UI for the app.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Gemini 중계 테스트")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: "프롬프트 입력",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("이미지 선택"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _callCloudRunAPI,
                    child: const Text("Gemini 요청"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _callCloudRunAPI,
                    child: const Text("Gemini 요청"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_selectedImage != null)
                Image.file(
                  File(_selectedImage!.path),
                  height: 150,
                ),
              const Divider(),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(_result),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
