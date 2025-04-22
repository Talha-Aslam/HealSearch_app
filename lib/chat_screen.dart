// lib/screens/chat_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:image_picker/image_picker.dart';
// import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  XFile? _pickedImage;
  late final genai.GenerativeModel _model;
  late final genai.ChatSession _chat;
  final FocusNode _focusNode =
      FocusNode(); // Added FocusNode to manage keyboard focus

  // --- Define the Initial Doctor Persona Prompt ---
  // !! CRITICAL: Include comprehensive disclaimers !!
  static const String initialDoctorPrompt = """
  👩‍⚕️ **Welcome to your friendly Medical Assistant!**

I’m an AI built to guide you with basic health suggestions based on the symptoms you describe. I can explain possible causes and recommend **common over-the-counter (OTC) medicines** for **mild, everyday issues** like headaches, colds, or stomach discomfort.

I’m here to support you — but please remember:
🩺 This is **not a replacement for a real doctor**.
🚨 If your symptoms are serious, unusual, or don’t go away, **always consult a qualified healthcare professional**.

You can start by telling me how you're feeling, and I'll do my best to help. 😊
  """;
  // --- End of Prompt ---

  @override
  void initState() {
    super.initState();

    if (geminiApiKey == geminiApiKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Removed the SnackBar warning for API key
        }
      });
      // Optionally disable input if no key
    }

    // Initialize the Gemini model
    _model = genai.GenerativeModel(
      model: 'gemini-1.5-flash-latest', // Or 'gemini-pro-vision'
      apiKey: geminiApiKey,
      // You might want to adjust safety settings for medical context if possible,
      // but rely heavily on the prompt disclaimer.
      // safetySettings: [ ... ],
      generationConfig: genai.GenerationConfig(
          // Adjust temperature for more factual/less creative responses if needed
          // temperature: 0.5,
          ),
    );

    // --- Start the chat session with the initial "doctor" context ---
    _chat = _model.startChat(
      history: [
        // Provide the persona prompt as the initial message from the 'model'.
        // This sets the context for the entire conversation.
        genai.Content.model([genai.TextPart(initialDoctorPrompt)])
        // Optional: You could add a dummy user message like Content.text("Hello")
        // if needed, but usually the model prompt is enough.
      ],
    );

    // --- Add the initial disclaimer/prompt message to the UI ---
    // So the user sees it immediately before typing anything.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Ensure the widget is still in the tree
        setState(() {
          _messages.insert(
            // Insert at the beginning of the list
            0,
            ChatMessage(
              sender: MessageSender.model, // From the bot
              text: initialDoctorPrompt,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom(); // Scroll down if needed (might not be necessary for the first message)
      }
    });
  }

  // --- Rest of the code remains the same ---
  // (dispose, build, _buildMessageItem, _buildInputArea, _buildImagePreview,
  // _scrollToBottom, _pickImage, _sendMessage, _showError)
  // ...

  @override
  void dispose() {
    _focusNode.dispose(); // Dispose the FocusNode to avoid memory leaks
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- UI Building Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
        title: const Text('AI Doctor'), // Updated Title
        elevation: 1.0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8A2387),
                Color(0xFFE94057),
                Color(0xFFF27121),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: PreferredSize(
          // Add a subtle disclaimer reminder in the AppBar
          preferredSize: const Size.fromHeight(20.0),
          child: Container(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              "Make sure to always Consult a Doctor.",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontSize: 12.0,
                  ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                // Add extra spacing/styling for the initial disclaimer
                if (index == 0 &&
                    _messages[index].sender == MessageSender.model &&
                    _messages[index]
                        .text
                        .contains("VERY IMPORTANT DISCLAIMER")) {
                  return _buildDisclaimerMessageItem(_messages[index]);
                }
                return _buildMessageItem(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

// Optional: A slightly different style for the initial disclaimer message
  Widget _buildDisclaimerMessageItem(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
              color: Theme.of(context).colorScheme.tertiary, width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Maybe add an Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.tertiary, size: 20),
              const SizedBox(width: 8),
              Text("Important Information",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).colorScheme.onTertiaryContainer)),
              const SizedBox(width: 8),
              Icon(Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.tertiary, size: 20),
            ],
          ),
          const Divider(height: 15),
          // Use the standard text part for the content
          Text(
            message.text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isUserMessage = message.sender == MessageSender.user;
    final alignment =
        isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUserMessage
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceVariant;
    final textColor = isUserMessage
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width * 0.75, // Max bubble width
            ),
            child: Card(
              elevation: 0.5,
              color: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16.0),
                  topRight: const Radius.circular(16.0),
                  bottomLeft: Radius.circular(isUserMessage ? 16.0 : 0),
                  bottomRight: Radius.circular(isUserMessage ? 0 : 16.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.image != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            message.image!,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 40),
                          ),
                        ),
                      ),
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: TextStyle(
                            color: textColor, height: 1.4), // Line height
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4.0,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Takes minimum space needed
        children: [
          // Image Preview Area
          if (_pickedImage != null) _buildImagePreview(),

          // Input Row
          Row(
            children: [
              // Image Picker Button (Maybe less relevant for symptoms, but keep for flexibility)
              IconButton(
                icon: Icon(
                  Icons.image_outlined,
                  color: Color.fromARGB(255, 205, 13, 39),
                ),
                onPressed: _isLoading ? null : _pickImage,
                tooltip: 'Add Image (Optional)',
              ),
              // Text Field
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode:
                      _focusNode, // Attach the FocusNode to the TextField
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText:
                        'Describe mild symptoms here...', // Updated hint text
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                  ),
                  onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8.0),
              // Send Button
              IconButton(
                icon: Icon(
                  Icons.send,
                  color: const Color.fromARGB(255, 205, 13, 39),
                ),
                onPressed: _isLoading ||
                        (_textController.text.isEmpty && _pickedImage == null)
                    ? null
                    : () {
                        FocusScope.of(context)
                            .unfocus(); // Ensure keyboard is dismissed
                        debugPrint(
                            "Send button pressed"); // Debugging log to confirm button press
                        _sendMessage(); // Trigger send message immediately
                      },
                tooltip: 'Send Message',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    // ... (Keep the original _buildImagePreview logic as before)
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(
              File(_pickedImage!.path),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          const Text("Image added"),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                _pickedImage = null;
              });
            },
            tooltip: 'Remove Image',
          )
        ],
      ),
    );
  }

  // --- Logic Methods ---

  void _scrollToBottom() {
    // ... (Keep the original _scrollToBottom logic as before)
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          // Add mounted check here too
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _pickImage() async {
    // ... (Keep the original _pickImage logic as before)
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        // Check mounted after await
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _sendMessage() async {
    // ... (Keep the original _sendMessage logic mostly the same)
    // Make sure the disclaimer logic isn't accidentally removed
    // from the API call or response handling if you modify it.
    final String text = _textController.text.trim();
    final XFile? imageFile = _pickedImage;

    if (text.isEmpty && imageFile == null) {
      return;
    }

    // Check if mounted before setState
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(
        sender: MessageSender.user,
        text: text,
        image: imageFile != null ? File(imageFile.path) : null,
        timestamp: DateTime.now(),
      ));
      _textController.clear();
      _pickedImage = null;
    });
    _scrollToBottom();

    try {
      final List<genai.Part> parts = [];
      Uint8List? imageBytes;

      if (imageFile != null) {
        imageBytes = await imageFile.readAsBytes();
        String mimeType = 'image/jpeg'; // Basic MIME type inference
        final pathLower = imageFile.path.toLowerCase();
        if (pathLower.endsWith('.png'))
          mimeType = 'image/png';
        else if (pathLower.endsWith('.webp'))
          mimeType = 'image/webp';
        else if (pathLower.endsWith('.heic'))
          mimeType = 'image/heic';
        else if (pathLower.endsWith('.heif')) mimeType = 'image/heif';
        parts.add(genai.DataPart(mimeType, imageBytes));
      }

      if (text.isNotEmpty) {
        parts.add(genai.TextPart(
            "You are a friendly AI medical advisor in an educational app. When the user tells you their symptoms, explain the **possible cause** in simple words, then suggest common **over-the-counter (OTC) medicines** that might help. Be short, clear, and helpful. Example:\n\nInput: I have a headache and fever\nOutput: This could be due to a viral infection. You may take Paracetamol or Panadol. Stay hydrated and rest.\n\nNow respond to:\n$text"));
      }

      final content = genai.Content.multi(parts);

      // Use the existing _chat session which already has the context
      var response = await _chat.sendMessage(content);
      final String? responseText = response.text;

      // Check if mounted before processing response and setState
      if (!mounted) return;

      if (responseText == null || responseText.isEmpty) {
        _showError('AI did not return a response.');
        setState(() {
          // Add an error message to the chat
          _messages.add(ChatMessage(
            sender: MessageSender.model,
            text:
                "Sorry, I encountered an issue and couldn't get a response. Please try again.",
            timestamp: DateTime.now(),
          ));
        });
      } else {
        // Add Gemini response to UI
        // Optional: You *could* programmatically add a mini-disclaimer
        // reminder to every bot response here, but it might be overkill
        // if the initial prompt and app bar are clear.
        // final responseWithReminder = responseText + "\n\n*(Reminder: Not medical advice. Consult a doctor.)*";
        setState(() {
          _messages.add(ChatMessage(
            sender: MessageSender.model,
            text: responseText, // or responseWithReminder
            timestamp: DateTime.now(),
          ));
        });
      }
      _scrollToBottom();
    } catch (e) {
      // Check if mounted before showing error / setState
      if (!mounted) return;
      _showError('Error sending message: $e');
      setState(() {
        _messages.add(ChatMessage(
          sender: MessageSender.model,
          text:
              "Sorry, I couldn't process that. Error: ${e.toString()}\n\nPlease remember to consult a real doctor for medical advice.",
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    } finally {
      // Check if mounted before final setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    // Check if mounted before showing SnackBar
    if (mounted && ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
    debugPrint("Chat Error: $message");
  }
} // End of _ChatScreenState
