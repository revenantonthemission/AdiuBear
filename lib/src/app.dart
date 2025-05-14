import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:path_provider/path_provider.dart';

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
  final vertexAI = FirebaseVertexAI.instanceFor(
    location: 'us-west1',
  );
  late GenerativeModel model;
  late LiveGenerativeModel liveModel;
  late LiveSession _session;

  String? localPath;
  String? path;

  @override
  void initState() {
    super.initState();
    model = vertexAI.generativeModel(model: 'gemini-2.5-pro-preview-05-06');
    liveModel = FirebaseVertexAI.instance.liveGenerativeModel(
      model: 'gemini-2.0-flash-live-001',
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: ResponseModalities.values,
      ),
    );
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

    // Further Implementations for Bidirectional Streaming via Live API
    _session = await liveModel.connect();
    await _session.send(input: Content.text(prompt), turnComplete: true);

    await for (final (message as LiveServerContent) in _session.receive()) {
      for (final part in message.modelTurn!.parts) {
        _result += part.toString();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }


  Future<void> _voiceAPI() async {
    setState(() {
      _isLoading = false;
      _result = '';
    });
    if (await audioRecorder.hasPermission()) {
      // Further Implementations for Bidirectional Streaming via Live API
      if (!await audioRecorder.isRecording()) {
        _session = await liveModel.connect();
        localPath = await _localPath;
        final stream = await audioRecorder
            .startStream(
            const RecordConfig(encoder: AudioEncoder.pcm16bits));
        final mediaChunkStream = stream.map((data) {
          return InlineDataPart('audio/pcm', data);
        });
        await _session.sendMediaStream(mediaChunkStream);
        // In a separate thread, receive the audio response from the model
        await for (final (message as LiveServerContent) in _session
            .receive()) {
          // Process the received message
          for (final part in message.modelTurn!.parts) {
            if (part is InlineDataPart && part.mimeType == 'audio/pcm') {
              final Uint8List pcmChunk = part.bytes;
              _result += String.fromCharCodes(pcmChunk);
            }
          }
        }
      } else {
        await audioRecorder.cancel();
      }
    } else {
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
                      onPressed: pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text("Image Interaction"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _voiceAPI,
                      icon: const Icon(Icons.mic),
                      label: const Text("Voice Interaction"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _textAPI,
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