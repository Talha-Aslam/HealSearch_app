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

    // Setup keyboard focus management
    _focusNode.addListener(() {
      // When the text field gets focus, make sure UI adjusts
      if (_focusNode.hasFocus) {
        // Add post-frame callback to scroll to bottom when keyboard appears
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom();
        });
      }
    });

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
    return GestureDetector(
      // Add GestureDetector to handle taps outside the text field
      onTap: () {
        // Dismiss keyboard when tapping outside the text field
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        // Use resizeToAvoidBottomInset to ensure the UI adjusts correctly with keyboard
        resizeToAvoidBottomInset: true,
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
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.5),
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
        body: SafeArea(
          // Wrap in SafeArea to respect system UI elements
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
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
              // Use AnimatedContainer for smooth transitions when keyboard appears
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: _buildInputArea(),
              ),
            ],
          ),
        ),
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

    // Enhanced theming with better color contrast
    final Color color;
    final Gradient? gradient;
    final Color textColor;

    if (isUserMessage) {
      // User messages - gradient styling
      color = Theme.of(context).colorScheme.primary.withOpacity(0.8);
      textColor = Colors.white;
      gradient = LinearGradient(
        colors: [
          Color(0xFF8A2387).withOpacity(0.9),
          Color(0xFFE94057).withOpacity(0.9),
          Color(0xFFF27121).withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // AI message styling - more visually appealing
      textColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Theme.of(context).colorScheme.onSurface;

      // For dark mode, use more contrasting container
      if (Theme.of(context).brightness == Brightness.dark) {
        color = Color(0xFF2A2A2A); // Dark gray with better contrast
        gradient = LinearGradient(
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF363636),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else {
        // Light mode
        color = Colors.white;
        gradient = LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFF8F8F8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Time indicator above message with smaller font
          Padding(
            padding: EdgeInsets.only(
              bottom: 2.0,
              left: isUserMessage ? 0 : 8.0,
              right: isUserMessage ? 8.0 : 0,
            ),
            child: Text(
              _formatTimeStamp(message.timestamp),
              style: TextStyle(
                fontSize: 10.0,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ),

          // Message bubble
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16.0),
                  topRight: const Radius.circular(16.0),
                  bottomLeft: Radius.circular(isUserMessage ? 16.0 : 0),
                  bottomRight: Radius.circular(isUserMessage ? 0 : 16.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUserMessage
                        ? Colors.black.withOpacity(0.1)
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add AI icon for bot messages
                    if (!isUserMessage)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Color(0xFFFFA726) // Orange in dark mode
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "AI Doctor",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Color(0xFFFFA726) // Orange in dark mode
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      _buildFormattedText(
                          message.text, textColor, isUserMessage),
                  ],
                ),
              ),
            ),
          ),

          // Add small spacing after each message
          SizedBox(height: 2.0),
        ],
      ),
    );
  }

  // Helper method to format message timestamps
  String _formatTimeStamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today: show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days
      return '${timestamp.day}/${timestamp.month}, ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  // Helper method to build formatted message text with support for basic markdown-like formatting
  Widget _buildFormattedText(String text, Color textColor, bool isUserMessage) {
    // Process the text for basic formatting
    if (isUserMessage) {
      // For user messages, just show plain text
      return Text(
        text,
        style: TextStyle(
          color: textColor,
          height: 1.4,
          fontSize: 15.0,
        ),
      );
    } else {
      // For AI responses, we'll parse basic markdown-like formatting for richer display
      final List<InlineSpan> spans = [];

      // Regular expressions for basic formatting
      final boldRegex = RegExp(r'\*\*(.*?)\*\*');
      final listItemRegex = RegExp(r'^\s*[-•*]\s(.+)$', multiLine: true);

      // Store the last end position to track where we left off
      int lastMatchEnd = 0;

      // Find all bold text
      final boldMatches = boldRegex.allMatches(text);
      for (final match in boldMatches) {
        // Add normal text before this match
        if (match.start > lastMatchEnd) {
          spans.add(TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(
              color: textColor,
              height: 1.5,
              fontSize: 15.0,
            ),
          ));
        }

        // Add the bold text (without ** markers)
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Color(0xFFFFA726) // Orange highlight in dark mode
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            height: 1.5,
            fontSize: 15.0,
          ),
        ));

        lastMatchEnd = match.end;
      }

      // Add remaining text after the last match
      if (lastMatchEnd < text.length) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd),
          style: TextStyle(
            color: textColor,
            height: 1.5,
            fontSize: 15.0,
          ),
        ));
      }

      // If no formatting was detected, just add the whole text as a single span
      if (spans.isEmpty) {
        // Process list items if present
        final listItems = listItemRegex.allMatches(text);
        if (listItems.isNotEmpty) {
          // Handle list items with special styling
          int lastPos = 0;
          for (final item in listItems) {
            if (item.start > lastPos) {
              // Add text before this list item
              spans.add(TextSpan(
                text: text.substring(lastPos, item.start),
                style: TextStyle(color: textColor, height: 1.5, fontSize: 15.0),
              ));
            }

            // Add the list item with bullet styling
            spans.add(TextSpan(
              text: "• ", // Replace with a proper bullet
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                height: 1.5,
                fontSize: 16.0,
              ),
            ));

            spans.add(TextSpan(
              text: item.group(1), // The list item text without the bullet
              style: TextStyle(color: textColor, height: 1.5, fontSize: 15.0),
            ));

            lastPos = item.end;
          }

          // Add remaining text after the last list item
          if (lastPos < text.length) {
            spans.add(TextSpan(
              text: text.substring(lastPos),
              style: TextStyle(color: textColor, height: 1.5, fontSize: 15.0),
            ));
          }
        } else {
          // Plain text with no formatting
          spans.add(TextSpan(
            text: text,
            style: TextStyle(color: textColor, height: 1.5, fontSize: 15.0),
          ));
        }
      }

      return RichText(
        text: TextSpan(children: spans),
        textAlign: TextAlign.left,
      );
    }
  }

  Widget _buildInputArea() {
    // Use MediaQuery to adjust padding based on keyboard visibility
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        top: 8.0,
        bottom:
            bottomInset > 0 ? 8.0 : 8.0 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF1E1E1E) // Darker background for dark mode
            : Colors.white, // Pure white for light mode
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 6.0,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
          ),
        ],
        // Add a subtle border at the top
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Takes minimum space needed
        children: [
          // Image Preview Area
          if (_pickedImage != null) _buildImagePreview(),

          // Input Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end, // Align items at bottom
            children: [
              // Image Picker Button with improved styling
              Container(
                margin: const EdgeInsets.only(right: 4.0, bottom: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF2A2A2A)
                      : Color(0xFFE8E8E8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isLoading ? null : _pickImage,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.image_outlined,
                        color: _isLoading
                            ? Theme.of(context).disabledColor
                            : Theme.of(context).brightness == Brightness.dark
                                ? Color(0xFFFFA726) // Orange in dark mode
                                : Color(0xFFE94057), // App color in light mode
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),

              // Text Field
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    minLines: 1,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 16.0,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Describe mild symptoms here...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[500],
                        fontSize: 15.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xFF2A2A2A) // Darker but not too dark
                          : Color(0xFFF5F5F5), // Very light gray
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      isDense: true,
                    ),
                    onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                    onChanged: (_) =>
                        setState(() {}), // Rebuild to update button state
                  ),
                ),
              ),

              const SizedBox(width: 4.0),
              // Send Button - Using a more styled approach
              Container(
                margin: const EdgeInsets.only(left: 2.0, bottom: 2.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isLoading ||
                          (_textController.text.isEmpty && _pickedImage == null)
                      ? null // No gradient when disabled
                      : LinearGradient(
                          colors: [
                            Color(0xFF8A2387),
                            Color(0xFFE94057),
                            Color(0xFFF27121),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: _isLoading ||
                          (_textController.text.isEmpty && _pickedImage == null)
                      ? Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[300]
                      : null, // Use null to let gradient show
                  boxShadow: _isLoading ||
                          (_textController.text.isEmpty && _pickedImage == null)
                      ? null
                      : [
                          BoxShadow(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: _isLoading ||
                            (_textController.text.isEmpty &&
                                _pickedImage == null)
                        ? null
                        : () {
                            debugPrint("Send button pressed - tap triggered");
                            FocusScope.of(context).unfocus();
                            _sendMessage();
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.send,
                        color: _isLoading ||
                                (_textController.text.isEmpty &&
                                    _pickedImage == null)
                            ? Theme.of(context).disabledColor
                            : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF2A2A2A)
            : Color(0xFFF5F5F5),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.file(
              File(_pickedImage!.path),
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Image added",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              Text(
                "Tap to remove",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _pickedImage = null;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
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
    final ImagePicker picker = ImagePicker();
    try {
      // Show a bottom sheet to select image source
      if (mounted) {
        await showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Gallery'),
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null && mounted) {
                        setState(() {
                          _pickedImage = image;
                        });
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Camera'),
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? photo =
                          await picker.pickImage(source: ImageSource.camera);
                      if (photo != null && mounted) {
                        setState(() {
                          _pickedImage = photo;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _sendMessage() async {
    debugPrint("_sendMessage method called");

    final String text = _textController.text.trim();
    final XFile? imageFile = _pickedImage;

    // Guard clause - return early if there's nothing to send
    if (text.isEmpty && imageFile == null) {
      debugPrint("Nothing to send - returning early");
      return;
    }

    // Ensure keyboard is dismissed - this helps with UI responsiveness
    FocusScope.of(context).unfocus();

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

    // Ensure scroll happens after setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToBottom();
    });

    try {
      final List<genai.Part> parts = [];
      Uint8List? imageBytes;

      if (imageFile != null) {
        imageBytes = await imageFile.readAsBytes();
        String mimeType = 'image/jpeg'; // Basic MIME type inference
        final pathLower = imageFile.path.toLowerCase();
        if (pathLower.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (pathLower.endsWith('.webp'))
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
        setState(() {
          _messages.add(ChatMessage(
            sender: MessageSender.model,
            text: responseText,
            timestamp: DateTime.now(),
          ));
        });
      }

      // Ensure scroll happens after setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
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

      // Ensure scroll happens after setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
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
