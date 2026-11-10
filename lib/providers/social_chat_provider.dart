import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';

/// Latest chat messages of a social session (oldest -> newest), from the API.
/// Refresh with `ref.invalidate(socialChatMessagesProvider(sessionId))`.
final socialChatMessagesProvider = FutureProvider.autoDispose
    .family<List<SocialChatMessageModel>, String>(
      (ref, sessionId) =>
          ref.watch(socialSessionRepositoryProvider).getMessages(sessionId),
    );
