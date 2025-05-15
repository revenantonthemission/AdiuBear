import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'chat.dart';

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
  late String _result = '';
  bool _isLoading = false;
  final audioRecorder = AudioRecorder();
  late GenerativeModel model;
  late FirebaseFirestore db;

  String? localPath;
  String? path;

  @override
  void initState() {
    super.initState();
    model =
        FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.0-flash');
    db = FirebaseFirestore.instance;
  }

  Future<void> pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() {
        _selectedImage = image;
      });
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // call Gemini API via text prompt.
  Future<void> _textAPI() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = '';
    });

    final requestTime = DateTime.now().toUtc();
    final chat = model.startChat();
    final response = await chat.sendMessage(Content.text(prompt));
    final responseTime = DateTime.now().toUtc();

    // The chat record between user and Gemini
    final chatRecord = <String, dynamic>{
      'user': prompt,
      'user-timestamp': requestTime,
      'gemini': response.text,
      'gemini-timestamp': responseTime,
    };
    db.collection('chat-records').add(chatRecord).then(
        (DocumentReference doc) =>
            {print('DocumentSnapshot added with ID: ${doc.id}')});

    setState(() {
      _result = response.text!;
      _isLoading = false;
    });
  }

  Future<void> _voiceAPI() async {
    setState(() {
      _isLoading = false;
      _result = '';
    });

    if (await audioRecorder.hasPermission()) {
      if (!await audioRecorder.isRecording()) {
        localPath = await _localPath;
        audioRecorder.start(const RecordConfig(),
            path: '$localPath/audio0.m4a');
        setState(() {
          _isLoading = true;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        path = await audioRecorder.stop();
        final audio = await File(path!).readAsBytes();
        final audioPart = InlineDataPart('audio/mpeg', audio);
        TextPart prompt =
            TextPart("Transcribe what's said in this audio recording.");

        GenerateContentResponse response = await model.generateContent([
          Content.multi(
            [
              prompt,
              audioPart,
            ],
          )
        ]);
        prompt = TextPart(response.candidates.first.text.toString());
        response = await model.generateContent([
          Content.multi(
            [
              prompt,
            ],
          )
        ]);

        setState(() {
          _result = response.text.toString();
          _isLoading = false;
          audioRecorder.dispose();
        });
      }
    } else {
      setState(() => _isLoading = false);
      throw Exception(
          'There is something wrong with the Gemini API. Try again.');
    }
  }

// Build the UI for the app.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Adiubear Demo",
      routes: {
        '/chat': (context) => const GeminiChatView(),
      },
      home: Scaffold(
        appBar: AppBar(title: const Text("Adiubear - Demo")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: "Enter Prompt",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: pickImage,
                      icon: const Icon(Icons.image),
                      tooltip: 'Select Image',
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _voiceAPI,
                      icon: const Icon(Icons.mic),
                      tooltip: 'Voice Interaction',
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _textAPI,
                      icon: const Icon(Icons.send),
                      tooltip: 'Send Prompt',
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
                    child: MarkdownBody(
                      data: _result,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
