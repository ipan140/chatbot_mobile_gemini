import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chatbot',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

// ================= SPLASH SCREEN =================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GetStartedPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.android, size: 100, color: Color(0xFF0D1B4C)),
            SizedBox(height: 20),
            Text(
              "Chatbot AI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= GET STARTED PAGE =================
class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy, size: 120, color: Color(0xFF0D1B4C)),
            const SizedBox(height: 30),
            const Text(
              "Welcome to Chatbot AI",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 16),
            const Text(
              "Your intelligent companion for captivating conversations! "
              "I’m here to help you solve your daily challenges.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D1B4C),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatBotPage()),
                );
              },
              child: const Text(
                "Get Started",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ================= CHATBOT PAGE =================
class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env["API_KEY"];
    _model = GenerativeModel(model: "gemini-1.5-flash", apiKey: apiKey!);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? text, File? file}) async {
    if ((text == null || text.isEmpty) && file == null) return;

    setState(() {
      _messages.add({
        "role": "user",
        "text": text,
        "file": file,
        "time": DateTime.now()
      });
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final content = <Content>[];
      if (text != null && text.isNotEmpty) {
        content.add(Content.text(text));
      }
      if (file != null) {
        final mimeType = file.path.endsWith(".png")
            ? "image/png"
            : file.path.endsWith(".jpg") || file.path.endsWith(".jpeg")
                ? "image/jpeg"
                : "application/octet-stream";
        content.add(Content.data(mimeType, await file.readAsBytes()));
      }

      final response = await _model.generateContent(content);

      setState(() {
        _messages.add({
          "role": "bot",
          "text": response.text ?? "",
          "time": DateTime.now()
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "bot",
          "text": "Terjadi kesalahan: ${e.toString()}",
          "time": DateTime.now()
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _sendMessage(file: File(picked.path));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      _sendMessage(file: File(result.files.single.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4C), // body biru tua
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Chatbot",
                    style: TextStyle(
                      color: Color(0xFF0D1B4C),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications,
                            color: Color(0xFF0D1B4C)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Notifikasi belum tersedia")),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings,
                            color: Color(0xFF0D1B4C)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Menu Pengaturan")),
                          );
                        },
                      ),
                      const CircleAvatar(
                        backgroundColor: Color(0xFF0D1B4C),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chat Section
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isLoading && index == _messages.length) {
                    // Bubble typing indicator
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const TypingIndicator(),
                      ),
                    );
                  }

                  final message = _messages[index];
                  final isUser = message["role"] == "user";
                  final hasFile = message["file"] != null;
                  final time = message["time"] as DateTime;

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.white : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: hasFile
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "File: ${message["file"].path.split('/').last}",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (message["file"].path
                                            .endsWith('.png') ||
                                        message["file"].path
                                            .endsWith('.jpg') ||
                                        message["file"].path
                                            .endsWith('.jpeg'))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.file(
                                            message["file"],
                                            width: 160,
                                            height: 160,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : Text(
                                  message["text"] ?? "",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 8, right: 8, bottom: 4),
                          child: Text(
                            "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

            // Input area floating putih
            SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFF0D1B4C)),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          builder: (context) {
                            return SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.image,
                                        color: Color(0xFF0D1B4C)),
                                    title: const Text("Upload Gambar"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.attach_file,
                                        color: Color(0xFF0D1B4C)),
                                    title: const Text("Upload File"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickFile();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          hintText: "Reply...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) =>
                            _sendMessage(text: _controller.text),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF0D1B4C)),
                      onPressed: _isLoading
                          ? null
                          : () => _sendMessage(text: _controller.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= TYPING INDICATOR =================
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double opacity = 0.2;
            if (_controller.value > (index * 0.3) &&
                _controller.value < (index * 0.3 + 0.4)) {
              opacity = 1.0;
            }
            return Opacity(
              opacity: opacity,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  "•",
                  style: TextStyle(fontSize: 20, color: Colors.black54),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
