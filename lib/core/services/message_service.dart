import 'dart:convert';
import 'package:http/http.dart' as http;

class MessageService {
  final String _edgeFunctionUrl;
  final String _internalKey;

  MessageService({
    required String edgeFunctionUrl,
    required String internalKey,
  })  : _edgeFunctionUrl = edgeFunctionUrl,
        _internalKey = internalKey;

  /// Notify recipient of new message
  Future<bool> notifyNewMessage({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String messageId,
    required String conversationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-internal-key': _internalKey, // 🔐 Internal trigger auth
        },
        body: jsonEncode({
          'recipientId': recipientId,
          'senderName': senderName,
          'messagePreview': messagePreview.length > 50
              ? '${messagePreview.substring(0, 47)}...'
              : messagePreview,
          'messageId': messageId,
          'conversationId': conversationId,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Failed to send message notification: $e');
      return false;
    }
  }
}