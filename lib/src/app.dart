import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

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

  @override
  void initState() {
    super.initState();
  }

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
        "https://api-server-636726337012.asia-northeast3.run.app/gemini");
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

  Future<void> _callLiveAPI() async {
    // Initialize the Vertex AI service and create a `LiveModel` instance
    final model = FirebaseVertexAI.instance.liveGenerativeModel(
      // The Live API requires this specific model.
      model: 'gemini-2.0-flash-live-preview-04-09',
      // Configure the model to respond with audio
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [
          ResponseModalities.audio,
        ],
      ),
    );
    LiveSession session = await model.connect();
    final audioRecorder = AudioRecorder();

    if (await audioRecorder.hasPermission()) {
      final stream = await audioRecorder
          .startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits));
    }

    // do something...

    final path = await audioRecorder.stop();
    audioRecorder.dispose();
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
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Row(
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
                    ElevatedButton.icon(
                      onPressed: _callLiveAPI,
                      icon: const Icon(Icons.mic),
                      label: const Text("Live API 요청"),
                    ),
                  ],
                ),
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
