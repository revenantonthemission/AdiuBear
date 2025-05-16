import 'package:adiubear/src/authentication/authentication_gate.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:adiubear/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:adiubear/src/core_components/custom_theme.dart';

void main() async {
  // Initialize the Firebase client
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(ChangeNotifierProvider(
    create: (context) => ThemeProvider(),
    child: const HomeScreen(),
  ));
}

// Define the HomeScreen widget.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    //required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AuthenticationGate(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}

/*
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
      home: const AuthenticationGate(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}

/// ㅋㅋ 오늘 UI 완성해야 함 답도 덦다
*/
