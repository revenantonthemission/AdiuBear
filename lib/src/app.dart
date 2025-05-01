import 'dart:convert';
import 'dart:io';
import 'package:daily_care/apikey.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Define the HomeScreen widget.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settingsController,
  });

  // Declare a final variable to hold the settings controller.
  final dynamic settingsController;

  // Override the createState method to return an instance of _HomeScreenState.
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Define the state class for the HomeScreen widget.
class _HomeScreenState extends State<HomeScreen> {

  // Set up the controller for text input and using the speech-to-text library.
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Declare variables to track the state of the app.
  // XFile: Cross-platform File Abstraction
  bool _isListening = false;
  String _response = '';
  XFile? _selectedImage;

  // Initialize and set the speech-to-text controller to return the result of the recognition.
  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() => _controller.text = result.recognizedWords);
      });
    }
  }

  // If the user input is an image, open up the user's photo gallery and pick an image from the gallery.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = picked);
    }
  }

  // Call Gemini API with the user's input and the API key by using REST API of the http package.
  // Trim the text input and send the request to Gemini.
  Future<void> _callGemini() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    const apiKey = geminiAPIKey;
    Uri url;
    Map<String, dynamic> body;

    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');
      body = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ]
      };
    } else {
      url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');
      body = {
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      };
    }

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _response = data['candidates'][0]['content']['parts'][0]['text'];
      });
    } else {
      setState(() {
        _response = '오류: ${res.body}';
      });
    }
  }

  // Build the UI for the app.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Gemini 인터페이스')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(labelText: '프롬프트를 입력하세요'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                    onPressed: _isListening ? _speech.stop : _startListening,
                  ),
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _pickImage,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _callGemini,
                    child: const Text('Gemini 요청'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedImage != null)
                Image.file(
                  File(_selectedImage!.path),
                  height: 150,
                ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_response),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
