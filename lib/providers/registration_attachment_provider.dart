import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_registration_attachment_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/registration_attachment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final registrationAttachmentRepositoryProvider =
    Provider<IRegistrationAttachmentRepository>((ref) {
      return ApiRegistrationAttachmentRepository(ref.watch(dioClientProvider));
    });
