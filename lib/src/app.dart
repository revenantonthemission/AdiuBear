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
  late String _result = '';
  bool _isLoading = false;
  late LiveSession session;

  @override
  void initState() {
    super.initState();
  }

  // call Live API via text prompt.
  Future<void> _textLiveAPI() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    // Initialize the Vertex AI service and create a `LiveModel` instance
    final model = FirebaseVertexAI.instance.liveGenerativeModel(
      // The Live API requires this specific model.
      model: 'gemini-2.0-flash-live-preview-04-09',
      // Configure the model to respond with audio
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [
          ResponseModalities.text,
        ],
        speechConfig: SpeechConfig(voiceName: 'Fenrir'),
      ),
    );

    setState(() {
      _isLoading = true;
      _result = '';
    });

    session = await model.connect();
    await session.send(input: Content.text(prompt), turnComplete: true);

    setState(() => _isLoading = false);
    await for (final response in session.receive()) {
      final content = response.message as LiveServerContent;
      final modelTurn = content.modelTurn;
    }
  }

  Future<void> _voiceLiveAPI() async {
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

    setState(() {
      _isLoading = true;
      _result = '';
    });

    LiveSession session = await model.connect();
    final audioRecorder = AudioRecorder();

    if (await audioRecorder.hasPermission()) {
      final stream = await audioRecorder
          .startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits));
      final mediaChunkStream = stream.map((data) {
        return InlineDataPart('audio/pcm', data);
      });

      await session.sendMediaStream(mediaChunkStream);

      final responseStream = session.receive();

      setState(() => _result = responseStream.asyncMap((response) async {
        final content = response.message as LiveServerContent;
      }) as String);

      setState(() => _isLoading = false);

    } else {
      setState(() => _isLoading = false);
      throw Exception('There is something wrong with Live API. Try again.');
    }
  }

  // Build the UI for the app.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Adiubear - Live API Demo")),
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
                    ElevatedButton.icon(
                      onPressed: _voiceLiveAPI,
                      icon: const Icon(Icons.mic),
                      label: const Text("Voice Interaction"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _textLiveAPI,
                      icon: const Icon(Icons.send),
                      label: const Text("Text Interaction"),
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
