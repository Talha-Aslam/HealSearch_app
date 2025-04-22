// lib/models/chat_message.dart
import 'dart:io';
import 'package:uuid/uuid.dart';

enum MessageSender { user, model }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final File? image; // Store the image file for display
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.sender,
    this.text = '',
    this.image,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
}
