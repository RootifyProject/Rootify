/*
 * Copyright (C) 2026 Rootify - Aby - FoxLabs
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ---- SYSTEM ---
import 'dart:convert';

// ---- EXTERNAL ---
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ---- MAJOR ---
// Telegram Communication Service
// Handles sending feedback and bug reports to a centralized Telegram bot.
// --- TelegramService
class TelegramService {
  // --- Sub
  // Constants & Configuration
  static String get _token => dotenv.get('TELEGRAM_BOT_TOKEN');

  // --- Sub
  // External Communication
  // Send a message to a specific Telegram chat or topic.
  static Future<bool> sendMessage(String text,
      {String? chatId, int? messageThreadId}) async {
    final targetChatId = chatId ?? dotenv.get('TELEGRAM_CHAT_ID');
    if (_token.isEmpty || targetChatId.isEmpty) return false;

    final url = Uri.parse('https://api.telegram.org/bot$_token/sendMessage');

    try {
      final body = {
        'chat_id': targetChatId,
        'text': text,
      };

      if (messageThreadId != null) {
        body['message_thread_id'] = messageThreadId.toString();
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
